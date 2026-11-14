import 'dart:math';

import 'package:flutter_bottle_match/domain/models/configuration.dart';
import 'package:flutter_bottle_match/domain/rules/round_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const roster = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l'];

  test('a seeded shuffle is stable and contains every player once', () {
    final first = shufflePlayerOrder(roster, Random(7));
    final second = shufflePlayerOrder(roster, Random(7));

    expect(first, second);
    expect(first.toSet(), roster.toSet());
    expect(first, hasLength(roster.length));
  });

  test('an unchanged order is a legal result', () {
    List<String>? unchanged;
    for (var seed = 0; seed < 20; seed++) {
      final order = shufflePlayerOrder(const ['maya', 'leo'], Random(seed));
      if (order.first == 'maya' && order.last == 'leo') {
        unchanged = order;
        break;
      }
    }

    expect(unchanged, ['maya', 'leo']);
  });

  test(
    'linear keeps the roster order and snake reverses every other round',
    () {
      const roster = ['maya', 'leo', 'ava'];

      expect(
        roundPlayerOrder(
          rosterIds: roster,
          order: TurnOrder.linear,
          roundNumber: 2,
          random: Random(1),
        ),
        roster,
      );
      expect(
        roundPlayerOrder(
          rosterIds: roster,
          order: TurnOrder.snake,
          roundNumber: 1,
          random: Random(1),
        ),
        roster,
      );
      expect(
        roundPlayerOrder(
          rosterIds: roster,
          order: TurnOrder.snake,
          roundNumber: 2,
          random: Random(1),
        ),
        ['ava', 'leo', 'maya'],
      );
    },
  );

  test('rotating moves the start forward and random can repeat', () {
    const roster = ['maya', 'leo', 'ava'];

    expect(
      roundPlayerOrder(
        rosterIds: roster,
        order: TurnOrder.rotating,
        roundNumber: 1,
        random: Random(1),
      ),
      roster,
    );
    expect(
      roundPlayerOrder(
        rosterIds: roster,
        order: TurnOrder.rotating,
        roundNumber: 2,
        random: Random(1),
      ),
      ['leo', 'ava', 'maya'],
    );
    expect(
      roundPlayerOrder(
        rosterIds: roster,
        order: TurnOrder.rotating,
        roundNumber: 4,
        random: Random(1),
      ),
      roster,
    );

    final repeated = roundPlayerOrder(
      rosterIds: const ['maya', 'leo'],
      order: TurnOrder.random,
      roundNumber: 3,
      random: Random(1),
    );
    expect(repeated.toSet(), {'maya', 'leo'});
  });

  test('a saved match without a turn order stays random', () {
    final settings = MatchSettings.fromJson(const {
      'winRule': 'firstToTarget',
      'targetRoundWins': 3,
      'selectedPlayerId': null,
      'bottleCount': 5,
      'timer': 'off',
      'physicalEquipmentConfirmed': false,
    });

    expect(settings.turnOrder, TurnOrder.random);
  });
}
