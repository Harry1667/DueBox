// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DueBox';

  @override
  String get appSlogan => 'Manage your bills,\nstress-free.';

  @override
  String get dashboardTitle => 'My Bills';

  @override
  String get totalPending => 'Total Pending';

  @override
  String get addFirstBill => 'Tap + to add your first bill';

  @override
  String get notificationScheduled => 'Notifications enabled and scheduled';

  @override
  String get addSuccess => 'Success: Added!';

  @override
  String addFail(Object message) {
    return 'Failed: $message';
  }

  @override
  String deleteGroupTitle(Object groupId) {
    return 'Delete group \"$groupId\"?';
  }

  @override
  String get deleteGroupContent => 'This will delete all bills in this group.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get editGroupName => 'Edit Group Name';

  @override
  String get save => 'Save';

  @override
  String get pickColor => 'Pick Color';

  @override
  String get changeColor => 'Change Color';

  @override
  String get pinUnpin => 'Pin/Unpin';

  @override
  String get moveUp => 'Move Up';

  @override
  String get moveDown => 'Move Down';

  @override
  String get deleteGroup => 'Delete Group';

  @override
  String get editTitle => 'Edit Title';

  @override
  String get enterNewTitle => 'Enter new title';

  @override
  String items(Object count) {
    return '$count Items';
  }

  @override
  String get billInputTitle => 'Enter Bill Info';

  @override
  String get billInputHint => 'Paste SMS or Email content here...';

  @override
  String get startAiAnalysis => 'Start AI Analysis';

  @override
  String get textInput => 'Text Input';

  @override
  String get galleryUpload => 'Gallery Upload';

  @override
  String get cameraScan => 'Camera Scan';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get generalSettings => 'General';

  @override
  String get homeTitle => 'Home Title';

  @override
  String get notificationsReminders => 'Notifications & Reminders';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get reminderTime => 'Reminder Time';

  @override
  String get reminderTimeDesc => 'Set daily notification time';

  @override
  String get advanceReminder => 'Advance Reminder';

  @override
  String get advanceReminderDesc =>
      'Extra reminder days besides due day and day before';

  @override
  String get daysBefore => 'Days Before';

  @override
  String get days => 'Days';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get statusPaid => 'Paid';

  @override
  String statusOverdue(Object days) {
    return 'Overdue by $days days';
  }

  @override
  String statusRemaining(Object days) {
    return '$days days left';
  }

  @override
  String get generalBill => 'General Bill';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String get dueDate => 'Due Date';

  @override
  String get note => 'Note';

  @override
  String get editBill => 'Edit Bill';

  @override
  String get title => 'Title';

  @override
  String get amount => 'Amount';

  @override
  String get categoryMoveGroup => 'Category (Move to Group)';

  @override
  String get recurrence => 'Recurrence';

  @override
  String get none => 'None';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get deleteBillConfirm => 'Delete Bill?';

  @override
  String get deleteBillContent => 'Delete this bill permanently?';

  @override
  String get tutorialStep1Title => 'Bill Display Area';

  @override
  String get tutorialStep1Desc =>
      'This is where you view all upcoming bills.\nAction: Tap anywhere to proceed.';

  @override
  String get tutorialStep2Title => 'Add Bill Button';

  @override
  String get tutorialStep2Desc => 'Tap here to add a new bill.';

  @override
  String get tutorialStep3Title => 'New Record Menu Area';

  @override
  String get tutorialStep3Desc => 'Here are 3 ways to record your bills.';

  @override
  String get tutorialStep4Title => 'Text Input';

  @override
  String get tutorialStep4Desc =>
      'Paste SMS/Email text here to auto-extract bill info.';

  @override
  String get tutorialStep5Title => 'Gallery Upload';

  @override
  String get tutorialStep5Desc =>
      'Upload a photo here to auto-extract bill info.';

  @override
  String get tutorialStep6Title => 'Camera Scan';

  @override
  String get tutorialStep6Desc =>
      'Take a photo here to auto-extract bill info.';

  @override
  String get tutorialStep7Title => 'Start Recording';

  @override
  String get tutorialStep7Desc => 'Choose a way to start recording.';

  @override
  String get tutorialStep8Title => 'Your Record';

  @override
  String get tutorialStep8Desc =>
      'This is your record. We will remind you before it is due.';

  @override
  String get tutorialStep9Title => 'Edit Feature';

  @override
  String get tutorialStep9Desc => 'This is the bill editing page.';

  @override
  String get tutorialFinishTitle => 'Congratulations!';

  @override
  String get tutorialFinishDesc =>
      'Thanks for completing the tutorial. Welcome to DueBox!';
}
