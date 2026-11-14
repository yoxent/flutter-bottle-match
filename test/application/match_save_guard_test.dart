import 'package:flutter_bottle_match/application/match_save_guard.dart';
import 'package:flutter_bottle_match/domain/models/match_phase.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/match_fixtures.dart';
import '../support/memory_repositories.dart';

void main() {
  test('an unfinished match is not replaced until confirmed', () async {
    final repository = MemoryMatchRepository()
      ..active = sampleMatch(phase: MatchPhase.activeTurn);
    final guard = MatchSaveGuard(repository);
    final incoming = sampleMatch(
      phase: MatchPhase.setup,
    ).copyWith(roundNumber: 0, roundOrder: const []);

    final blocked = await guard.saveNew(incoming, replaceConfirmed: false);
    expect(blocked, isA<NewMatchNeedsConfirmation>());
    expect(repository.active!.phase, MatchPhase.activeTurn);

    final saved = await guard.saveNew(incoming, replaceConfirmed: true);
    expect(saved, isA<NewMatchSaved>());
    expect(repository.active!.phase, MatchPhase.setup);
  });

  test(
    'a finished championship can be replaced without confirmation',
    () async {
      final repository = MemoryMatchRepository()
        ..active = sampleMatch(phase: MatchPhase.championship);
      final guard = MatchSaveGuard(repository);
      final incoming = sampleMatch(phase: MatchPhase.setup);

      final saved = await guard.saveNew(incoming, replaceConfirmed: false);

      expect(saved, isA<NewMatchSaved>());
      expect(repository.active!.phase, MatchPhase.setup);
    },
  );
}
