import 'dart:math';

import 'package:flutter_bottle_match/domain/rules/bottle_round.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a deal hides a target and shows a different starting order', () {
    for (var seed = 0; seed < 20; seed++) {
      final board = dealBoard(count: 5, random: Random(seed));

      expect(board.target, hasLength(5));
      expect(board.committed, hasLength(5));
      expect(board.pending, board.committed);
      expect(board.target.toSet(), {0, 1, 2, 3, 4});
      expect(board.committed.toSet(), board.target.toSet());
      expect(board.committed, isNot(board.target));
      expect(board.guesses, isEmpty);
      expect(board.hint, isNull);
      expect(board.practice, isFalse);
    }
  });

  test('feedback counts exact positions and blocks a repeated order', () {
    const target = [0, 1, 2, 3, 4];
    const arrangement = [0, 1, 2, 4, 3];

    final counted = judgeArrangement(
      target: target,
      arrangement: arrangement,
      previous: const [],
    );

    expect(counted, isA<GuessCounted>());
    final guess = counted as GuessCounted;
    expect(guess.correct, 3);
    expect(guess.solved, isFalse);

    final repeated = judgeArrangement(
      target: target,
      arrangement: arrangement,
      previous: const [arrangement],
    );
    expect(repeated, isA<GuessBlocked>());

    final solved = judgeArrangement(
      target: target,
      arrangement: target,
      previous: const [arrangement],
    );
    final solvedGuess = solved as GuessCounted;
    expect(solvedGuess.solved, isTrue);
    expect(solvedGuess.correct, 5);
  });

  test('an arrangement that is not a permutation is rejected', () {
    final result = judgeArrangement(
      target: const [0, 1, 2, 3, 4],
      arrangement: const [0, 0, 1, 2, 3],
      previous: const [],
    );

    expect(result, isA<GuessBlocked>());
  });

  test('dropping one bottle on another swaps only those positions', () {
    final swapped = swapBottles(const [0, 1, 2, 3, 4], 1, 3);

    expect(swapped, [0, 3, 2, 1, 4]);
    expect(swapBottles(const [0, 1, 2, 3, 4], 1, 1), isNull);
  });

  test('a hint names one hidden bottle at its position', () {
    const target = [4, 2, 0, 1, 3];
    final hint = revealHint(target: target, random: Random(2));

    expect(hint.position, inInclusiveRange(0, 4));
    expect(hint.bottle, target[hint.position]);
  });
}
