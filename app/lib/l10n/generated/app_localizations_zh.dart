// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'DueBox';

  @override
  String get appSlogan => '轻松管理您的账单，\n不再逾期。';

  @override
  String get dashboardTitle => '我的账单';

  @override
  String get totalPending => '待缴总额';

  @override
  String get addFirstBill => '点击 + 新增第一笔账单';

  @override
  String get notificationScheduled => '已开启并排程通知';

  @override
  String get addSuccess => '✅ 新增成功！';

  @override
  String addFail(Object message) {
    return '❌ 失败: $message';
  }

  @override
  String deleteGroupTitle(Object groupId) {
    return '删除分组 \"$groupId\"?';
  }

  @override
  String get deleteGroupContent => '这将删除分组内的所有账单。';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get editGroupName => '编辑分组名称';

  @override
  String get save => '保存';

  @override
  String get pickColor => '变更颜色';

  @override
  String get changeColor => '变更颜色';

  @override
  String get pinUnpin => '置顶/取消置顶';

  @override
  String get moveUp => '分组上移';

  @override
  String get moveDown => '分组下移';

  @override
  String get deleteGroup => '删除分组';

  @override
  String get editTitle => '修改标题';

  @override
  String get enterNewTitle => '输入新的标题';

  @override
  String items(Object count) {
    return '$count 项目';
  }

  @override
  String get billInputTitle => '输入账单信息';

  @override
  String get billInputHint => '在此粘贴短信、Email 内容...';

  @override
  String get startAiAnalysis => '开始 AI 分析';

  @override
  String get textInput => '文字输入';

  @override
  String get galleryUpload => '相册上传';

  @override
  String get cameraScan => '拍照识别';

  @override
  String get settingsTitle => '设置';

  @override
  String get generalSettings => '一般设置';

  @override
  String get homeTitle => '首页标题';

  @override
  String get notificationsReminders => '通知与提醒';

  @override
  String get enableNotifications => '接受通知';

  @override
  String get reminderTime => '提醒时间';

  @override
  String get reminderTimeDesc => '设定每日发送通知的时间';

  @override
  String get advanceReminder => '提前提醒';

  @override
  String get advanceReminderDesc => '除当日与前一日外，额外提醒天数';

  @override
  String get daysBefore => '前';

  @override
  String get days => '天';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get statusPaid => '已缴费';

  @override
  String statusOverdue(Object days) {
    return '已逾期 $days 天';
  }

  @override
  String statusRemaining(Object days) {
    return '还有 $days 天';
  }

  @override
  String get generalBill => '一般账单';

  @override
  String get monthly => '每月';

  @override
  String get yearly => '每年';

  @override
  String get dueDate => '缴费期限';

  @override
  String get note => '备注';

  @override
  String get editBill => '编辑账单';

  @override
  String get title => '标题';

  @override
  String get amount => '金额';

  @override
  String get categoryMoveGroup => '分类 (将移动到对应分组)';

  @override
  String get recurrence => '周期';

  @override
  String get none => '无';

  @override
  String get daily => '每天';

  @override
  String get weekly => '每周';

  @override
  String get deleteBillConfirm => '删除账单?';

  @override
  String get deleteBillContent => '永久删除此账单?';

  @override
  String get tutorialStep1Title => '账单展示区块';

  @override
  String get tutorialStep1Desc => '这是查看所有要提醒的账单的地方 \n 动作：点击任意处可进入下一步';

  @override
  String get tutorialStep2Title => '添加账单按钮';

  @override
  String get tutorialStep2Desc => '这是添加账单的地方';

  @override
  String get tutorialStep3Title => '新增记录选单区域';

  @override
  String get tutorialStep3Desc => '这是三种记录方式';

  @override
  String get tutorialStep4Title => '文字输入';

  @override
  String get tutorialStep4Desc => '在这里粘贴短信，Email文字，可以自动获取账单内容';

  @override
  String get tutorialStep5Title => '相册上传';

  @override
  String get tutorialStep5Desc => '在这里上传照片，可以自动获取账单内容';

  @override
  String get tutorialStep6Title => '拍照识别';

  @override
  String get tutorialStep6Desc => '在这里拍照，可以自动获取账单内容';

  @override
  String get tutorialStep7Title => '开始记录';

  @override
  String get tutorialStep7Desc => '选择一种你喜欢的方式开始记录';

  @override
  String get tutorialStep8Title => '你的记录';

  @override
  String get tutorialStep8Desc => '这是你的记录，我们会在这笔账单到期前提醒你';

  @override
  String get tutorialStep9Title => '编辑功能';

  @override
  String get tutorialStep9Desc => '这是编辑账单的页面';

  @override
  String get tutorialFinishTitle => '恭喜！';

  @override
  String get tutorialFinishDesc => '感谢您完成教程，欢迎使用DueBox';
}

/// The translations for Chinese, as used in China (`zh_CN`).
class AppLocalizationsZhCn extends AppLocalizationsZh {
  AppLocalizationsZhCn() : super('zh_CN');

