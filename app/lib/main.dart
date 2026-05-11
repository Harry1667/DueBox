import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/bill_dashboard_page.dart';
import 'pages/welcome_page.dart';

import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService().init();
  runApp(const BillManagerApp());
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
