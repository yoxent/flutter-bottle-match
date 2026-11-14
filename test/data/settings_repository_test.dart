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
      ),
    );

    final reloaded = SharedPreferencesSettingsRepository(
      await SharedPreferences.getInstance(),
    );
    final stored = await reloaded.read();
    expect(stored.soundEnabled, isFalse);
    expect(stored.hapticsEnabled, isFalse);
    expect(stored.reducedMotion, isTrue);
  });
}
