import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google's published *test* ad unit IDs — safe to ship while developing,
/// they always serve a placeholder ad and never earn revenue. Swap these
/// for your own AdMob ad unit IDs (from admob.google.com) before release;
/// see README.md for the exact steps.
const _testBannerUnitIdAndroid = 'ca-app-pub-3940256099942544/6300978111';
const _testBannerUnitIdIOS = 'ca-app-pub-3940256099942544/2934735716';

String get _bannerAdUnitId =>
    Platform.isIOS ? _testBannerUnitIdIOS : _testBannerUnitIdAndroid;

/// Reserves banner-sized space at the bottom of a screen for a future ad.
/// Loads a real (test) banner when the SDK is available so the space is
/// wired up end-to-end; if the ad fails to load (no network, ads disabled,
/// SDK not reachable) it quietly falls back to an empty placeholder of the
/// same size instead of breaking layout.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _loaded = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      setState(() => _failed = true);
      return;
    }
    final ad = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() => _failed = true);
        },
      ),
    );
    _bannerAd = ad;
    ad.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = AdSize.banner.height.toDouble();
    if (_loaded && _bannerAd != null) {
      return SizedBox(
        height: height,
        width: AdSize.banner.width.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return SizedBox(
      height: height,
      child: _failed
          ? const SizedBox.shrink()
          : Center(
              child: Text(
                'Ad space',
                style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12),
              ),
            ),
    );
  }
}
