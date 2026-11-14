import 'dart:math';

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
