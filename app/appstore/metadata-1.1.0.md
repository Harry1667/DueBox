# DueBox 1.1.0 App Store 文案（草稿，待確認後推送到 ASC）

目前線上版本：**1.0.1（READY_FOR_SALE）**，最後一個 build 號 3。
本次建議版號 **1.1.0**——新增了週期性帳單提醒與已繳費標記兩個功能，
不只是修 bug，用 1.0.2 會低估這次的變動幅度。

三個語系都要更新：`en-US` / `zh-Hant` / `zh-Hans`。

---

## 更新說明 What's New（本次新增，1.0.1 目前是空的）

### zh-Hant

```
本次更新讓「訂閱制帳單」真正被管好，並修正多項提醒相關問題。

新功能
• 週期性帳單：偵測到月費／年費的帳單，往後每一期都會自動提醒，不再只提醒第一次
• 標記已繳費：繳完的帳單可以標記完成，不再提醒，也不計入待繳總額

問題修正
• 修正提醒時間與提前天數改過之後，既有帳單沒有跟著重新排程的問題
• 修正通知開關關不掉的問題
• 修正當天新增、且已過提醒時間的帳單完全收不到提醒的問題
• 修正帳單在分類之間移動時，週期設定會遺失的問題
• 修正週期選單出現無法實際生效的選項
• 通知內容現在會跟隨系統語言顯示

其他改善
• 帳單辨識改用新的分析服務，速度與穩定度提升
• 金額若含逗號或貨幣符號也能正確辨識
```

### zh-Hans

```
本次更新让「订阅制账单」真正被管好，并修正多项提醒相关问题。

新功能
• 周期性账单：检测到月费／年费的账单，往后每一期都会自动提醒，不再只提醒第一次
• 标记已缴费：缴完的账单可以标记完成，不再提醒，也不计入待缴总额

问题修正
• 修正提醒时间与提前天数改过之后，既有账单没有跟着重新排程的问题
• 修正通知开关关不掉的问题
• 修正当天新增、且已过提醒时间的账单完全收不到提醒的问题
• 修正账单在分类之间移动时，周期设置会丢失的问题
• 修正周期菜单出现无法实际生效的选项
• 通知内容现在会跟随系统语言显示

其他改善
• 账单识别改用新的分析服务，速度与稳定度提升
• 金额若含逗号或货币符号也能正确识别
```

### en-US

```
This update makes recurring bills actually work, and fixes several reminder issues.

New
• Recurring bills: monthly and yearly bills now remind you every cycle, not just once
• Mark as paid: completed bills stop reminding you and are excluded from your pending total

Fixed
• Changing the reminder time or lead days now reschedules existing bills
• The notification toggle can be turned off again
• Bills added on their due date after the reminder time no longer go completely silent
• Moving a bill between categories no longer loses its recurrence setting
• Removed recurrence options that could not actually take effect
• Notification text now follows your system language

Improved
• Faster and more reliable bill recognition
• Amounts containing commas or currency symbols are now parsed correctly
```

---

## 商店說明 Description（更新版）

相對於 1.0.1 的改動：把「週期性帳單」與「已繳費管理」寫進功能列表，
其餘結構與語氣沿用既有版本，避免整份重寫造成審核端的落差感。

### zh-Hant

```
DueBox 是一款智慧帳單管理應用，旨在幫助您避免錯過付款日期。它結合了人工智慧輔助輸入和清晰的本地提醒，讓您更輕鬆地整理帳單並追蹤待付款項。

錯過付款往往並非因為遺忘，而是因為資訊分散、金額不明確或提醒不足。DueBox 致力於將帳單轉化為清晰易懂、便於管理的條目，讓您輕鬆管理帳單。

主要功能

AI 輔助帳單輸入

照片拍攝：拍攝紙質帳單照片，AI 即可提取關鍵資訊，例如金額、到期日和類別

照片上傳：選擇螢幕截圖或圖庫中的圖片進行分析

文字解析：貼上簡訊或電子郵件內容，自動提取帳單資訊

週期性帳單

自動辨識月費與年費類型的訂閱帳單

每一期都會持續提醒，不需要每個月重新輸入

帳單概覽

在一個地方查看所有帳單和即將到期的付款

自動顯示即將到期、逾期和已完成帳單的狀態

針對信用卡、水電瓦斯費和訂閱等常見帳單類型進行分類管理

繳費狀態管理

繳完的帳單可標記為已繳費，停止提醒並自動從待繳總額中扣除

到期日提醒

帳單到期前，iOS 本地通知提醒

可自訂提醒時間與提前天數，配合您的作息

有助於降低因疏忽或繁忙日程而導致的逾期付款風險

重要提示

AI 辨識結果可能因影像品質和內容格式而異。請在付款前核實帳單金額和到期日。DueBox 是一款帳單管理和提醒工具，並非支付或銀行服務。
```

