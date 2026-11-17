import 'package:flutter/widgets.dart';
import 'package:unity_levelplay_mediation/unity_levelplay_mediation.dart';

import '../core/constants/levelplay_ads.dart';

Widget buildLevelPlayBanner() => const LevelPlayBannerView();

class LevelPlayBannerView extends StatefulWidget {
  const LevelPlayBannerView({super.key});

  @override
  State<LevelPlayBannerView> createState() => _LevelPlayBannerViewState();
}

class _LevelPlayBannerViewState extends State<LevelPlayBannerView>
    implements LevelPlayBannerAdViewListener {
  final _key = GlobalKey<LevelPlayBannerAdViewState>();

  @override
  Widget build(BuildContext context) {
    final size = LevelPlayAdSize.BANNER;
    return Center(
      child: SizedBox(
        width: size.width.toDouble(),
        height: size.height.toDouble(),
        child: LevelPlayBannerAdView(
          key: _key,
          adUnitId: LevelPlayAds.bannerAdUnitId,
          adSize: size,
          listener: this,
          onPlatformViewCreated: () {
            _key.currentState?.loadAd();
          },
        ),
      ),
    );
  }

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {}

  @override
  void onAdLoadFailed(LevelPlayAdError error) {}

  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) {}

  @override
  void onAdDisplayFailed(LevelPlayAdInfo adInfo, LevelPlayAdError error) {}

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {}

  @override
  void onAdExpanded(LevelPlayAdInfo adInfo) {}

  @override
  void onAdCollapsed(LevelPlayAdInfo adInfo) {}

  @override
  void onAdLeftApplication(LevelPlayAdInfo adInfo) {}
}
