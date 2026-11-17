import 'dart:math';

import '../models/bottle_board.dart';

export '../models/bottle_board.dart';

/// [turnCycle] starts at 1. A hint is offered once this value is reached,
/// which is after every player has had three turns.
const bottleHintCycle = 4;

sealed class GuessCheck {
  const GuessCheck();
}

class GuessBlocked extends GuessCheck {
  const GuessBlocked(this.reason);

  final String reason;
}

class GuessCounted extends GuessCheck {
  const GuessCounted({required this.correct, required this.solved});

  final int correct;
  final bool solved;
}

/// Shuffles N distinct bottles into a hidden target and a different start.
BottleBoard dealBoard({
  required int count,
  required Random random,
  bool practice = false,
}) {
  final target = _shuffle(count, random);
  var starting = _shuffle(count, random);
  if (_same(starting, target)) {
    final first = starting[0];
    starting[0] = starting[1];
    starting[1] = first;
  }
  return BottleBoard(
    target: target,
    committed: List<int>.of(starting),
    pending: List<int>.of(starting),
    opening: List<int>.of(starting),
    practice: practice,
  );
}

/// A, B, C from [opening]. The letter stays with that bottle for the round.
String roundBottleLetter(List<int> opening, int bottle) {
  final index = opening.indexOf(bottle);
  final slot = index < 0 ? (bottle < 0 ? 0 : bottle) : index;
  return String.fromCharCode(65 + (slot % 26));
}

String roundOrderLabel(List<int> opening, List<int> bottles) {
  return [
    for (final bottle in bottles) roundBottleLetter(opening, bottle),
  ].join(', ');
}

GuessCheck judgeArrangement({
  required List<int> target,
  required List<int> arrangement,
  required List<List<int>> previous,
  bool rejectRepeated = false,
}) {
  if (!_permutation(arrangement, target.length)) {
    return const GuessBlocked('Arrange each bottle once.');
  }
  if (rejectRepeated) {
    for (final earlier in previous) {
      if (_same(earlier, arrangement)) {
        return const GuessBlocked('That order was already checked.');
      }
    }
  }
  final correct = _exactCount(target, arrangement);
  return GuessCounted(correct: correct, solved: correct == target.length);
}

/// Swaps two positions. The same position returns null and changes nothing.
List<int>? swapBottles(List<int> arrangement, int from, int to) {
  if (from == to ||
      from < 0 ||
      to < 0 ||
      from >= arrangement.length ||
      to >= arrangement.length) {
    return null;
  }
  final next = List<int>.of(arrangement);
  final bottle = next[from];
  next[from] = next[to];
  next[to] = bottle;
  return next;
}

BottleHint revealHint({required List<int> target, required Random random}) {
  final position = random.nextInt(target.length);
  return BottleHint(position: position, bottle: target[position]);
}

List<int> _shuffle(int count, Random random) {
  final order = [for (var index = 0; index < count; index++) index];
  for (var index = order.length - 1; index > 0; index--) {
    final swapIndex = random.nextInt(index + 1);
    final current = order[index];
    order[index] = order[swapIndex];
    order[swapIndex] = current;
  }
  return order;
}

int _exactCount(List<int> target, List<int> arrangement) {
  var correct = 0;
  for (var index = 0; index < target.length; index++) {
    if (arrangement[index] == target[index]) {
      correct++;
    }
  }
  return correct;
}

bool _permutation(List<int> arrangement, int count) {
  if (arrangement.length != count) {
    return false;
  }
  final seen = <int>{};
  for (final bottle in arrangement) {
    if (bottle < 0 || bottle >= count || !seen.add(bottle)) {
      return false;
    }
  }
  return true;
}

bool _same(List<int> left, List<int> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
