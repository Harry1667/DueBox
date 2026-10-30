import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../types/bill.dart';
import 'logger_service.dart';
import 'analytics_service.dart';
import 'remote_config_service.dart';

/// 帳單辨識失敗時丟出的例外。訊息會直接顯示給使用者，所以寫成人看得懂的中文。
class AiExtractException implements Exception {
  final String message;
  AiExtractException(this.message);
  @override
  String toString() => message;
}

/// AI 帳單辨識服務。
///
/// 只走 proxy-cli（clip.twloop.com）：圖片走 Gemini CLI 的 OAuth 免費額度，
/// 文字走 auto-route 自動挑模型，用量都會記在 proxy 儀表板上。
///
/// 為什麼不再保留 Gemini 直連備援：直連需要把 Gemini 金鑰放進 App，
/// 不論寫在程式碼或從 Remote Config 下發，都能從安裝好的 App 裡取出。
/// App 只持有 proxy token，上游金鑰留在 proxy 伺服器上。
///
/// 失敗一律丟 AiExtractException，不會安靜地回 null。
class AiService {
  static const _groupName = 'bill-extract';

  // ── Prompt（精簡版，約 100 tokens）────────────────────────────────────────
  static const _imagePrompt =
      '帳單圖片辨識。只輸出JSON不含其他文字：\n'
      '{"title":"服務商","amount":數值,"currency":"NT\$","dueDate":"YYYY-MM-DD","note":"備註","category":"類別","recurrence":0}\n'
      'recurrence: 0=無 1=月費(月/mo/Monthly/自動續訂) 2=年費(年/yr/Annual)\n'
      '訂閱服務找下次扣款日。民國年+1911。繁體中文。';

  static const _textPromptPrefix =
      '帳單文字擷取。只輸出JSON：\n'
      '{"title":"","amount":0,"currency":"NT\$","dueDate":"YYYY-MM-DD","note":"","category":"","recurrence":0}\n'
      'recurrence: 0=無 1=月費(月/mo/Monthly/自動續訂) 2=年費(年/yr/Annual)\n'
      '內容：';

  final http.Client _http = http.Client();
  final _config = RemoteConfigService();
  final _log = LoggerService();
  final _analytics = AnalyticsService();

  // ── 對外 API ──────────────────────────────────────────────────────────────

  /// 從圖片擷取帳單。[method] 只用於統計，填 'camera' 或 'gallery'。
  Future<Bill> extractBillFromImage(File imageFile, {required String method}) async {
    final bytes = await imageFile.readAsBytes();
    return _extract(
      method: method,
      run: () => _proxyImage(bytes),
    );
  }

  /// 從文字擷取帳單。
  Future<Bill> extractBillFromText(String text) async {
    return _extract(
      method: 'text',
      run: () => _proxyText(text),
    );
  }

  /// 共用的呼叫流程，順便把統計事件打齊。
  Future<Bill> _extract({
    required String method,
    required Future<_AiResult> Function() run,
  }) async {
    final started = DateTime.now();
    try {
      final r = await run();
      _analytics.billExtractSuccess(
        method: method,
        source: 'proxy',
        provider: r.provider,
        latencyMs: DateTime.now().difference(started).inMilliseconds,
      );
      return r.bill;
    } catch (e) {
      _log.log('AiService: proxy 失敗 → $e');
      _analytics.billExtractFailed(method: method, reason: _classify(e));
      throw AiExtractException('AI 辨識失敗：$e');
    }
  }

