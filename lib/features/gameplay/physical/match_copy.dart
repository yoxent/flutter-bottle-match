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

String roundOpeningLabel(int roundNumber) {
  final number = roundNumber < 0 ? 0 : roundNumber;
  return 'ROUND ${number.toString().padLeft(2, '0')}';
}

/// One line for the round-opening header.
///
/// A selected-player match shows that player's score. First-to-target shows
/// the target, because no single player owns the goal.
String roundOpeningScoreLine(MatchSnapshot snapshot) {
  final target = snapshot.settings.targetRoundWins;
  if (snapshot.settings.winRule == WinRule.firstToTarget) {
    return 'FIRST TO $target WINS';
  }
  final name = visibleName(
    snapshot.roster,
    snapshot.settings.selectedPlayerId,
  ).toUpperCase();
  final score = snapshot.scores[snapshot.settings.selectedPlayerId] ?? 0;
  return '$name GOAL • $score / $target WINS';
}

String roundOpeningOrderTitle(TurnOrder order) {
  return switch (order) {
    TurnOrder.random => 'Player Order',
    TurnOrder.linear => 'Linear player order',
    TurnOrder.snake => 'Reversed player order',
    TurnOrder.rotating => 'Rotated player order',
  };
}

String roundOpeningOrderNote(TurnOrder order) {
  return switch (order) {
    TurnOrder.random => 'A fresh order is randomized every round.',
    TurnOrder.linear => 'The same order is used every round.',
    TurnOrder.snake => 'The order reverses every round.',
    TurnOrder.rotating => 'The next player starts each round.',
  };
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

/// The player who met the match goal, if the goal names one.
String? championPlayerId(MatchSnapshot snapshot) {
  return evaluateMatchGoal(
    rule: snapshot.settings.winRule,
    target: snapshot.settings.targetRoundWins,
    selectedPlayerId: snapshot.settings.selectedPlayerId,
    scores: snapshot.scores,
  ).playerId;
}

/// Latest confirmed winner, if this match has one.
String? latestWinnerId(MatchSnapshot snapshot) {
  for (final win in snapshot.wins.reversed) {
    if (!win.reversed) {
      return win.winnerId;
    }
  }
  return null;
}

/// Up to [limit] players for the round-win list.
///
/// Distinct scores stay in highest-first order. When two of those players
/// share a score, the selected players are shown in this round's turn order
/// instead. Turn order also decides who keeps the last place when more than
/// [limit] players share that score.
List<String> topScorerIds(MatchSnapshot snapshot, {int limit = 3}) {
  final turn = snapshot.roundOrder.isEmpty
      ? [for (final player in snapshot.roster) player.id]
      : snapshot.roundOrder;
  final turnRank = <String, int>{
    for (var index = 0; index < turn.length; index++) turn[index]: index,
  };
  final ids = [for (final player in snapshot.roster) player.id];
  final fallback = <String, int>{
    for (var index = 0; index < ids.length; index++)
      if (!turnRank.containsKey(ids[index])) ids[index]: turn.length + index,
  };
  int seat(String id) =>
      turnRank[id] ?? fallback[id] ?? turn.length + ids.length;

  final ranked = [...ids]
    ..sort((a, b) {
      final byScore = (snapshot.scores[b] ?? 0).compareTo(
        snapshot.scores[a] ?? 0,
      );
      if (byScore != 0) {
        return byScore;
      }
      final bySeat = seat(a).compareTo(seat(b));
      if (bySeat != 0) {
        return bySeat;
      }
      return a.compareTo(b);
    });

  final count = limit < ranked.length ? limit : ranked.length;
  final selected = ranked.sublist(0, count);
  if (!_sharesScore(snapshot, selected)) {
    return selected;
  }
  selected.sort((a, b) {
    final bySeat = seat(a).compareTo(seat(b));
    if (bySeat != 0) {
      return bySeat;
    }
    return a.compareTo(b);
  });
  return selected;
}

bool _sharesScore(MatchSnapshot snapshot, List<String> ids) {
  final seen = <int>{};
  for (final id in ids) {
    final score = snapshot.scores[id] ?? 0;
    if (!seen.add(score)) {
      return true;
    }
  }
  return false;
}

String formatRemaining(Duration duration) {
  final seconds = duration.inSeconds;
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  return '$minutes:${rest.toString().padLeft(2, '0')}';
}
