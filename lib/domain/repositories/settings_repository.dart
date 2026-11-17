import '../models/app_settings.dart';

/// Persistence contract for sound, haptics, reduced motion, and volumes.
abstract interface class SettingsRepository {
  Future<AppSettings> read();

  Future<void> save(AppSettings settings);
}
