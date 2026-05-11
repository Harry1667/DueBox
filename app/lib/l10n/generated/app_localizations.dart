import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'DueBox'**
  String get appTitle;

  /// No description provided for @appSlogan.
  ///
  /// In en, this message translates to:
  /// **'Manage your bills,\nstress-free.'**
  String get appSlogan;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'My Bills'**
  String get dashboardTitle;

  /// No description provided for @totalPending.
  ///
  /// In en, this message translates to:
  /// **'Total Pending'**
  String get totalPending;

  /// No description provided for @addFirstBill.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first bill'**
  String get addFirstBill;

  /// No description provided for @notificationScheduled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled and scheduled'**
  String get notificationScheduled;

  /// No description provided for @addSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success: Added!'**
  String get addSuccess;

  /// No description provided for @addFail.
  ///
  /// In en, this message translates to:
  /// **'Failed: {message}'**
  String addFail(Object message);

  /// No description provided for @deleteGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete group \"{groupId}\"?'**
  String deleteGroupTitle(Object groupId);

  /// No description provided for @deleteGroupContent.
  ///
  /// In en, this message translates to:
  /// **'This will delete all bills in this group.'**
  String get deleteGroupContent;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @editGroupName.
  ///
  /// In en, this message translates to:
  /// **'Edit Group Name'**
  String get editGroupName;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @pickColor.
  ///
  /// In en, this message translates to:
  /// **'Pick Color'**
  String get pickColor;

  /// No description provided for @changeColor.
  ///
  /// In en, this message translates to:
  /// **'Change Color'**
  String get changeColor;

  /// No description provided for @pinUnpin.
  ///
  /// In en, this message translates to:
  /// **'Pin/Unpin'**
  String get pinUnpin;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move Up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move Down'**
  String get moveDown;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete Group'**
  String get deleteGroup;

  /// No description provided for @editTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Title'**
  String get editTitle;

  /// No description provided for @enterNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter new title'**
  String get enterNewTitle;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'{count} Items'**
  String items(Object count);

  /// No description provided for @billInputTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Bill Info'**
  String get billInputTitle;

  /// No description provided for @billInputHint.
  ///
  /// In en, this message translates to:
  /// **'Paste SMS or Email content here...'**
  String get billInputHint;

  /// No description provided for @startAiAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Start AI Analysis'**
  String get startAiAnalysis;

  /// No description provided for @textInput.
  ///
  /// In en, this message translates to:
  /// **'Text Input'**
  String get textInput;

  /// No description provided for @galleryUpload.
  ///
  /// In en, this message translates to:
  /// **'Gallery Upload'**
  String get galleryUpload;

  /// No description provided for @cameraScan.
  ///
  /// In en, this message translates to:
  /// **'Camera Scan'**
  String get cameraScan;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalSettings;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home Title'**
  String get homeTitle;

  /// No description provided for @notificationsReminders.
  ///
  /// In en, this message translates to:
  /// **'Notifications & Reminders'**
  String get notificationsReminders;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminderTime;

  /// No description provided for @reminderTimeDesc.
  ///
  /// In en, this message translates to:
  /// **'Set daily notification time'**
  String get reminderTimeDesc;

  /// No description provided for @advanceReminder.
  ///
  /// In en, this message translates to:
  /// **'Advance Reminder'**
  String get advanceReminder;

  /// No description provided for @advanceReminderDesc.
  ///
  /// In en, this message translates to:
  /// **'Extra reminder days besides due day and day before'**
  String get advanceReminderDesc;

  /// No description provided for @daysBefore.
  ///
  /// In en, this message translates to:
  /// **'Days Before'**
  String get daysBefore;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @statusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statusPaid;

  /// No description provided for @statusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue by {days} days'**
  String statusOverdue(Object days);

  /// No description provided for @statusRemaining.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String statusRemaining(Object days);

  /// No description provided for @generalBill.
  ///
  /// In en, this message translates to:
  /// **'General Bill'**
  String get generalBill;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @editBill.
  ///
  /// In en, this message translates to:
  /// **'Edit Bill'**
  String get editBill;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @categoryMoveGroup.
  ///
  /// In en, this message translates to:
  /// **'Category (Move to Group)'**
  String get categoryMoveGroup;

  /// No description provided for @recurrence.
  ///
  /// In en, this message translates to:
  /// **'Recurrence'**
  String get recurrence;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @deleteBillConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete Bill?'**
  String get deleteBillConfirm;

  /// No description provided for @deleteBillContent.
  ///
  /// In en, this message translates to:
  /// **'Delete this bill permanently?'**
  String get deleteBillContent;

  /// No description provided for @tutorialStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Bill Display Area'**
  String get tutorialStep1Title;

  /// No description provided for @tutorialStep1Desc.
  ///
  /// In en, this message translates to:
  /// **'This is where you view all upcoming bills.\nAction: Tap anywhere to proceed.'**
  String get tutorialStep1Desc;

  /// No description provided for @tutorialStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Add Bill Button'**
  String get tutorialStep2Title;

  /// No description provided for @tutorialStep2Desc.
  ///
  /// In en, this message translates to:
  /// **'Tap here to add a new bill.'**
  String get tutorialStep2Desc;

  /// No description provided for @tutorialStep3Title.
  ///
  /// In en, this message translates to:
  /// **'New Record Menu Area'**
  String get tutorialStep3Title;

  /// No description provided for @tutorialStep3Desc.
  ///
  /// In en, this message translates to:
  /// **'Here are 3 ways to record your bills.'**
  String get tutorialStep3Desc;

  /// No description provided for @tutorialStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Text Input'**
  String get tutorialStep4Title;

  /// No description provided for @tutorialStep4Desc.
  ///
  /// In en, this message translates to:
  /// **'Paste SMS/Email text here to auto-extract bill info.'**
  String get tutorialStep4Desc;

  /// No description provided for @tutorialStep5Title.
  ///
  /// In en, this message translates to:
  /// **'Gallery Upload'**
  String get tutorialStep5Title;

  /// No description provided for @tutorialStep5Desc.
  ///
  /// In en, this message translates to:
  /// **'Upload a photo here to auto-extract bill info.'**
  String get tutorialStep5Desc;

  /// No description provided for @tutorialStep6Title.
  ///
  /// In en, this message translates to:
  /// **'Camera Scan'**
  String get tutorialStep6Title;

  /// No description provided for @tutorialStep6Desc.
  ///
  /// In en, this message translates to:
  /// **'Take a photo here to auto-extract bill info.'**
  String get tutorialStep6Desc;

  /// No description provided for @tutorialStep7Title.
  ///
  /// In en, this message translates to:
  /// **'Start Recording'**
  String get tutorialStep7Title;

  /// No description provided for @tutorialStep7Desc.
  ///
  /// In en, this message translates to:
  /// **'Choose a way to start recording.'**
  String get tutorialStep7Desc;

  /// No description provided for @tutorialStep8Title.
  ///
  /// In en, this message translates to:
  /// **'Your Record'**
  String get tutorialStep8Title;

  /// No description provided for @tutorialStep8Desc.
  ///
  /// In en, this message translates to:
  /// **'This is your record. We will remind you before it is due.'**
  String get tutorialStep8Desc;

  /// No description provided for @tutorialStep9Title.
  ///
  /// In en, this message translates to:
  /// **'Edit Feature'**
  String get tutorialStep9Title;

  /// No description provided for @tutorialStep9Desc.
  ///
  /// In en, this message translates to:
  /// **'This is the bill editing page.'**
  String get tutorialStep9Desc;

  /// No description provided for @tutorialFinishTitle.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get tutorialFinishTitle;

  /// No description provided for @tutorialFinishDesc.
  ///
  /// In en, this message translates to:
  /// **'Thanks for completing the tutorial. Welcome to DueBox!'**
  String get tutorialFinishDesc;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'CN':
            return AppLocalizationsZhCn();
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
