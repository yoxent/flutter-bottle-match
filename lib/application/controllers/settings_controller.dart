import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/app_settings.dart';
import '../providers.dart';

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
      SettingsController.new,
    );

class SettingsController extends AsyncNotifier<AppSettings> {
  Future<void> _pending = Future<void>.value();

  @override
  Future<AppSettings> build() {
    return ref.watch(settingsRepositoryProvider).read();
  }

  Future<void> setSoundEnabled(bool value) {
    return _save((current) => current.copyWith(soundEnabled: value));
  }

  Future<void> setHapticsEnabled(bool value) {
    return _save((current) => current.copyWith(hapticsEnabled: value));
  }

  Future<void> setReducedMotion(bool value) {
    return _save((current) => current.copyWith(reducedMotion: value));
  }

  Future<void> setMasterVolume(int percent) {
    return _save(
      (current) =>
          current.copyWith(masterVolume: AppSettings.snapVolume(percent)),
    );
  }

  Future<void> setBgmVolume(int percent) {
    return _save(
      (current) => current.copyWith(bgmVolume: AppSettings.snapVolume(percent)),
    );
  }

  Future<void> setSfxVolume(int percent) {
    return _save(
      (current) => current.copyWith(sfxVolume: AppSettings.snapVolume(percent)),
    );
  }

  Future<void> _save(AppSettings Function(AppSettings current) update) {
    final result = _pending.then((_) => _write(update));
    _pending = result.catchError((Object _) {});
    return result;
  }

  Future<void> _write(AppSettings Function(AppSettings current) update) async {
    final previous = state.requireValue;
    final next = update(previous);
    if (next == previous) {
      return;
    }
    state = AsyncData(next);
    try {
      await ref.read(settingsRepositoryProvider).save(next);
    } catch (error) {
      if (state.requireValue == next) {
        state = AsyncData(previous);
      }
      rethrow;
    }
  }
}
