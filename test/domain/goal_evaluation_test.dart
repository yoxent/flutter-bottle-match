import 'package:flutter_bottle_match/domain/models/configuration.dart';
import 'package:flutter_bottle_match/domain/rules/goal_evaluation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('first player to the target is the champion', () {
    final result = evaluateMatchGoal(
      rule: WinRule.firstToTarget,
      target: 3,
      selectedPlayerId: null,
      scores: const {'maya': 3, 'leo': 2},
    );

    expect(result.status, GoalStatus.champion);
    expect(result.playerId, 'maya');
  });

  test(
    'another player passing the target does not end selected-player mode',
    () {
      final result = evaluateMatchGoal(
        rule: WinRule.selectedPlayerReachesTarget,
        target: 3,
        selectedPlayerId: 'maya',
        scores: const {'maya': 2, 'leo': 4},
      );

      expect(result.status, GoalStatus.inProgress);
    },
  );

  test('the selected player can win without the highest score', () {
    final result = evaluateMatchGoal(
      rule: WinRule.selectedPlayerReachesTarget,
      target: 3,
      selectedPlayerId: 'maya',
      scores: const {'maya': 3, 'leo': 4},
    );

    expect(result.status, GoalStatus.champion);
    expect(result.playerId, 'maya');
  });

  test('two players at the first-to-target score stay unresolved', () {
    final result = evaluateMatchGoal(
      rule: WinRule.firstToTarget,
      target: 3,
      selectedPlayerId: null,
      scores: const {'maya': 3, 'leo': 3},
    );

    expect(result.status, GoalStatus.ambiguous);
    expect(result.playerId, isNull);
  });
}
