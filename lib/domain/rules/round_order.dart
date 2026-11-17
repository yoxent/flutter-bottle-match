import 'dart:math';

import '../models/configuration.dart';

/// Shuffles the full roster for a new round.
///
/// A fresh shuffle may repeat the previous order. This function does not
/// reject a repeated order. Every id appears exactly once.
List<String> shufflePlayerOrder(List<String> playerIds, Random random) {
  final order = List<String>.of(playerIds);
  for (var index = order.length - 1; index > 0; index--) {
    final swapIndex = random.nextInt(index + 1);
    final current = order[index];
    order[index] = order[swapIndex];
    order[swapIndex] = current;
  }
  return order;
}

/// Orders [rosterIds] for [roundNumber], which starts at 1.
///
/// Linear, snake, and rotating follow the roster list. Random shuffles it.
/// Every id appears once. Inside a round, callers repeat the returned list.
List<String> roundPlayerOrder({
  required List<String> rosterIds,
  required TurnOrder order,
  required int roundNumber,
  required Random random,
}) {
  final roster = List<String>.of(rosterIds);
  return switch (order) {
    TurnOrder.linear => roster,
    TurnOrder.snake => roundNumber.isOdd ? roster : roster.reversed.toList(),
    TurnOrder.rotating => _rotate(roster, roundNumber),
    TurnOrder.random => shufflePlayerOrder(roster, random),
  };
}

List<String> _rotate(List<String> roster, int roundNumber) {
  if (roster.isEmpty) {
    return roster;
  }
  final shift = (roundNumber - 1) % roster.length;
  return [...roster.sublist(shift), ...roster.sublist(0, shift)];
}
