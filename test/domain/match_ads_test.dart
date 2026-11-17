import 'package:flutter_bottle_match/domain/ads/match_ads.dart';
import 'package:flutter_bottle_match/domain/models/match_phase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an interstitial is due only when play enters the championship', () {
    expect(
      isMatchJustCompleted(MatchPhase.roundResult, MatchPhase.championship),
      isTrue,
    );
    expect(
      isMatchJustCompleted(MatchPhase.championship, MatchPhase.championship),
      isFalse,
    );
    expect(isMatchJustCompleted(null, MatchPhase.championship), isFalse);
    expect(
      isMatchJustCompleted(MatchPhase.activeTurn, MatchPhase.roundResult),
      isFalse,
    );
  });

  test('unavailable ads do not report a banner or block the result', () async {
    const ads = UnavailableMatchAds();
    var notified = false;
    ads.addListener(() => notified = true);

    expect(ads.isBannerReady, isFalse);
    await ads.showMatchCompletedAd();
    ads.removeListener(() => notified = true);

    expect(notified, isFalse);
  });
}
