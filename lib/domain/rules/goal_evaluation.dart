import '../models/configuration.dart';

enum GoalStatus { inProgress, champion, ambiguous }

/// Result of checking the match goal against current scores.
///
/// [GoalStatus.ambiguous] is reserved for a first-to-target correction that
/// leaves more than one player at or above the target. The GDD does not name
/// the champion in that case, so this evaluation does not choose one.
class GoalEvaluation {
  const GoalEvaluation.inProgress()
    : status = GoalStatus.inProgress,
      playerId = null;

  const GoalEvaluation.champion(this.playerId) : status = GoalStatus.champion;

  const GoalEvaluation.ambiguous()
    : status = GoalStatus.ambiguous,
      playerId = null;

  final GoalStatus status;
  final String? playerId;
}

GoalEvaluation evaluateMatchGoal({
  required WinRule rule,
  required int target,
  required String? selectedPlayerId,
  required Map<String, int> scores,
}) {
  switch (rule) {
    case WinRule.selectedPlayerReachesTarget:
      final playerId = selectedPlayerId;
      if (playerId == null) {
        return const GoalEvaluation.inProgress();
      }
      if ((scores[playerId] ?? 0) >= target) {
        return GoalEvaluation.champion(playerId);
      }
      return const GoalEvaluation.inProgress();
    case WinRule.firstToTarget:
      final qualified = [
        for (final entry in scores.entries)
          if (entry.value >= target) entry.key,
      ];
      if (qualified.isEmpty) {
        return const GoalEvaluation.inProgress();
      }
      if (qualified.length == 1) {
        return GoalEvaluation.champion(qualified.single);
      }
      return const GoalEvaluation.ambiguous();
  }
}
