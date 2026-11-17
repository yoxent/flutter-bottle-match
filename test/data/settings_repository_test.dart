import 'package:flutter_bottle_match/data/repositories/shared_preferences_settings_repository.dart';
import 'package:flutter_bottle_match/domain/models/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sound, haptics, and reduced motion persist independently', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = SharedPreferencesSettingsRepository(preferences);

    expect((await repository.read()).soundEnabled, isTrue);
    await repository.save(
      const AppSettings(
        soundEnabled: false,
        hapticsEnabled: false,
        reducedMotion: true,
        masterVolume: 75,
        bgmVolume: 50,
        sfxVolume: 0,
      ),
    );

    final reloaded = SharedPreferencesSettingsRepository(
      await SharedPreferences.getInstance(),
    );
    final stored = await reloaded.read();
    expect(stored.soundEnabled, isFalse);
    expect(stored.hapticsEnabled, isFalse);
    expect(stored.reducedMotion, isTrue);
    expect(stored.masterVolume, 75);
    expect(stored.bgmVolume, 50);
    expect(stored.sfxVolume, 0);
  });

  test('missing volumes start at 70 and off-step values snap', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesSettingsRepository.masterVolumeKey: 72,
    });
    final preferences = await SharedPreferences.getInstance();
    final repository = SharedPreferencesSettingsRepository(preferences);

    final stored = await repository.read();
    expect(stored.masterVolume, 70);
    expect(stored.bgmVolume, AppSettings.defaultVolume);
    expect(stored.sfxVolume, AppSettings.defaultVolume);
    expect(AppSettings.snapVolume(73), 75);
    expect(AppSettings.snapVolume(100), 100);
    expect(AppSettings.snapVolume(0), 0);
  });
}
