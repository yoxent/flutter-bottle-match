import 'package:flutter_bottle_match/application/launch_recovery.dart';
import 'package:flutter_bottle_match/domain/models/configuration.dart';
import 'package:flutter_bottle_match/domain/models/match_phase.dart';
import 'package:flutter_bottle_match/domain/models/turn_clock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/match_fixtures.dart';
import '../support/memory_repositories.dart';

void main() {
  test('launch pauses an in-progress match and keeps its order', () async {
    final repository = MemoryMatchRepository()
      ..active = sampleMatch(
        timer: TurnClock(
          duration: TurnTimerDuration.seconds30,
          remaining: const Duration(seconds: 30),
          runningSince: sampleUpdatedAt.subtract(const Duration(seconds: 10)),
        ),
      );
    final recovery = LaunchRecovery(repository, now: () => sampleUpdatedAt);

    final first = await recovery.prepare();
    final second = await recovery.prepare();

    expect(first!.phase, MatchPhase.paused);
    expect(first.resumePhase, MatchPhase.activeTurn);
    expect(first.roundOrder, ['maya', 'leo']);
    expect(first.timer.isRunning, isFalse);
    expect(first.timer.remaining, const Duration(seconds: 20));
    expect(second!.resumePhase, MatchPhase.activeTurn);
    expect(repository.saves, 1);
  });

  test('a championship is not rewritten on launch', () async {
    final repository = MemoryMatchRepository()
      ..active = sampleMatch(phase: MatchPhase.championship);
    final recovery = LaunchRecovery(repository, now: () => sampleUpdatedAt);

    final loaded = await recovery.prepare();

    expect(loaded!.phase, MatchPhase.championship);
    expect(repository.saves, 0);
  });
}
