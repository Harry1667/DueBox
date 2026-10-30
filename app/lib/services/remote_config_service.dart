import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'logger_service.dart';
import 'secrets.dart';

/// Firebase Remote Config 包裝層。
///
/// 為什麼要這一層：AI 相關的設定（proxy 位址／token／專案名）
/// 如果寫死在程式碼裡，一旦金鑰失效或模型被 Google 下架，就只能重新送審發版
/// 才能修好。放進 Remote Config 之後，可以在 Firebase 主控台直接改，
/// App 下次啟動（或 12 小時後自動拉取）就會生效。
///
/// 每個設定都保留「內建預設值」：Firebase 沒設定、沒網路、甚至整個 Firebase
/// 都還沒設定好的情況下，一律退回預設值，絕不讓 App 因為讀不到設定而壞掉。
class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  // ── Remote Config 的鍵名（要在 Firebase 主控台建同名參數才能覆寫）──────────
  static const keyProxyUrl = 'ai_proxy_url';
  static const keyProxyToken = 'ai_proxy_token';
  static const keyProxyProject = 'ai_proxy_project';

  /// 內建預設值。Remote Config 讀不到時就用這一組。
  ///
  /// 金鑰類的值來自 secrets.dart（已 gitignore），不直接寫在這裡——
  /// 這個 repo 是公開的，寫在這裡等於把金鑰貼上網路。
  static const Map<String, dynamic> _defaults = {
    keyProxyUrl: 'https://clip.twloop.com/api/chat',
    keyProxyToken: Secrets.proxyToken,
    keyProxyProject: Secrets.proxyProject,
  };

  FirebaseRemoteConfig? _rc;
  bool _ready = false;

  /// 初始化。Firebase 尚未設定完成時會安靜失敗，之後所有讀取都走預設值。
  Future<void> init() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        // 開發期設短一點才看得到改動；正式版建議調回 1 小時以上避免頻繁請求。
        minimumFetchInterval: const Duration(minutes: 15),
      ));
      await rc.setDefaults(_defaults);
      await rc.fetchAndActivate();
      _rc = rc;
      _ready = true;
      LoggerService().log('RemoteConfig: 已啟用，來源=${rc.getString(keyProxyProject)}');
    } catch (e) {
      // 沒有 GoogleService-Info.plist、沒網路、或 Firebase 專案沒開 Remote Config
      // 都會走到這裡。這不是致命錯誤，只是退回內建設定。
      _ready = false;
      LoggerService().log('RemoteConfig: 初始化失敗，改用內建預設值 → $e');
    }
  }

  String getString(String key) {
    if (_ready && _rc != null) {
      final v = _rc!.getString(key);
      if (v.isNotEmpty) return v;
    }
    return _defaults[key] as String? ?? '';
  }

  // ── 方便呼叫的具名 getter ─────────────────────────────────────────────────
  String get proxyUrl => getString(keyProxyUrl);
  String get proxyToken => getString(keyProxyToken);
  String get proxyProject => getString(keyProxyProject);
}
