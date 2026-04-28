import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:jogopalavras/src/core/ads/ad_config.dart';
import 'package:jogopalavras/src/theme/app_theme.dart';

class AdBannerSlot extends StatefulWidget {
  const AdBannerSlot({
    super.key,
    this.compact = false,
    this.margin = EdgeInsets.zero,
    this.safeAreaMinimum,
  });

  final bool compact;
  final EdgeInsetsGeometry margin;
  final EdgeInsets? safeAreaMinimum;

  @override
  State<AdBannerSlot> createState() => _AdBannerSlotState();
}

class _AdBannerSlotState extends State<AdBannerSlot> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadAd() {
    if (kIsWeb || !AdConfig.hasBannerPlacement) {
      return;
    }

    final ad = BannerAd(
      adUnitId: AdConfig.resolvedBannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }

          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) {
            return;
          }

          setState(() {
            _bannerAd = null;
            _isLoaded = false;
          });
        },
      ),
    );

    ad.load();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdConfig.hasBannerPlacement) {
      return const SizedBox.shrink();
    }

    final height = widget.compact ? 58.0 : 66.0;

    final slot = Padding(
      padding: widget.margin,
      child: Semantics(
        label: 'Espaço de anúncio',
        child: Container(
          height: height,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.card.withValues(alpha: 0.9),
            border: Border.all(color: AppTheme.rule.withValues(alpha: 0.7)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: _isLoaded && _bannerAd != null
              ? SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                )
              : const _AdLoadingLabel(),
        ),
      ),
    );

    final minimum = widget.safeAreaMinimum;
    if (minimum == null) {
      return slot;
    }

    return SafeArea(minimum: minimum, child: slot);
  }
}

class _AdLoadingLabel extends StatelessWidget {
  const _AdLoadingLabel();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Publicidade discreta',
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: AppTheme.ink.withValues(alpha: 0.56),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