  @override
  String get appTitle => 'DueBox';

  @override
  String get appSlogan => '轻松管理您的账单，\n不再逾期。';

  @override
  String get dashboardTitle => '我的账单';

  @override
  String get totalPending => '待缴总额';

  @override
  String get addFirstBill => '点击 + 新增第一笔账单';

  @override
  String get notificationScheduled => '已开启并排程通知';

  @override
  String get addSuccess => '✅ 新增成功！';

  @override
  String addFail(Object message) {
    return '❌ 失败: $message';
  }

  @override
  String deleteGroupTitle(Object groupId) {
    return '删除分组 \"$groupId\"?';
  }

  @override
  String get deleteGroupContent => '这将删除分组内的所有账单。';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get editGroupName => '编辑分组名称';

  @override
  String get save => '保存';

  @override
  String get pickColor => '变更颜色';

  @override
  String get changeColor => '变更颜色';

  @override
  String get pinUnpin => '置顶/取消置顶';

  @override
  String get moveUp => '分组上移';

  @override
  String get moveDown => '分组下移';

  @override
  String get deleteGroup => '删除分组';

  @override
  String get editTitle => '修改标题';

  @override
  String get enterNewTitle => '输入新的标题';

  @override
  String items(Object count) {
    return '$count 项目';
  }

  @override
  String get billInputTitle => '输入账单信息';

  @override
  String get billInputHint => '在此粘贴短信、Email 内容...';

  @override
  String get startAiAnalysis => '开始 AI 分析';

  @override
  String get textInput => '文字输入';

  @override
  String get galleryUpload => '相册上传';

  @override
  String get cameraScan => '拍照识别';

  @override
  String get settingsTitle => '设置';

  @override
  String get generalSettings => '一般设置';

  @override
  String get homeTitle => '首页标题';

  @override
  String get notificationsReminders => '通知与提醒';

  @override
  String get enableNotifications => '接受通知';

  @override
  String get reminderTime => '提醒时间';

  @override
  String get reminderTimeDesc => '设定每日发送通知的时间';

  @override
  String get advanceReminder => '提前提醒';

  @override
  String get advanceReminderDesc => '除当日与前一日外，额外提醒天数';

  @override
  String get daysBefore => '前';

  @override
  String get days => '天';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get statusPaid => '已缴费';

  @override
  String statusOverdue(Object days) {
    return '已逾期 $days 天';
  }

  @override
  String statusRemaining(Object days) {
    return '还有 $days 天';
  }

  @override
  String get generalBill => '一般账单';

  @override
  String get monthly => '每月';

  @override
  String get yearly => '每年';

  @override
  String get dueDate => '缴费期限';

  @override
  String get note => '备注';

  @override
  String get editBill => '编辑账单';

  @override
  String get title => '标题';

  @override
  String get amount => '金额';

  @override
  String get categoryMoveGroup => '分类 (将移动到对应分组)';

  @override
  String get recurrence => '周期';

  @override
  String get none => '无';

  @override
  String get daily => '每天';

  @override
  String get weekly => '每周';

  @override
  String get deleteBillConfirm => '删除账单?';

  @override
  String get deleteBillContent => '永久删除此账单?';

  @override
  String get tutorialStep1Title => '账单展示区块';

  @override
  String get tutorialStep1Desc => '这是查看所有要提醒的账单的地方 \n 动作：点击任意处可进入下一步';

  @override
  String get tutorialStep2Title => '添加账单按钮';

  @override
  String get tutorialStep2Desc => '这是添加账单的地方';

  @override
  String get tutorialStep3Title => '新增记录选单区域';

  @override
  String get tutorialStep3Desc => '这是三种记录方式';

  @override
  String get tutorialStep4Title => '文字输入';

  @override
  String get tutorialStep4Desc => '在这里粘贴短信，Email文字，可以自动获取账单内容';

  @override
  String get tutorialStep5Title => '相册上传';

  @override
  String get tutorialStep5Desc => '在这里上传照片，可以自动获取账单内容';

  @override
  String get tutorialStep6Title => '拍照识别';

  @override
  String get tutorialStep6Desc => '在这里拍照，可以自动获取账单内容';

  @override
  String get tutorialStep7Title => '开始记录';

  @override
  String get tutorialStep7Desc => '选择一种你喜欢的方式开始记录';

  @override
  String get tutorialStep8Title => '你的记录';

  @override
  String get tutorialStep8Desc => '这是你的记录，我们会在这笔账单到期前提醒你';

  @override
  String get tutorialStep9Title => '编辑功能';

  @override
  String get tutorialStep9Desc => '这是编辑账单的页面';

  @override
  String get tutorialFinishTitle => '恭喜！';

  @override
  String get tutorialFinishDesc => '感谢您完成教程，欢迎使用DueBox';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => 'DueBox';

  @override
  String get appSlogan => '輕鬆管理您的帳單，\n不再逾期。';

