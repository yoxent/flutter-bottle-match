import 'package:flutter_bottle_match/data/remote_config/firebase_ad_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the getter reads the remote flag again on each call', () {
    var remote = false;
    final config = FirebaseAdConfig(
      debugBuild: false,
      readRemoteTestAds: () => remote,
    );

    expect(config.testAds, isFalse);
    remote = true;
    expect(config.testAds, isTrue);
  });
}
