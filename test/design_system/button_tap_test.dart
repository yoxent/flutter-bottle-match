import 'package:flutter/material.dart';
import 'package:flutter_bottle_match/application/audio/game_audio.dart';
import 'package:flutter_bottle_match/application/controllers/settings_controller.dart';
import 'package:flutter_bottle_match/application/providers.dart';
import 'package:flutter_bottle_match/design_system/components/buttons/game_button.dart';
import 'package:flutter_bottle_match/design_system/tokens/colors.dart';
import 'package:flutter_bottle_match/domain/repositories/sound_output.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/memory_repositories.dart';

void main() {
  testWidgets('the click plays on press and the action runs on release', (
    tester,
  ) async {
    final output = _RecordingSoundOutput();
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          MemorySettingsRepository(),
        ),
        soundOutputProvider.overrideWithValue(output),
      ],
    );
    addTearDown(container.dispose);
    await container.read(settingsControllerProvider.future);
    var presses = 0;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: GameButton(
              label: 'Begin',
              backgroundColor: AppColors.yellow,
              onPressed: () => presses += 1,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Begin')),
    );
    await tester.pump();
    await container.read(gameAudioProvider.notifier).idle;
    expect(output.effects.map((effect) => effect.$1), [buttonClickAsset]);
    expect(presses, 0);

    await gesture.up();
    await tester.pump();
    expect(presses, 1);
    expect(output.effects, hasLength(1));
  });
}

class _RecordingSoundOutput implements SoundOutput {
  final effects = <(String, double)>[];

  @override
  Future<void> dispose() async {}

  @override
  Future<void> pauseLoop() async {}

  @override
  Future<void> playEffect(String asset, double volume) async {
    effects.add((asset, volume));
  }

  @override
  Future<void> resumeLoop() async {}

  @override
  Future<void> setLoopVolume(double volume) async {}

  @override
  Future<void> startLoop(String asset, double volume) async {}
}
