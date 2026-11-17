import 'package:flutter_bottle_match/domain/models/match_phase.dart';
import 'package:flutter_bottle_match/domain/models/match_snapshot.dart';
import 'package:flutter_bottle_match/domain/models/player.dart';
import 'package:flutter_bottle_match/domain/models/round_win.dart';
import 'package:flutter_bottle_match/features/gameplay/physical/match_copy.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/match_fixtures.dart';

const sam = Player(id: 'sam', name: 'Sam', avatarIndex: 2);
const nia = Player(id: 'nia', name: 'Nia', avatarIndex: 3);

void main() {
  test('distinct scores stay in highest-first order', () {
    final match = _match(
      roster: const [maya, leo, sam, nia],
      roundOrder: const ['nia', 'sam', 'leo', 'maya'],
      scores: const {'maya': 4, 'leo': 3, 'sam': 2, 'nia': 1},
    );

    expect(topScorerIds(match), ['maya', 'leo', 'sam']);
  });

  test('a tied top three is shown in turn order', () {
    final match = _match(
      roster: const [maya, leo, sam],
      roundOrder: const ['sam', 'leo', 'maya'],
      scores: const {'maya': 1, 'leo': 0, 'sam': 0},
    );

    expect(topScorerIds(match), ['sam', 'leo', 'maya']);
  });

  test('a tie for the last place keeps the earlier turn', () {
    final match = _match(
      roster: const [maya, leo, sam, nia],
      roundOrder: const ['nia', 'sam', 'leo', 'maya'],
      scores: const {'maya': 4, 'leo': 2, 'sam': 2, 'nia': 2},
    );

    expect(topScorerIds(match), ['nia', 'sam', 'maya']);
  });

  test('a reversed win does not count toward the list', () {
    final match =
        _match(
          roster: const [maya, leo],
          roundOrder: const ['maya', 'leo'],
          scores: const {'leo': 1},
        ).copyWith(
          wins: const [
            RoundWin(roundNumber: 1, winnerId: 'maya', reversed: true),
            RoundWin(roundNumber: 2, winnerId: 'leo'),
          ],
        );

    expect(topScorerIds(match), ['leo', 'maya']);
    expect(latestWinnerId(match), 'leo');
  });
}

MatchSnapshot _match({
  required List<Player> roster,
  required List<String> roundOrder,
  required Map<String, int> scores,
}) {
  return sampleMatch(
    phase: MatchPhase.roundResult,
    roster: roster,
    roundOrder: roundOrder,
  ).copyWith(wins: _wins(scores));
}

List<RoundWin> _wins(Map<String, int> scores) {
  final wins = <RoundWin>[];
  var round = 1;
  for (final entry in scores.entries) {
    for (var count = 0; count < entry.value; count++) {
      wins.add(RoundWin(roundNumber: round, winnerId: entry.key));
      round += 1;
    }
  }
  return wins;
}
