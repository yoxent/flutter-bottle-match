import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/ads/match_ads.dart';
import '../domain/repositories/ad_config.dart';
import '../domain/repositories/match_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/repositories/sound_output.dart';

/// Overridden during startup after Hive is open.
final matchRepositoryProvider = Provider<MatchRepository>(
  (ref) => throw StateError('MatchRepository must be overridden at startup.'),
);

/// Overridden during startup after shared preferences are open.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) =>
      throw StateError('SettingsRepository must be overridden at startup.'),
);

/// Overridden during startup with the platform playback implementation.
final soundOutputProvider = Provider<SoundOutput>(
  (ref) => throw StateError('SoundOutput must be overridden at startup.'),
);

/// Overridden during startup after Remote Config is opened, or its fallback.
final adConfigProvider = Provider<AdConfig>(
  (ref) => throw StateError('AdConfig must be overridden at startup.'),
);

/// The session ads. Widget tests keep the unavailable implementation.
final matchAdsProvider = Provider<MatchAds>(
  (ref) => const UnavailableMatchAds(),
);
