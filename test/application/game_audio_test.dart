import 'package:flutter/widgets.dart';
import 'package:flutter_bottle_match/application/audio/game_audio.dart';
import 'package:flutter_bottle_match/application/controllers/settings_controller.dart';
import 'package:flutter_bottle_match/application/providers.dart';
import 'package:flutter_bottle_match/domain/models/app_settings.dart';
import 'package:flutter_bottle_match/domain/repositories/sound_output.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/memory_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'music loops at master times music and pauses in the background',
    () async {
      final output = _RecordingSoundOutput();
      final container = _container(output);
      addTearDown(container.dispose);

      await container.read(settingsControllerProvider.future);
      final audio = container.read(gameAudioProvider.notifier);
      await audio.idle;

      expect(output.starts, hasLength(1));
      expect(output.starts.single.$1, loopAsset);
      expect(output.starts.single.$2, closeTo(0.49, 0.0001));

      await container
          .read(settingsControllerProvider.notifier)
          .setMasterVolume(50);
      await audio.idle;
      expect(output.starts, hasLength(1));
      expect(output.volumes.last, closeTo(0.35, 0.0001));

      await audio.handleLifecycle(AppLifecycleState.paused);
      expect(output.pauses, 1);

      await audio.handleLifecycle(AppLifecycleState.inactive);
      expect(output.pauses, 1);

      await audio.handleLifecycle(AppLifecycleState.resumed);
      expect(output.resumes, 1);

      await audio.playButton();
      expect(output.effects.single.$1, buttonClickAsset);
      expect(output.effects.single.$2, closeTo(0.35, 0.0001));

      await audio.playBottleMove();
      expect(output.effects.last.$1, bottleMoveAsset);
    },
  );

  test(
    'sound off stays silent and a blocked start retries on a button',
    () async {
      final output = _RecordingSoundOutput()..failNextStart = true;
      final repository = MemorySettingsRepository()
        ..value = const AppSettings(soundEnabled: false);
      final container = _container(output, repository: repository);
      addTearDown(container.dispose);

      await container.read(settingsControllerProvider.future);
      final audio = container.read(gameAudioProvider.notifier);
      await audio.idle;
      await audio.playButton();
      expect(output.starts, isEmpty);
      expect(output.effects, isEmpty);

      await container
          .read(settingsControllerProvider.notifier)
          .setSoundEnabled(true);
      await audio.idle;
      expect(output.starts, isEmpty);

      await audio.playButton();
      expect(output.starts, hasLength(1));
      expect(output.effects.single.$1, buttonClickAsset);
    },
  );
}

ProviderContainer _container(
  _RecordingSoundOutput output, {
  MemorySettingsRepository? repository,
}) {
  return ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(
        repository ?? MemorySettingsRepository(),
      ),
      soundOutputProvider.overrideWithValue(output),
    ],
  );
}

class _RecordingSoundOutput implements SoundOutput {
  var failNextStart = false;
  final starts = <(String, double)>[];
  final volumes = <double>[];
  var pauses = 0;
  var resumes = 0;
  final effects = <(String, double)>[];

  @override
  Future<void> dispose() async {}

  @override
  Future<void> pauseLoop() async {
    pauses += 1;
  }

  @override
  Future<void> playEffect(String asset, double volume) async {
    effects.add((asset, volume));
  }

  @override
  Future<void> resumeLoop() async {
    resumes += 1;
  }

  @override
  Future<void> setLoopVolume(double volume) async {
    volumes.add(volume);
  }

  @override
  Future<void> startLoop(String asset, double volume) async {
    if (failNextStart) {
      failNextStart = false;
      throw StateError('blocked');
    }
    starts.add((asset, volume));
  }
}
