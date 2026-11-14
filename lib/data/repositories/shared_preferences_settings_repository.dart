import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class SharedPreferencesSettingsRepository implements SettingsRepository {
  SharedPreferencesSettingsRepository(this._preferences);

  static const soundKey = 'settings.sound_enabled';
  static const hapticsKey = 'settings.haptics_enabled';
  static const reducedMotionKey = 'settings.reduced_motion';

  final SharedPreferences _preferences;

  @override
  Future<AppSettings> read() async {
    return AppSettings(
      soundEnabled: _preferences.getBool(soundKey) ?? true,
      hapticsEnabled: _preferences.getBool(hapticsKey) ?? true,
      reducedMotion: _preferences.getBool(reducedMotionKey) ?? false,
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    final soundSaved = await _preferences.setBool(
      soundKey,
      settings.soundEnabled,
    );
    final hapticsSaved = await _preferences.setBool(
      hapticsKey,
      settings.hapticsEnabled,
    );
    final motionSaved = await _preferences.setBool(
      reducedMotionKey,
      settings.reducedMotion,
    );
    if (!soundSaved || !hapticsSaved || !motionSaved) {
      throw StateError('Settings could not be saved on this device.');
    }
  }
}
