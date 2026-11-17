import 'dart:math';

import 'package:flutter_bottle_match/application/controllers/match_session_controller.dart';
import 'package:flutter_bottle_match/application/providers.dart';
import 'package:flutter_bottle_match/domain/models/configuration.dart';
import 'package:flutter_bottle_match/domain/models/match_phase.dart';
import 'package:flutter_bottle_match/domain/models/player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/memory_repositories.dart';

void main() {
  test(
    'a second unfinished match waits, then replaces after confirmation',
    () async {
      final repository = MemoryMatchRepository();
      final start = DateTime.utc(2026, 11, 14, 8);
      var ticks = 0;
      final container = ProviderContainer(
        overrides: [
          matchRepositoryProvider.overrideWithValue(repository),
          matchClockProvider.overrideWith(
            (ref) =>
                () => start.add(Duration(seconds: ticks++)),
          ),
          matchRandomProvider.overrideWithValue(Random(1)),
        ],
      );
      addTearDown(container.dispose);

      const roster = [
        Player(id: 'player-1', name: 'Player 1', avatarIndex: 0),
        Player(id: 'player-2', name: 'Player 2', avatarIndex: 1),
      ];
      const settings = MatchSettings(physicalEquipmentConfirmed: true);
      final notifier = container.read(matchSessionProvider.notifier);

      final first = await notifier.startMatch(
        roster: roster,
        settings: settings,
      );
      expect(first, isA<StartMatchReady>());
      final savedId = repository.active!.matchId;
      expect(await notifier.beginRound(), isNull);
      expect(repository.active!.phase, MatchPhase.activeTurn);

      final blocked = await notifier.startMatch(
        roster: roster,
        settings: settings,
      );
      expect(blocked, isA<StartMatchNeedsConfirmation>());
      expect(repository.active!.matchId, savedId);
      expect(repository.active!.phase, MatchPhase.activeTurn);

      final replaced = await notifier.startMatch(
        roster: roster,
        settings: settings,
        replaceConfirmed: true,
      );
      expect(replaced, isA<StartMatchReady>());
      expect(repository.active!.matchId, isNot(savedId));
      expect(repository.active!.phase, MatchPhase.roundIntroduction);
    },
  );
}
