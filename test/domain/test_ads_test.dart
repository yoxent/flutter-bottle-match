import 'package:flutter_bottle_match/domain/ads/test_ads.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a debug build always requests test ads', () {
    expect(resolveTestAds(debugBuild: true, remoteTestAds: false), isTrue);
    expect(resolveTestAds(debugBuild: true, remoteTestAds: true), isTrue);
  });

  test('a release build follows the remote flag and defaults to live ads', () {
    expect(resolveTestAds(debugBuild: false, remoteTestAds: false), isFalse);
    expect(resolveTestAds(debugBuild: false, remoteTestAds: true), isTrue);
  });
}
