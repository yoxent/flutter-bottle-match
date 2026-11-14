import '../models/app_settings.dart';

/// Persistence contract for sound, haptics, and reduced motion.
abstract interface class SettingsRepository {
  Future<AppSettings> read();

  Future<void> save(AppSettings settings);
}
