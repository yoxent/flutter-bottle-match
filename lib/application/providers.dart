import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/match_repository.dart';
import '../domain/repositories/settings_repository.dart';

/// Overridden during startup after Hive is open.
final matchRepositoryProvider = Provider<MatchRepository>(
  (ref) => throw StateError('MatchRepository must be overridden at startup.'),
);

/// Overridden during startup after shared preferences are open.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) =>
      throw StateError('SettingsRepository must be overridden at startup.'),
);
