import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'application/providers.dart';
import 'data/repositories/hive_match_repository.dart';
import 'data/repositories/shared_preferences_settings_repository.dart';
import 'domain/repositories/match_repository.dart';
import 'domain/repositories/settings_repository.dart';

class AppDependencies {
  const AppDependencies({
    required this.matchRepository,
    required this.settingsRepository,
  });

  final MatchRepository matchRepository;
  final SettingsRepository settingsRepository;

  Widget scope(Widget child) {
    return ProviderScope(
      overrides: [
        matchRepositoryProvider.overrideWithValue(matchRepository),
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
      child: child,
    );
  }

  static Future<AppDependencies> open() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<String>(HiveMatchRepository.boxName);
    final preferences = await SharedPreferences.getInstance();
    return AppDependencies(
      matchRepository: HiveMatchRepository(box),
      settingsRepository: SharedPreferencesSettingsRepository(preferences),
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
