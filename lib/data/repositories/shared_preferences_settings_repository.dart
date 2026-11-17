import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class SharedPreferencesSettingsRepository implements SettingsRepository {
  SharedPreferencesSettingsRepository(this._preferences);

  static const soundKey = 'settings.sound_enabled';
  static const hapticsKey = 'settings.haptics_enabled';
  static const reducedMotionKey = 'settings.reduced_motion';
  static const masterVolumeKey = 'settings.master_volume';
  static const bgmVolumeKey = 'settings.bgm_volume';
  static const sfxVolumeKey = 'settings.sfx_volume';

  final SharedPreferences _preferences;

  @override
  Future<AppSettings> read() async {
    return AppSettings(
      soundEnabled: _preferences.getBool(soundKey) ?? true,
      hapticsEnabled: _preferences.getBool(hapticsKey) ?? true,
      reducedMotion: _preferences.getBool(reducedMotionKey) ?? false,
      masterVolume: _volume(masterVolumeKey),
      bgmVolume: _volume(bgmVolumeKey),
      sfxVolume: _volume(sfxVolumeKey),
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
    final masterSaved = await _preferences.setInt(
      masterVolumeKey,
      AppSettings.snapVolume(settings.masterVolume),
    );
    final bgmSaved = await _preferences.setInt(
      bgmVolumeKey,
      AppSettings.snapVolume(settings.bgmVolume),
    );
    final sfxSaved = await _preferences.setInt(
      sfxVolumeKey,
      AppSettings.snapVolume(settings.sfxVolume),
    );
    if (!soundSaved ||
        !hapticsSaved ||
        !motionSaved ||
        !masterSaved ||
        !bgmSaved ||
        !sfxSaved) {
      throw StateError('Settings could not be saved on this device.');
    }
  }

  int _volume(String key) {
    return AppSettings.snapVolume(
      _preferences.getInt(key) ?? AppSettings.defaultVolume,
    );
  }
}
