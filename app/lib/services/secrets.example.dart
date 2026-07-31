// 這是範本檔。實際使用時複製一份成 secrets.dart 並填入真實值：
//
//     cp lib/services/secrets.example.dart lib/services/secrets.dart
//
// secrets.dart 已被 .gitignore 排除，不會進版控。
// 這個範本檔則會進版控，讓任何人 clone 之後知道要準備哪些值。
//
// 為什麼用「gitignore 一個 Dart 檔」而不是 --dart-define：
// 這個專案是在 Xcode 直接按 Run 開發的，--dart-define 得額外設定 scheme 或
// xcconfig，容易漏掉而且漏掉時是安靜地帶著空金鑰出貨。用檔案的話，忘記建立
// secrets.dart 會直接編譯失敗，錯誤明確、不可能默默出錯。
//
// ⚠️ 注意：這些值最終仍會被打包進 IPA，可以被反編譯取出。這一層只防止金鑰
// 出現在公開的 GitHub repo（爬蟲掃到公開金鑰是分鐘級的）。真正的解法是讓
// App 只持有 proxy token、不持有上游供應商金鑰——等 proxy 穩定運行之後，
// 就可以把 Gemini 直連備援整段移除。

class Secrets {
  /// proxy-cli 的 Bearer token。到 clip.twloop.com 的用戶列表取得。
  static const proxyToken = 'YOUR_PROXY_TOKEN';

  /// proxy-cli 的專案名稱，用量會歸類到這個專案底下。
  static const proxyProject = 'YOUR_PROXY_PROJECT';

  /// proxy 失敗時的 Gemini 直連備援金鑰。到 Google AI Studio 取得。
  static const geminiApiKey = 'YOUR_GEMINI_API_KEY';
}
