import 'package:flutter/foundation.dart';

class AdConfig {
  const AdConfig._();

  static const bool adsEnabled = bool.fromEnvironment(
    'ADS_ENABLED',
    defaultValue: false,
  );

  static const String sampleAndroidAppId =
      'ca-app-pub-3940256099942544~3347511713';
  static const String sampleAndroidBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String sampleAndroidInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';

  static const String androidBannerId = String.fromEnvironment(
    'ADMOB_ANDROID_BANNER_ID',
    defaultValue: '',
  );

  static const String androidInterstitialId = String.fromEnvironment(
    'ADMOB_ANDROID_INTERSTITIAL_ID',
    defaultValue: '',
  );

  static bool get useTestAds => kDebugMode;

  static String get resolvedInterstitialId {
    if (useTestAds) {
      return sampleAndroidInterstitialId;
    }

    return androidInterstitialId;
  }

  static String get resolvedBannerId {
    if (useTestAds) {
      return sampleAndroidBannerId;
    }

    return androidBannerId;
  }

  static bool get hasBannerPlacement =>
      adsEnabled && resolvedBannerId.trim().isNotEmpty;

  static bool get hasInterstitialPlacement =>
      adsEnabled && resolvedInterstitialId.trim().isNotEmpty;

  static bool get canRequestAds =>
      hasBannerPlacement || hasInterstitialPlacement;
}
