part of 'physical_session.dart';

SessionResult openPractice(
  MatchSnapshot snapshot, {
  required Random random,
  required DateTime at,
}) {
  final opened = openFirstRound(snapshot, random: random, at: at);
  if (opened is! SessionAccepted) {
    return opened;
  }
  final board = opened.snapshot.board;
  if (board == null) {
    return const SessionRejected('Practice needs a bottle board.');
  }
  return SessionAccepted(
    opened.snapshot.copyWith(board: board.copyWith(practice: true)),
  );
}

SessionResult finishPractice(
  MatchSnapshot snapshot, {
  required Random random,
  required DateTime at,
}) {
  if (snapshot.board?.practice != true) {
    return const SessionRejected('Practice is not in progress.');
  }
  if (snapshot.phase != MatchPhase.roundResult) {
    return const SessionRejected('Finish practice from its result.');
  }
  return openFirstRound(
    MatchSnapshot(
      matchId: snapshot.matchId,
      mode: snapshot.mode,
      settings: snapshot.settings,
      roster: snapshot.roster,
      updatedAt: at,
    ),
    random: random,
    at: at,
  );
}

SessionResult moveBottle(
  MatchSnapshot snapshot, {
  required int from,
  required int to,
  required DateTime at,
}) {
  final board = snapshot.board;
  if (board == null) {
    return const SessionRejected('This match has no bottle board.');
  }
  if (snapshot.phase != MatchPhase.activeTurn) {
    return const SessionRejected('Move bottles during the active turn.');
  }
  final swapped = swapBottles(board.pending, from, to);
  if (swapped == null) {
    return const SessionRejected('Choose two different positions.');
  }
  return SessionAccepted(
    snapshot.copyWith(
      board: board.copyWith(pending: swapped),
      updatedAt: at,
    ),
  );
}

SessionResult submitArrangement(
  MatchSnapshot snapshot, {
  required DateTime at,
}) {
  final board = snapshot.board;
  if (board == null) {
    return const SessionRejected('This match has no bottle board.');
  }
  if (snapshot.phase != MatchPhase.activeTurn) {
    return const SessionRejected(
      'Check the arrangement during the active turn.',
    );
  }
  final check = judgeArrangement(
    target: board.target,
    arrangement: board.pending,
    previous: [for (final guess in board.guesses) guess.arrangement],
  );
  if (check is GuessBlocked) {
    return SessionRejected(check.reason);
  }
  final counted = check as GuessCounted;
  final submitted = List<int>.of(board.pending);
  final withGuess = snapshot.copyWith(
    board: board.copyWith(
      committed: submitted,
      pending: List<int>.of(submitted),
      guesses: [
        ...board.guesses,
        BottleGuess(arrangement: submitted, correct: counted.correct),
      ],
    ),
    updatedAt: at,
  );
  if (board.practice) {
    return _closePractice(withGuess, at: at);
  }
  if (!counted.solved) {
    return advanceAfterGuess(withGuess, at: at);
  }
  return _awardSolver(withGuess, at: at);
}

SessionResult takeHint(
  MatchSnapshot snapshot, {
  required Random random,
  required DateTime at,
}) {
  final board = snapshot.board;
  if (board == null) {
    return const SessionRejected('This match has no bottle board.');
  }
  if (snapshot.phase != MatchPhase.paused) {
    return const SessionRejected('Open the hint from pause.');
  }
  if (board.hint != null) {
    return const SessionRejected('The hint was already used.');
  }
  if (snapshot.turnCycle < bottleHintCycle) {
    return const SessionRejected(
      'A hint is available after everyone has played three times.',
    );
  }
  return SessionAccepted(
    snapshot.copyWith(
      board: board.copyWith(
        hint: revealHint(target: board.target, random: random),
      ),
      updatedAt: at,
    ),
  );
}

SessionResult expireTurn(MatchSnapshot snapshot, {required DateTime at}) {
  final board = snapshot.board;
  if (board == null) {
    return const SessionRejected('This match has no bottle board.');
  }
  if (snapshot.phase != MatchPhase.activeTurn) {
    return const SessionRejected('The timer ends the active turn.');
  }
  if (snapshot.settings.timer == TurnTimerDuration.off ||
      snapshot.timer.remainingAt(at) > Duration.zero) {
    return const SessionRejected('The timer is still running.');
  }
  return skipTurn(_discardPending(snapshot), at: at);
}

SessionResult _closePractice(MatchSnapshot snapshot, {required DateTime at}) {
  final requested = snapshot.apply(MatchEvent.requestPhysicalResult, at: at);
  if (requested == null) {
    return const SessionRejected('Practice could not be checked.');
  }
  final confirmed = requested.apply(MatchEvent.confirmPhysicalResult, at: at);
  if (confirmed == null) {
    return const SessionRejected('Practice could not be checked.');
  }
  return SessionAccepted(
    confirmed.copyWith(
      timer: _idleTurnClock(snapshot.settings.timer),
      updatedAt: at,
    ),
  );
}

SessionResult _awardSolver(MatchSnapshot snapshot, {required DateTime at}) {
  final index = snapshot.currentPlayerIndex;
  if (index == null || index < 0 || index >= snapshot.roundOrder.length) {
    return const SessionRejected('The round order is not ready.');
  }
  final awarded = snapshot.scorebook.award(
    roundNumber: snapshot.roundNumber,
    winnerId: snapshot.roundOrder[index],
  );
  if (awarded is! ScorebookAccepted) {
    return SessionRejected((awarded as ScorebookRejected).reason);
  }
  final withWin = snapshot.copyWith(
    wins: awarded.scorebook.wins,
    timer: _idleTurnClock(snapshot.settings.timer),
    updatedAt: at,
  );
  final requested = withWin.apply(MatchEvent.requestPhysicalResult, at: at);
  if (requested == null) {
    return const SessionRejected('The solved order could not be recorded.');
  }
  final confirmed = requested.apply(MatchEvent.confirmPhysicalResult, at: at);
  if (confirmed == null) {
    return const SessionRejected('The solved order could not be recorded.');
  }
  final goal = _goal(confirmed);
  if (goal.status == GoalStatus.champion) {
    final champion = confirmed.apply(MatchEvent.declareChampion, at: at);
    if (champion == null) {
      return const SessionRejected('The match goal could not be completed.');
    }
    return SessionAccepted(champion);
  }
  return SessionAccepted(confirmed);
}
