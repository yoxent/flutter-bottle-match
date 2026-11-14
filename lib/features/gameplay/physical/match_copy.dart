import '../../../domain/models/configuration.dart';
import '../../../domain/models/match_snapshot.dart';
import '../../../domain/models/player.dart';
import '../../../domain/rules/goal_evaluation.dart';
import '../../../domain/rules/player_names.dart';

String visibleName(List<Player> roster, String? id) {
  if (id == null) {
    return 'Waiting';
  }
  final names = visiblePlayerNames(roster);
  final index = roster.indexWhere((player) => player.id == id);
  if (index < 0) {
    return id;
  }
  return names[index];
}

String currentPlayerName(MatchSnapshot snapshot) {
  final index = snapshot.currentPlayerIndex;
  if (index == null || index < 0 || index >= snapshot.roundOrder.length) {
    return 'Waiting';
  }
  return visibleName(snapshot.roster, snapshot.roundOrder[index]);
}

String nextPlayerName(MatchSnapshot snapshot) {
  final index = snapshot.currentPlayerIndex;
  if (index == null || snapshot.roundOrder.isEmpty) {
    return 'Waiting';
  }
  final next = (index + 1) % snapshot.roundOrder.length;
  return visibleName(snapshot.roster, snapshot.roundOrder[next]);
}

String currentPlayerId(MatchSnapshot snapshot) {
  final index = snapshot.currentPlayerIndex;
  if (index == null || index < 0 || index >= snapshot.roundOrder.length) {
    return snapshot.roster.first.id;
  }
  return snapshot.roundOrder[index];
}

String goalLabel(MatchSnapshot snapshot) {
  final target = snapshot.settings.targetRoundWins;
  if (snapshot.settings.winRule == WinRule.firstToTarget) {
    return 'First to $target';
  }
  final name = visibleName(snapshot.roster, snapshot.settings.selectedPlayerId);
  final score = snapshot.scores[snapshot.settings.selectedPlayerId] ?? 0;
  return '$name\'s goal: $score / $target wins';
}

String standingsLabel(MatchSnapshot snapshot) {
  final names = visiblePlayerNames(snapshot.roster);
  return [
    for (var index = 0; index < snapshot.roster.length; index++)
      '${names[index]} ${snapshot.scores[snapshot.roster[index].id] ?? 0}',
  ].join(' · ');
}

String winConditionSummary(List<Player> roster, MatchSettings settings) {
  final target = settings.targetRoundWins;
  final wins = target == 1 ? 'round win' : 'round wins';
  return switch (settings.winRule) {
    WinRule.firstToTarget => 'First player to $target $wins',
    WinRule.selectedPlayerReachesTarget =>
      '${visibleName(roster, settings.selectedPlayerId)} reaches $target $wins. '
          'Only that player ends the match.',
  };
}

String timerSummary(TurnTimerDuration timer) {
  return switch (timer) {
    TurnTimerDuration.off => 'Off',
    TurnTimerDuration.seconds30 => '30 seconds',
    TurnTimerDuration.seconds60 => '60 seconds',
    TurnTimerDuration.seconds90 => '90 seconds',
  };
}

String turnOrderName(TurnOrder order) {
  return switch (order) {
    TurnOrder.linear => 'Linear',
    TurnOrder.snake => 'Snake',
    TurnOrder.rotating => 'Rotating',
    TurnOrder.random => 'Random',
  };
}

String turnOrderSummary(TurnOrder order) {
  return switch (order) {
    TurnOrder.linear => 'Same order every round',
    TurnOrder.snake => 'Reverse every round',
    TurnOrder.rotating => 'Next player starts each round',
    TurnOrder.random => 'New order every round',
  };
}

String championTitle(MatchSnapshot snapshot) {
  final goal = evaluateMatchGoal(
    rule: snapshot.settings.winRule,
    target: snapshot.settings.targetRoundWins,
    selectedPlayerId: snapshot.settings.selectedPlayerId,
    scores: snapshot.scores,
  );
  final name = visibleName(snapshot.roster, goal.playerId).toUpperCase();
  if (goal.playerId == null) {
    return 'The champion is unresolved';
  }
  return switch (snapshot.settings.winRule) {
    WinRule.firstToTarget => '$name WINS!',
    WinRule.selectedPlayerReachesTarget => 'GOAL ACHIEVED, $name!',
  };
}

String roundWinnerLines(MatchSnapshot snapshot) {
  final wins = [
    for (final win in snapshot.wins)
      if (!win.reversed)
        'Round ${win.roundNumber}: ${visibleName(snapshot.roster, win.winnerId)}',
  ];
  if (wins.isEmpty) {
    return 'No round winners yet.';
  }
  return wins.join('\n');
}

String formatRemaining(Duration duration) {
  final seconds = duration.inSeconds;
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  return '$minutes:${rest.toString().padLeft(2, '0')}';
}