  /// 把例外歸類成短字串，避免把整段訊息當成統計維度炸開基數。
  String _classify(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('timeout')) return 'timeout';
    if (s.contains('auth') || s.contains('401') || s.contains('403')) return 'auth';
    if (s.contains('quota') || s.contains('429')) return 'quota';
    if (s.contains('socket') || s.contains('network')) return 'network';
    if (s.contains('formatexception') || s.contains('json')) return 'parse';
    return 'other';
  }

  // ── Proxy 路徑 ────────────────────────────────────────────────────────────

  Future<_AiResult> _proxyImage(Uint8List bytes) async {
    _log.log('Proxy: 送出圖片 ${bytes.length} bytes（provider=gemini）');
    // 指定 provider=gemini 是為了走 Gemini CLI 的 OAuth 免費路徑，
    // 比讓 proxy 自動路由到需要 API key 的多模態路徑便宜且快。
    return _postProxy(
      {
        'prompt': _imagePrompt,
        'provider': 'gemini',
        'images': [
          {'mime_type': 'image/jpeg', 'data': base64Encode(bytes)}
        ],
      },
      // 實測含上傳約 10 秒；留足裕度給行動網路。
      const Duration(seconds: 90),
    );
  }

  Future<_AiResult> _proxyText(String text) async {
    _log.log('Proxy: 送出文字 ${text.length} 字（auto-route）');
    return _postProxy(
      {'prompt': '$_textPromptPrefix"$text"'},
      const Duration(seconds: 45),
    );
  }

  Future<_AiResult> _postProxy(Map<String, dynamic> payload, Duration timeout) async {
    final res = await _http
        .post(
          Uri.parse(_config.proxyUrl),
          headers: {
            'Authorization': 'Bearer ${_config.proxyToken}',
            'Content-Type': 'application/json; charset=utf-8',
          },
          // 一定要用 utf8.encode：中文 prompt 若讓 http 套件用預設編碼送出，
          // Content-Length 會跟實際 byte 數對不上導致伺服器解析失敗。
          body: utf8.encode(jsonEncode({
            ...payload,
            'project': _config.proxyProject,
            'group': _groupName,
          })),
        )
        .timeout(timeout);

    // 伺服器可能回非 JSON 的錯誤頁（例如反向代理的 500），先擋掉再解析。
    Map<String, dynamic> body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('proxy 回傳非 JSON（HTTP ${res.statusCode}）');
    }

    if (res.statusCode != 200 || body['ok'] != true) {
      throw Exception(
          body['error'] ?? body['error_code'] ?? 'proxy HTTP ${res.statusCode}');
    }

    final provider = '${body['actual_provider']}/${body['actual_model']}';
    _log.log('Proxy: ✓ $provider ${body['latency_ms']}ms '
        'source=${body['actual_source']}');
    return _AiResult(_parseBill(body['content'] as String), provider);
  }

  // ── 解析 ─────────────────────────────────────────────────────────────────

  Bill _parseBill(String raw) {
    // 模型常常把 JSON 包在 ```json 圍欄裡（proxy 走 CLI 時尤其明顯），先剝掉。
    String clean = raw.replaceAll(RegExp(r'```json\s*|\s*```'), '').trim();
    // 前後仍可能有說明文字，抓第一個大括號區塊。
    final match = RegExp(r'\{.*\}', dotAll: true).firstMatch(clean);
    if (match != null) clean = match.group(0)!;

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(clean) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('模型回傳的內容不是有效 JSON：${_preview(raw)}');
    }

    return Bill(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: (data['title'] as String?)?.trim().isNotEmpty == true
          ? (data['title'] as String).trim()
          : '未知帳單',
      amount: _toDouble(data['amount']),
      currency: (data['currency'] as String?)?.trim().isNotEmpty == true
          ? (data['currency'] as String).trim()
          : 'NT\$',
      dueDate: _normalizeDate(data['dueDate']?.toString() ?? ''),
      status: BillStatus.unpaid,
      note: data['note'] as String?,
      category: data['category'] as String?,
      // clamp 到 0..2，對齊 Recurrence 只有 none/monthly/yearly 三個值，
      // 模型亂回 5 也不會造成 RangeError。
      recurrence: Recurrence
          .values[(_toDouble(data['recurrence']).toInt()).clamp(0, 2)],
    );
  }

  /// 模型可能把金額回成字串（"1,280" 或 "NT$1280"），統一轉成數字。
  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) {
      final cleaned = v.replaceAll(RegExp(r'[^0-9.\-]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  String _preview(String s) =>
      s.length <= 120 ? s : '${s.substring(0, 120)}…';

  String _normalizeDate(String s) {
    try {
      s = s.trim().replaceAll('/', '-');
      final parts = s.split('-');
      if (parts.length == 3) {
        final y = int.parse(parts[0]);
        // 民國年轉西元：帳單不可能來自 1920 年以前，小於就當民國年。
        if (y < 1920) {
          s = '${y + 1911}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
        }
      }
      DateTime.parse(s);
      return s;
    } catch (_) {
      _log.log('AiService: 日期無法解析「$s」，退回今天');
      return DateTime.now().toIso8601String().split('T')[0];
    }
  }

  void dispose() => _http.close();
}

/// 內部用：帶回辨識結果與實際使用的模型，供統計記錄。
class _AiResult {
  final Bill bill;
  final String provider;
  _AiResult(this.bill, this.provider);
}
