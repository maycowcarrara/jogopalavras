import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:jogopalavras/src/core/ads/ad_config.dart';

class AdService {
  AdService._();

  static final AdService instance = AdService._();

  InterstitialAd? _interstitialAd;
  DateTime? _lastInterstitialAt;
  bool _isLoading = false;
  int _naturalBreaks = 0;

  Future<void> initialize() async {
    if (kIsWeb || !AdConfig.canRequestAds) {
      return;
    }

    await MobileAds.instance.initialize();
    _loadInterstitial();
  }

  Future<void> registerNaturalBreak() async {
    if (kIsWeb || !AdConfig.canRequestAds) {
      return;
    }

    _naturalBreaks += 1;

    if (_naturalBreaks % 3 != 0) {
      _loadInterstitial();
      return;
    }

    if (_interstitialAd == null) {
      _loadInterstitial();
      return;
    }

    final now = DateTime.now();
    if (_lastInterstitialAt != null &&
        now.difference(_lastInterstitialAt!) < const Duration(minutes: 3)) {
      _loadInterstitial();
      return;
    }

    final ad = _interstitialAd;
    _interstitialAd = null;
    _lastInterstitialAt = now;
    await ad?.show();
  }

  void _loadInterstitial() {
    if (_isLoading || _interstitialAd != null || !AdConfig.canRequestAds) {
      return;
    }

    _isLoading = true;
    InterstitialAd.load(
      adUnitId: AdConfig.resolvedInterstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }
}
