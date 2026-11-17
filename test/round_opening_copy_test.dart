import 'package:flutter_bottle_match/domain/models/configuration.dart';
import 'package:flutter_bottle_match/features/gameplay/physical/match_copy.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/match_fixtures.dart';

void main() {
  test('the opening label pads the round number', () {
    expect(roundOpeningLabel(1), 'ROUND 01');
    expect(roundOpeningLabel(12), 'ROUND 12');
  });

  test('a selected player goal shows that player and the live score', () {
    final match = sampleMatch().copyWith(
      settings: const MatchSettings(
        winRule: WinRule.selectedPlayerReachesTarget,
        selectedPlayerId: 'leo',
        targetRoundWins: 3,
        physicalEquipmentConfirmed: true,
      ),
    );

    expect(roundOpeningScoreLine(match), 'LEO GOAL • 0 / 3 WINS');
  });

  test('first to target names the target and not one player', () {
    expect(roundOpeningScoreLine(sampleMatch()), 'FIRST TO 3 WINS');
  });

  test('only a random order is described as shuffled', () {
    expect(roundOpeningOrderTitle(TurnOrder.random), 'Player Order');
    expect(
      roundOpeningOrderNote(TurnOrder.random),
      'A fresh order is randomized every round.',
    );
    expect(roundOpeningOrderTitle(TurnOrder.linear), 'Linear player order');
    expect(
      roundOpeningOrderNote(TurnOrder.linear),
      'The same order is used every round.',
    );
    expect(roundOpeningOrderTitle(TurnOrder.snake), 'Reversed player order');
    expect(
      roundOpeningOrderNote(TurnOrder.rotating),
      'The next player starts each round.',
    );
  });
}
