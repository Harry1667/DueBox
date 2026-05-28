# DueBox（DueDay）

智慧帳單管理 iOS App — AI OCR 掃描帳單，自動識別金額與到期日，提醒避免逾期。

## 功能
- **三種輸入方式**：
  - 📷 拍照辨識：拍攝實體帳單，AI 自動擷取金額、日期、類別
  - 🖼️ 相簿上傳：從相簿選圖進行 AI 分析
  - 📝 文字輸入：貼上簡訊或 Email 通知，AI 智慧解析
- **帳單儀表板**：待繳總額 + 狀態標示（🔴 逾期 / 🟡 即將到期 / 🟢 已繳）
- **分類管理**：自定義群組（信用卡、水電費等）+ 拖曳排序
- **到期提醒**：本地推播通知
- **廣告 / 訂閱**：免費觀看廣告獲得 AI 額度；訂閱解鎖無限功能
- **深色模式**（OLED 優化）

## 技術棧
- Flutter（iOS）
- Google Gemini（OCR + NLP）
- shared_preferences + flutter_local_notifications
- AdMob + IAP

## 快速開始
```bash
cd app
flutter pub get
flutter run
```

---

## English

A smart bill manager for iOS. AI OCR pulls the amount and due date out of any bill so you never miss a payment.

### Features
- **Three input methods**:
  - 📷 Photo capture: snap a paper bill; AI extracts amount, date, category
  - 🖼️ Album upload: pick an image; same AI flow
  - 📝 Text input: paste an SMS or email notification; AI parses it
- **Bill dashboard**: total due + status badges (🔴 overdue / 🟡 due soon / 🟢 paid)
- **Categories**: custom groups (credit card, utilities, etc.) with drag-to-reorder
- **Due reminders**: local push notifications
- **Ads / subscription**: free tier earns AI credits via rewarded ads; subscription unlocks unlimited
- **Dark mode** (OLED-optimized)

### Tech stack
- Flutter (iOS)
- Google Gemini (OCR + NLP)
- shared_preferences + flutter_local_notifications
- AdMob + IAP

### Quick start
```bash
cd app
flutter pub get
flutter run
```
