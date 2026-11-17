import 'package:flutter/material.dart';
import 'package:flutter_bottle_match/application/audio/game_audio.dart';
import 'package:flutter_bottle_match/application/controllers/settings_controller.dart';
import 'package:flutter_bottle_match/application/providers.dart';
import 'package:flutter_bottle_match/domain/repositories/sound_output.dart';
import 'package:flutter_bottle_match/features/gameplay/board/bottle_rack.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/memory_repositories.dart';

void main() {
  testWidgets('bottle move follows the drag release and the second tap', (
    tester,
  ) async {
    final output = _RecordingSoundOutput();
    final swaps = <(int, int)>[];
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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 420,
              child: BottleRack(
                arrangement: const [0, 1],
                opening: const [0, 1],
                onSwap: (from, to) => swaps.add((from, to)),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('bottle-position-0')));
    await tester.pump();
    await container.read(gameAudioProvider.notifier).idle;
    expect(output.effects, isEmpty);
    expect(swaps, isEmpty);

    final second = tester.getCenter(find.byKey(const Key('bottle-position-1')));
    final hold = await tester.startGesture(second);
    await tester.pump();
    await container.read(gameAudioProvider.notifier).idle;
    expect(swaps, isEmpty);
    expect(output.effects.map((effect) => effect.$1), [bottleMoveAsset]);

    await hold.up();
    await tester.pump();
    await container.read(gameAudioProvider.notifier).idle;
    expect(swaps, [(0, 1)]);
    expect(output.effects, hasLength(1));

    output.effects.clear();
    swaps.clear();
    await tester.tap(find.byKey(const Key('bottle-position-0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('move-to-1')));
    await tester.pump();
    await container.read(gameAudioProvider.notifier).idle;
    expect(swaps, [(0, 1)]);
    expect(output.effects, isEmpty);

    final from = tester.getCenter(find.byKey(const Key('bottle-position-0')));
    final missed = await tester.startGesture(from);
    await tester.pump();
    await missed.moveBy(const Offset(0, -120));
    await tester.pump();
    await missed.up();
    await tester.pump();
    await container.read(gameAudioProvider.notifier).idle;
    expect(swaps, [(0, 1)]);
    expect(output.effects.map((effect) => effect.$1), [bottleMoveAsset]);

    output.effects.clear();
    final onto = tester.getCenter(find.byKey(const Key('bottle-position-1')));
    final dropped = await tester.startGesture(from);
    await tester.pump();
    await dropped.moveTo(onto);
    await tester.pump();
    await dropped.up();
    await tester.pump();
    await container.read(gameAudioProvider.notifier).idle;
    expect(swaps, [(0, 1), (0, 1)]);
    expect(output.effects.map((effect) => effect.$1), [bottleMoveAsset]);
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
