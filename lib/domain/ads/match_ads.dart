import '../models/match_phase.dart';

/// Loads the banner and plays one interstitial when a match is completed.
abstract interface class MatchAds {
  bool get isBannerReady;

  void addListener(void Function() listener);

  void removeListener(void Function() listener);

  Future<void> showMatchCompletedAd();
}

/// Used where LevelPlay cannot run, including the browser and widget tests.
class UnavailableMatchAds implements MatchAds {
  const UnavailableMatchAds();

  @override
  bool get isBannerReady => false;

  @override
  void addListener(void Function() listener) {}

  @override
  void removeListener(void Function() listener) {}

  @override
  Future<void> showMatchCompletedAd() async {}
}

/// True only when play enters the championship, not when a saved one is opened.
bool isMatchJustCompleted(MatchPhase? previous, MatchPhase? next) {
  return next == MatchPhase.championship &&
      previous != null &&
      previous != MatchPhase.championship;
}
