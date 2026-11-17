import 'dart:async';

import '../../domain/ads/match_ads.dart';
import 'level_play_match_ads.dart';

Future<MatchAds> openMatchAds({required bool testAds}) async {
  final ads = LevelPlayMatchAds();
  unawaited(ads.start(testAds: testAds));
  return ads;
}