  @override
  String get dashboardTitle => '我的帳單';

  @override
  String get totalPending => '待繳總額';

  @override
  String get addFirstBill => '點擊 + 新增第一筆帳單';

  @override
  String get notificationScheduled => '已開啟並排程通知';

  @override
  String get addSuccess => '✅ 新增成功！';

  @override
  String addFail(Object message) {
    return '❌ 失敗: $message';
  }

  @override
  String deleteGroupTitle(Object groupId) {
    return '刪除群組 \"$groupId\"?';
  }

  @override
  String get deleteGroupContent => '這將會刪除群組內的所有帳單。';

  @override
  String get cancel => '取消';

  @override
  String get delete => '刪除';

  @override
  String get editGroupName => '編輯群組名稱';

  @override
  String get save => '儲存';

  @override
  String get pickColor => '變更顏色';

  @override
  String get changeColor => '變更顏色';

  @override
  String get pinUnpin => '置頂/取消置頂';

  @override
  String get moveUp => '群組上移';

  @override
  String get moveDown => '群組下移';

  @override
  String get deleteGroup => '刪除群組';

  @override
  String get editTitle => '修改標題';

  @override
  String get enterNewTitle => '輸入新的標題';

  @override
  String items(Object count) {
    return '$count 項目';
  }

  @override
  String get billInputTitle => '輸入帳單資訊';

  @override
  String get billInputHint => '在此貼上簡訊、Email 內容...';

  @override
  String get startAiAnalysis => '開始 AI 分析';

  @override
  String get textInput => '文字輸入';

  @override
  String get galleryUpload => '相簿上傳';

  @override
  String get cameraScan => '拍照辨識';

  @override
  String get settingsTitle => '設定';

  @override
  String get generalSettings => '一般設定';

  @override
  String get homeTitle => '首頁標題';

  @override
  String get notificationsReminders => '通知與提醒';

  @override
  String get enableNotifications => '接受通知';

  @override
  String get reminderTime => '提醒時間';

  @override
  String get reminderTimeDesc => '設定每日發送通知的時間';

  @override
  String get advanceReminder => '提前提醒';

  @override
  String get advanceReminderDesc => '除當日與前一日外，額外提醒天數';

  @override
  String get daysBefore => '前';

  @override
  String get days => '天';

  @override
  String get about => '關於';

  @override
  String get version => '版本';

  @override
  String get statusPaid => '已繳費';

  @override
  String statusOverdue(Object days) {
    return '已逾期 $days 天';
  }

  @override
  String statusRemaining(Object days) {
    return '還有 $days 天';
  }

  @override
  String get generalBill => '一般帳單';

  @override
  String get monthly => '每月';

  @override
  String get yearly => '每年';

  @override
  String get dueDate => '繳費期限';

  @override
  String get note => '備註';

  @override
  String get editBill => '編輯帳單';

  @override
  String get title => '標題';

  @override
  String get amount => '金額';

  @override
  String get categoryMoveGroup => '分類 (將移動到對應群組)';

  @override
  String get recurrence => '週期';

  @override
  String get none => '無';

  @override
  String get daily => '每天';

  @override
  String get weekly => '每週';

  @override
  String get deleteBillConfirm => '刪除帳單?';

  @override
  String get deleteBillContent => '永久刪除此帳單?';

  @override
  String get tutorialStep1Title => '帳單展示區塊';

  @override
  String get tutorialStep1Desc => '這是查看所有要提醒的帳單的地方 \n 動作：點擊任意處可進入下一步';

  @override
  String get tutorialStep2Title => '添加帳單按鈕';

  @override
  String get tutorialStep2Desc => '這是添加帳單的地方';

  @override
  String get tutorialStep3Title => '新增紀錄選單區域';

  @override
  String get tutorialStep3Desc => '這是三種紀錄方式';

  @override
  String get tutorialStep4Title => '文字輸入';

  @override
  String get tutorialStep4Desc => '在這裡貼上簡訊，Email文字，可以自動獲取帳單內容';

  @override
  String get tutorialStep5Title => '相簿上傳';

  @override
  String get tutorialStep5Desc => '在這裡上傳照片，可以自動獲取帳單內容';

  @override
  String get tutorialStep6Title => '拍照辨識';

  @override
  String get tutorialStep6Desc => '在這裡拍照，可以自動獲取帳單內容';

  @override
  String get tutorialStep7Title => '開始紀錄';

  @override
  String get tutorialStep7Desc => '選擇一種你喜歡的方式開始紀錄';

  @override
  String get tutorialStep8Title => '你的紀錄';

  @override
  String get tutorialStep8Desc => '這是你的紀錄，我們會在這個帳單到期前提醒你';

  @override
  String get tutorialStep9Title => '編輯功能';

  @override
  String get tutorialStep9Desc => '這是編輯帳單的頁面';

  @override
  String get tutorialFinishTitle => '恭喜！';

  @override
  String get tutorialFinishDesc => '感謝您完成教程，歡迎使用DueBox';
}
