# DueBox

Flutter 開發的 iOS 智慧帳單管理 App。用 AI 辨識帳單圖片與文字，自動擷取金額、
到期日與週期，並在到期前推播提醒。

## 首次設定（clone 之後必做）

專案有兩個含金鑰的檔案不進版控（這個 repo 是公開的）。少了它們會直接編譯失敗，
錯誤訊息會指名缺哪個檔案。

```bash
cd app

# 1. AI 服務金鑰（App 執行時需要）
cp lib/services/secrets.example.dart lib/services/secrets.dart
#    編輯 secrets.dart，填入 proxy token / proxy 專案名

# 2. Firebase Remote Config 部署範本（只有要更新遠端設定時才需要）
cp remoteconfig.template.example.json remoteconfig.template.json

flutter pub get
```

另外需要 `ios/Runner/GoogleService-Info.plist`（Firebase iOS 設定）。若遺失，
執行 `flutterfire configure -p duebox-ec228 --platforms=ios -i com.gomiigo.DueBoxApp -y`
重新產生。

## 執行與驗證

```bash
flutter analyze          # 應為 No issues found
flutter test             # 單元測試
flutter build ios --no-codesign --debug
```

日常開發在 Xcode 開啟 `ios/Runner.xcworkspace` 直接 Run。

## AI 服務架構

帳單辨識只走 **proxy-cli** — `clip.twloop.com/api/chat`。圖片走 Gemini CLI 的
OAuth 免費額度，文字走 auto-route 自動選模型。用量集中記錄在 proxy 儀表板。
失敗會送出 `bill_extract_failed` 事件並把錯誤顯示給使用者，不會安靜地回 null。

App 不持有 Gemini 金鑰：放進 App 的任何值（程式碼或 Remote Config）都能被取出，
所以上游金鑰只放在 proxy 伺服器上。不要再加回 Gemini 直連備援。

### 遠端可調的設定

以下參數放在 Firebase Remote Config（專案 `duebox-ec228`），可以在主控台直接改，
不需要重新送審發版。App 讀不到時退回 `secrets.dart` 與程式碼內建的預設值。

| 參數 | 用途 |
|---|---|
| `ai_proxy_url` / `ai_proxy_token` / `ai_proxy_project` | proxy 連線設定 |

更新方式：改 `remoteconfig.template.json` 後 `firebase deploy --only remoteconfig`。

## 專案結構

- `lib/main.dart` — 進入點，負責 Firebase 初始化
- `lib/pages/` — 各頁面（主畫面、設定、歡迎頁、debug console）
- `lib/widgets/` — 可重用元件（帳單卡片、Logo）
- `lib/services/` — AI 辨識、通知排程、廣告、教學引導、統計、遠端設定
- `lib/types/` — 資料模型（Bill、BillGroup）
- `lib/l10n/` — 語系檔（en / zh / zh-CN / zh-TW）

## 注意事項

- **最低支援 iOS 15.0** — Firebase 4.x 的要求，不能再往下降。
- **廣告單元** — Debug 建置自動使用 Google 測試單元；Release 才會用正式單元。
  不要把 `AdService._isTestMode` 改成寫死 false，開發時點到自己的正式廣告會被
  AdMob 判定為無效流量。
- **proxy token 仍會被打包進 IPA** — gitignore 只防止它出現在公開 repo。
  token 外洩時到 clip.twloop.com 換發，再更新 Remote Config 的 `ai_proxy_token`。
