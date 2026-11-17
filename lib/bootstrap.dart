import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'application/audio/game_audio.dart';
import 'application/providers.dart';
import 'data/ads/open_match_ads.dart';
import 'data/audio/audioplayers_sound_output.dart';
import 'data/remote_config/firebase_ad_config.dart';
import 'data/repositories/hive_match_repository.dart';
import 'data/repositories/shared_preferences_settings_repository.dart';
import 'domain/ads/match_ads.dart';
import 'domain/repositories/ad_config.dart';
import 'domain/repositories/match_repository.dart';
import 'domain/repositories/settings_repository.dart';
import 'domain/repositories/sound_output.dart';

class AppDependencies {
  const AppDependencies({
    required this.matchRepository,
    required this.settingsRepository,
    required this.soundOutput,
    required this.adConfig,
    required this.matchAds,
  });

  final MatchRepository matchRepository;
  final SettingsRepository settingsRepository;
  final SoundOutput soundOutput;
  final AdConfig adConfig;
  final MatchAds matchAds;

  Widget scope(Widget child) {
    return ProviderScope(
      overrides: [
        matchRepositoryProvider.overrideWithValue(matchRepository),
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
        soundOutputProvider.overrideWithValue(soundOutput),
        adConfigProvider.overrideWithValue(adConfig),
        matchAdsProvider.overrideWithValue(matchAds),
      ],
      child: child,
    );
  }

  static Future<AppDependencies> open() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<String>(HiveMatchRepository.boxName);
    final preferences = await SharedPreferences.getInstance();
    final adConfig = await openFirebaseAdConfig(debugBuild: kDebugMode);
    final matchAds = await openMatchAds(testAds: adConfig.testAds);
    return AppDependencies(
      matchRepository: HiveMatchRepository(box),
      settingsRepository: SharedPreferencesSettingsRepository(preferences),
      soundOutput: await AudioplayersSoundOutput.open(
        effects: const [buttonClickAsset, bottleMoveAsset],
      ),
      adConfig: adConfig,
      matchAds: matchAds,
    );
  }
}

/// Phones stay portrait. Tablets and browsers keep every orientation so the
/// centered layout can use the extra width.
Future<void> preferPortraitOnPhones() async {
  if (kIsWeb) {
    return;
  }
  final views = PlatformDispatcher.instance.views;
  if (views.isEmpty) {
    return;
  }
  final view = views.first;
  final shortestSide = view.physicalSize.shortestSide / view.devicePixelRatio;
  if (shortestSide < 600) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
}
