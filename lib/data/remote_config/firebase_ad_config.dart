import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../../domain/ads/test_ads.dart';
import '../../domain/repositories/ad_config.dart';
import '../../firebase_options.dart';

const testAdsRemoteKey = 'test_ads';

/// Reads [testAdsRemoteKey] when [AdConfig.testAds] is called.
class FirebaseAdConfig implements AdConfig {
  const FirebaseAdConfig({
    required this.debugBuild,
    required this.readRemoteTestAds,
  });

  final bool debugBuild;
  final bool Function() readRemoteTestAds;

  @override
  bool get testAds => resolveTestAds(
    debugBuild: debugBuild,
    remoteTestAds: readRemoteTestAds(),
  );
}

/// Starts Firebase and returns a config that requests test ads until a fetch
/// says otherwise.
///
/// A failed start still returns an [AdConfig]. The match can open either way.
Future<AdConfig> openFirebaseAdConfig({required bool debugBuild}) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final remote = FirebaseRemoteConfig.instance;
    await remote.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: debugBuild
            ? Duration.zero
            : const Duration(hours: 12),
      ),
    );
    await remote.setDefaults(const {testAdsRemoteKey: true});
    await remote.activate();
    try {
      await remote.fetchAndActivate();
    } catch (_) {}
    return FirebaseAdConfig(
      debugBuild: debugBuild,
      readRemoteTestAds: () => remote.getBool(testAdsRemoteKey),
    );
  } catch (_) {
    return FirebaseAdConfig(
      debugBuild: debugBuild,
      readRemoteTestAds: () => true,
    );
  }
}
