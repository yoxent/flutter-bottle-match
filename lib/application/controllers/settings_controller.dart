import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/app_settings.dart';
import '../providers.dart';

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
      SettingsController.new,
    );

class SettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() {
    return ref.watch(settingsRepositoryProvider).read();
  }

  Future<void> setSoundEnabled(bool value) {
    return _save(state.requireValue.copyWith(soundEnabled: value));
  }

  Future<void> setHapticsEnabled(bool value) {
    return _save(state.requireValue.copyWith(hapticsEnabled: value));
  }

  Future<void> setReducedMotion(bool value) {
    return _save(state.requireValue.copyWith(reducedMotion: value));
  }

  Future<void> _save(AppSettings next) async {
    final previous = state.requireValue;
    state = AsyncData(next);
    try {
      await ref.read(settingsRepositoryProvider).save(next);
    } catch (error) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}
