import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app/l10n/generated/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/welcome_page.dart';

import 'services/ad_service.dart';
import 'services/analytics_service.dart';
import 'services/logger_service.dart';
import 'services/remote_config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 要最先初始化：Remote Config 會決定 AI 服務用哪把金鑰，
  // Analytics 也要在使用者開始操作之前就準備好。
  await _initFirebase();

  await AdService().init();
  runApp(const BillManagerApp());
}

/// 初始化 Firebase 與其相依服務。
///
/// 用 flutterfire configure 產生的 DefaultFirebaseOptions，而不是讓 SDK 自己去
/// 讀 GoogleService-Info.plist——設定寫在 Dart 端，缺檔或檔案被改壞時會在編譯期
/// 就發現，不會拖到執行期才炸。
///
/// 全程包在 try/catch 裡：裝置沒網路、或 Firebase 服務暫時不可用時都會丟例外。
/// 統計與遠端設定都不是 App 的核心功能，不該讓它們害整個 App 開不起來——
/// 失敗就退回內建設定並繼續跑，AI 辨識不受影響。
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AnalyticsService().init();
    await RemoteConfigService().init();
  } catch (e) {
    LoggerService().log('Firebase 初始化失敗，App 以內建設定繼續執行 → $e');
  }
}

class BillManagerApp extends StatelessWidget {
  const BillManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DueBox',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),       // Generic Chinese (Simplified fallback)
        Locale('zh', 'TW'), // Traditional Chinese
        Locale('zh', 'CN'), // Simplified Chinese
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return supportedLocales.first;

        // Smart Chinese handling
        if (locale.languageCode == 'zh') {
          // 1. Check Script Code (Hans = Simplified, Hant = Traditional)
          if (locale.scriptCode == 'Hant') {
            return const Locale('zh', 'TW');
          }
          if (locale.scriptCode == 'Hans') {
            return const Locale('zh', 'CN');
          }

          // 2. Check Country Code
          switch (locale.countryCode) {
            case 'TW':
            case 'HK':
            case 'MO':
              return const Locale('zh', 'TW');
            case 'CN':
            case 'SG':
              return const Locale('zh', 'CN');
          }

          // 3. Default fallback for 'zh' -> Simplified
           return const Locale('zh', 'CN');
        }

        // Standard matching for other languages
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale.languageCode &&
              supportedLocale.countryCode == locale.countryCode) {
            return supportedLocale;
          }
        }

        // Language matching (ignoring country)
        for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode) {
              return supportedLocale;
            }
        }

        // Fallback to English
        return const Locale('en');
      },
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF3C3C3C),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      home: const WelcomePage(),
    );
  }
}
