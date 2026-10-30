import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'logger_service.dart';

class AdService {
  static final AdService _instance = AdService._internal();

  factory AdService() {
    return _instance;
  }

  AdService._internal();

  InterstitialAd? _interstitialAd;
  bool _isAdLoading = false;

  final String _adUnitId = 'ca-app-pub-5936164848570883/7406893247';
  final String _testAdUnitId = 'ca-app-pub-3940256099942544/4411468910';

  /// Debug 建置一律用 Google 的測試廣告單元。
  ///
  /// 開發時反覆觸發正式廣告、又在自己的裝置上點到，AdMob 會判定為無效流量，
  /// 輕則扣收益、重則停用帳號。Release 建置（TestFlight／App Store）
  /// kDebugMode 為 false，會自動切回正式單元，不需要手動改回來。
  bool get _isTestMode => kDebugMode;

  String get adUnitId => _isTestMode ? _testAdUnitId : _adUnitId;

  Future<void> init() async {
    await MobileAds.instance.initialize();
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    if (_isAdLoading) return;
    _isAdLoading = true;

    InterstitialAd.load(
      adUnitId: adUnitId, 
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          LoggerService().log('AdService: Interstitial Ad loaded');
          _interstitialAd = ad;
          _isAdLoading = false;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (LoadAdError error) {
          LoggerService().log('AdService: Interstitial Ad failed to load: $error');
          _interstitialAd = null;
          _isAdLoading = false;
          // Retry loading after a delay? Usually handled by next attempt
        },
      ),
    );
  }

  /// Shows the interstitial ad if available. 
  /// Returns a Future that completes when the ad is closed (content dismissed) 
  /// or if the ad failed to show/wasn't ready (completes immediately).
  Future<void> showInterstitialAd() async {
    if (_interstitialAd == null) {
      LoggerService().log('AdService: Ad not ready, skipping');
      _loadInterstitialAd(); // Try to load one for next time
      return;
    }

    // show() 是 void，只能透過 FullScreenContentCallback 得知廣告何時關閉，
    // 所以用 Completer 把 callback 轉成呼叫端可以 await 的 Future。
    final Completer<void> showCompleter = Completer<void>();
    bool transitionHandled = false;

    void handleTermination() {
      if (transitionHandled) return;
      transitionHandled = true;
      if (!showCompleter.isCompleted) {
        showCompleter.complete();
      }
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        LoggerService().log('AdService: Ad showed fullscreen');
        // If ad showed, we expect a dismissal eventually.
        // However, if it's stuck on top of a dismissed picker, we might need a watchdog.
        Future.delayed(const Duration(seconds: 15), () {
          if (!transitionHandled) {
             LoggerService().log('AdService: Ad watchdog triggered - forced completion');
             handleTermination();
          }
        });
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        LoggerService().log('AdService: Ad dismissed');
        ad.dispose();
        _interstitialAd = null;
        handleTermination();
        _loadInterstitialAd(); // Load the next one
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
         LoggerService().log('AdService: Ad failed to show: $error');
         ad.dispose();
         _interstitialAd = null;
         handleTermination(); // Don't block flow
         _loadInterstitialAd();
      },
      onAdImpression: (InterstitialAd ad) {
        LoggerService().log('AdService: Ad impression recorded');
      },
    );

    try {
      _interstitialAd!.show();
    } catch (e) {
      LoggerService().log('AdService: Exception during show(): $e');
      handleTermination();
    }
    
    return showCompleter.future;
  }
}


