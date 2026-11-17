import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';
import '../design_system/components/ad_banner_placeholder.dart';
import '../domain/ads/match_ads.dart';
import 'level_play_banner_view_import.dart';

/// The shell banner. The LevelPlay view replaces the label after init.
class AdBanner extends ConsumerStatefulWidget {
  const AdBanner({super.key});

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner> {
  MatchAds? _ads;

  @override
  void dispose() {
    _ads?.removeListener(_onAdsChanged);
    super.dispose();
  }

  void _onAdsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _bind(MatchAds ads) {
    if (identical(_ads, ads)) {
      return;
    }
    _ads?.removeListener(_onAdsChanged);
    _ads = ads;
    ads.addListener(_onAdsChanged);
  }

  @override
  Widget build(BuildContext context) {
    final ads = ref.watch(matchAdsProvider);
    _bind(ads);
    return AdBannerPlaceholder(
      child: ads.isBannerReady ? buildLevelPlayBanner() : null,
    );
  }
}