### zh-Hans

```
DueBox 是一款智能账单管理应用，旨在帮助您避免错过付款日期。它结合了人工智能辅助输入和清晰的本地提醒，让您更轻松地整理账单并追踪待付款项。

错过付款往往并非因为遗忘，而是因为信息分散、金额不明确或提醒不足。DueBox 致力于将账单转化为清晰易懂、便于管理的条目，让您轻松管理账单。

主要功能

AI 辅助账单录入

照片拍摄：拍摄纸质账单照片，AI 即可提取关键信息，例如金额、到期日和类别

照片上传：选择屏幕截图或图库中的图片进行分析

文本解析：粘贴短信或电子邮件内容，自动提取账单信息

周期性账单

自动识别月费与年费类型的订阅账单

每一期都会持续提醒，不需要每个月重新输入

账单概览

在一个地方查看所有账单和即将到期的付款

自动显示即将到期、逾期和已完成账单的状态

针对信用卡、水电煤气费和订阅等常见账单类型进行分类管理

缴费状态管理

缴完的账单可标记为已缴费，停止提醒并自动从待缴总额中扣除

到期日提醒

账单到期前，iOS 本地通知提醒

可自定义提醒时间与提前天数，配合您的作息

有助于降低因疏忽或繁忙日程而导致的逾期付款风险

重要提示

AI 识别结果可能因图像质量和内容格式而异。请在付款前核实账单金额和到期日。DueBox 是一款账单管理和提醒工具，并非支付或银行服务。
```

### en-US

```
DueBox is a smart bill management app designed to help you avoid missing due dates. By combining AI-assisted input with clear local reminders, DueBox makes it easier to organize bills and track what needs to be paid.

Missed payments are often not caused by forgetting, but by scattered information, unclear amounts, or insufficient reminders. DueBox focuses on turning bills into clear, manageable items with minimal effort.

Key Features

AI-Assisted Bill Input

Photo capture: Take a picture of a physical bill and let AI extract key details such as amount, due date, and category

Photo upload: Select screenshots or images from your gallery for analysis

Text parsing: Paste SMS or email content and automatically extract bill information

Recurring Bills

Automatically detects monthly and yearly subscription bills

Reminds you every cycle, so you never need to re-enter the same bill

Bill Dashboard

View all bills and upcoming payments in one place

Automatic status indicators for upcoming, overdue, and completed bills

Category management for common bill types such as credit cards, utilities, and subscriptions

Payment Status

Mark a bill as paid to stop its reminders and remove it from your pending total

Due Date Reminders

Local iOS notifications before bills are due

Customizable reminder time and lead days to fit your routine

Helps reduce the risk of late payments caused by oversight or busy schedules

Important Notice

AI recognition results may vary depending on image quality and content format. Please verify bill amounts and due dates before making payments. DueBox is a bill management and reminder tool, not a payment or banking service.
```

---

## 關鍵字 Keywords（建議微調）

現有關鍵字沒有涵蓋本次新增的「訂閱管理」這個高搜尋量情境。
上限 100 字元，中文用全形頓號會佔字元，建議改用半形逗號。

| 語系 | 現有 | 建議 |
|---|---|---|
| en-US | `bill reminder,due date,bill tracker,payment reminder,AI OCR,utilities,credit card` | `bill reminder,subscription tracker,due date,recurring,payment reminder,OCR scan,utilities` |
| zh-Hant | `帳單提醒、到期日、帳單追蹤、付款提醒、AI OCR、公用事業、信用卡` | `帳單提醒,訂閱管理,月費,到期日,繳費提醒,帳單掃描,信用卡,水電費` |
| zh-Hans | `账单提醒、到期日、账单追踪、付款提醒、AI OCR、公用事业、信用卡` | `账单提醒,订阅管理,月费,到期日,缴费提醒,账单扫描,信用卡,水电费` |

---

## 需要一併修掉的現有缺陷

**zh-Hans 的 promotional text 目前是英文**：

> Too many bills to remember? DueBox helps you organize payments, see what's due, and get reminders before deadlines arrive.

簡體使用者會在商店頁看到英文宣傳語。建議改成：

```
账单太多记不住？DueBox 帮你整理付款、查看到期日，并在截止日期前收到提醒。
```

（zh-Hant 的宣傳語本身沒問題，但「DueBox 可以幫助您」前面有多餘空格，一併清掉。）
