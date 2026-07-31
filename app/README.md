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
#    編輯 secrets.dart，填入 proxy token / proxy 專案名 / Gemini 金鑰

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

帳單辨識有兩條路徑，優先順序固定：

1. **proxy-cli（主要）** — `clip.twloop.com/api/chat`。圖片走 Gemini CLI 的 OAuth
   免費額度，文字走 auto-route 自動選模型。用量集中記錄在 proxy 儀表板。
2. **Gemini 直連（備援）** — 只在 proxy 逾時、回非 200、或回傳內容解不出 JSON 時
   啟用。備援被觸發會送出 `ai_proxy_fallback` 事件到 Firebase Analytics，
   這是要盯的健康指標——備援會安靜地把事情做完，不主動觀測不會知道 proxy 壞了。

兩條路都失敗才會丟出錯誤給使用者，不會安靜地回 null。

### 遠端可調的設定

以下參數放在 Firebase Remote Config（專案 `duebox-ec228`），可以在主控台直接改，
不需要重新送審發版。App 讀不到時退回 `secrets.dart` 與程式碼內建的預設值。

| 參數 | 用途 |
|---|---|
| `ai_use_proxy` | 關閉後直接走 Gemini 直連（proxy 整個掛掉時的逃生門） |
| `ai_proxy_url` / `ai_proxy_token` / `ai_proxy_project` | proxy 連線設定 |
| `gemini_api_key` | 備援金鑰，失效時改這裡 |
| `gemini_model` | 備援模型。**`gemini-2.5-flash` 已對新金鑰下架（回 404）**，用 `-latest` 別名 |

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
- **金鑰仍會被打包進 IPA** — gitignore 只防止金鑰出現在公開 repo。真正的解法是
  讓 App 只持有 proxy token，等 proxy 穩定後移除 Gemini 直連備援。
