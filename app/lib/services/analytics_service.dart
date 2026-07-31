import 'package:firebase_analytics/firebase_analytics.dart';
import 'logger_service.dart';

/// Firebase Analytics 包裝層。
///
/// 為什麼包一層而不直接呼叫 FirebaseAnalytics.instance：
/// 1. Firebase 還沒設定好（缺 GoogleService-Info.plist）時直接呼叫會丟例外，
///    包一層之後所有事件變成安靜的 no-op，不會讓 App 因為統計而崩潰。
/// 2. 事件名稱集中在這裡，避免各頁面各自打錯字導致統計對不起來。
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _fa;
  bool _ready = false;

  /// Firebase 初始化成功後呼叫。失敗就維持 no-op 模式。
  void init() {
    try {
      _fa = FirebaseAnalytics.instance;
      _ready = true;
      LoggerService().log('Analytics: 已啟用');
    } catch (e) {
      _ready = false;
      LoggerService().log('Analytics: 停用（Firebase 未就緒）→ $e');
    }
  }

  Future<void> _log(String name, [Map<String, Object>? params]) async {
    if (!_ready || _fa == null) return;
    try {
      await _fa!.logEvent(name: name, parameters: params);
    } catch (e) {
      // 統計失敗絕不能影響主流程，吞掉但留 log。
      LoggerService().log('Analytics: 送出 $name 失敗 → $e');
    }
  }

  // ── AI 帳單辨識 ───────────────────────────────────────────────────────────

  /// 使用者選了哪種輸入方式。method: text / gallery / camera
  Future<void> billInputStarted(String method) =>
      _log('bill_input_started', {'method': method});

  /// 辨識成功。source 區分是 proxy 還是直連備援，方便看備援被觸發的頻率。
  Future<void> billExtractSuccess({
    required String method,
    required String source,
    required String provider,
    required int latencyMs,
  }) =>
      _log('bill_extract_success', {
        'method': method,
        'source': source,
        'provider': provider,
        'latency_ms': latencyMs,
      });

  /// 辨識失敗（proxy 與備援都失敗）。reason 用簡短分類字串，不要塞整段例外訊息。
  Future<void> billExtractFailed({
    required String method,
    required String reason,
  }) =>
      _log('bill_extract_failed', {'method': method, 'reason': reason});

  /// proxy 失敗、退到直連備援時記一筆，這是要盯的健康指標。
  Future<void> proxyFallback(String reason) =>
      _log('ai_proxy_fallback', {'reason': reason});

  // ── 帳單操作 ─────────────────────────────────────────────────────────────

  Future<void> billAdded({required String category, required bool recurring}) =>
      _log('bill_added', {'category': category, 'recurring': recurring ? 1 : 0});

  Future<void> billEdited() => _log('bill_edited');

  Future<void> billDeleted() => _log('bill_deleted');

  // ── 其他 ─────────────────────────────────────────────────────────────────

  Future<void> notificationToggled(bool enabled) =>
      _log('notification_toggled', {'enabled': enabled ? 1 : 0});

  Future<void> tutorialCompleted() => _log('tutorial_completed');

  Future<void> adShown() => _log('ad_shown');
}
