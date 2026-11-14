import 'dart:math';

import '../models/configuration.dart';
import '../models/match_phase.dart';
import '../models/match_snapshot.dart';
import '../models/player.dart';
import '../models/turn_clock.dart';
import 'bottle_round.dart';
import 'goal_evaluation.dart';
import 'match_setup_check.dart';
import 'phase_transition.dart';
import 'player_names.dart';
import 'round_order.dart';
import 'scorebook.dart';

part 'bottle_session.dart';

/// A match-shell change. A rejected command does not carry a snapshot.
sealed class SessionResult {
  const SessionResult();
}

class SessionAccepted extends SessionResult {
  const SessionAccepted(this.snapshot);

  final MatchSnapshot snapshot;
}

class SessionRejected extends SessionResult {
  const SessionRejected(this.reason);

  final String reason;
}

const _roundPhases = {
  MatchPhase.roundIntroduction,
  MatchPhase.playerHandoff,
  MatchPhase.activeTurn,
  MatchPhase.physicalResultConfirmation,
};

const _skippablePhases = {
  MatchPhase.playerHandoff,
  MatchPhase.activeTurn,
  MatchPhase.physicalResultConfirmation,
};

/// Opens round 1 from a valid setup snapshot.
SessionResult openFirstRound(
  MatchSnapshot snapshot, {
  required Random random,
  required DateTime at,
}) {
  final check = MatchSetupCheck.evaluate(
    roster: snapshot.roster,
    settings: snapshot.settings,
  );
  if (!check.isValid) {
    return SessionRejected(check.issues.first);
  }
  final opened = snapshot.apply(MatchEvent.startMatch, at: at);
  if (opened == null) {
    return const SessionRejected('Start the match from setup.');
  }
  return SessionAccepted(
    opened.copyWith(
      schemaVersion: MatchSnapshot.boardSchemaVersion,
      roundNumber: 1,
      roundOrder: roundPlayerOrder(
        rosterIds: _ids(snapshot),
        order: snapshot.settings.turnOrder,
        roundNumber: snapshot.roundNumber + 1,
        random: random,
      ),
      turnCycle: 1,
      currentPlayerIndex: 0,
      timer: _idleTurnClock(snapshot.settings.timer),
      board: dealBoard(count: snapshot.settings.bottleCount, random: random),
      replaceBoard: true,
      updatedAt: at,
    ),
  );
}

SessionResult beginRound(MatchSnapshot snapshot, {required DateTime at}) {
  return _phase(snapshot, MatchEvent.beginRound, at: at);
}

/// Starts the optional timer. The clock stays idle until the player is ready.
SessionResult markPlayerReady(MatchSnapshot snapshot, {required DateTime at}) {
  final ready = snapshot.apply(MatchEvent.playerReady, at: at);
  if (ready == null) {
    return const SessionRejected('The current player is not at the handoff.');
  }
  return SessionAccepted(
    ready.copyWith(timer: ready.timer.startAt(at), updatedAt: at),
  );
}

SessionResult advancePlayer(MatchSnapshot snapshot, {required DateTime at}) {
  if (snapshot.judgesGuesses) {
    return const SessionRejected('Submit the arrangement or skip the turn.');
  }
  return advanceAfterGuess(snapshot, at: at);
}

SessionResult advanceAfterGuess(
  MatchSnapshot snapshot, {
  required DateTime at,
}) {
  final order = _requireOrder(snapshot);
  if (order != null) {
    return order;
  }
  final step = _step(snapshot);
  final moved = snapshot.copyWith(
    currentPlayerIndex: step.index,
    turnCycle: step.cycle,
    timer: _idleTurnClock(snapshot.settings.timer),
    updatedAt: at,
  );
  final advanced = moved.apply(MatchEvent.advanceToNextPlayer, at: at);
  if (advanced == null) {
    return const SessionRejected('Advance the turn from the active player.');
  }
  return SessionAccepted(advanced);
}

SessionResult requestWinner(MatchSnapshot snapshot, {required DateTime at}) {
  if (snapshot.judgesGuesses) {
    return const SessionRejected('Submit the arrangement to judge this round.');
  }
  final requested = snapshot.apply(MatchEvent.requestPhysicalResult, at: at);
  if (requested == null) {
    return const SessionRejected('Record a winner during the active turn.');
  }
  return SessionAccepted(
    requested.copyWith(timer: snapshot.timer.pauseAt(at), updatedAt: at),
  );
}

SessionResult confirmWinner(
  MatchSnapshot snapshot, {
  required String winnerId,
  required DateTime at,
}) {
  if (snapshot.judgesGuesses) {
    return const SessionRejected('The board already judges this round.');
  }
  if (!snapshot.roster.any((player) => player.id == winnerId)) {
    return const SessionRejected('Choose a player from the roster.');
  }
  final awarded = snapshot.scorebook.award(
    roundNumber: snapshot.roundNumber,
    winnerId: winnerId,
  );
  if (awarded is! ScorebookAccepted) {
    return SessionRejected((awarded as ScorebookRejected).reason);
  }
  final withWin = snapshot.copyWith(
    wins: awarded.scorebook.wins,
    timer: _idleTurnClock(snapshot.settings.timer),
    updatedAt: at,
  );
  final confirmed = withWin.apply(MatchEvent.confirmPhysicalResult, at: at);
  if (confirmed == null) {
    return const SessionRejected('Confirm the winner from the result step.');
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

/// Reverses the last point once and reopens winner confirmation.
///
/// A first-to-target correction that leaves more than one player at the
/// target stays on the round result and does not name a champion.
SessionResult correctLastResult(
  MatchSnapshot snapshot, {
  required DateTime at,
}) {
  if (snapshot.judgesGuesses) {
    return const SessionRejected(
      'A submitted arrangement cannot be reassigned.',
    );
  }
  if (!canCorrectPhysicalResult(snapshot.phase)) {
    return const SessionRejected(
      'The last result can be corrected before the next round.',
    );
  }
  final reversed = snapshot.scorebook.reverseLast();
  if (reversed is! ScorebookAccepted) {
    return SessionRejected((reversed as ScorebookRejected).reason);
  }
  final updated = snapshot.copyWith(
    wins: reversed.scorebook.wins,
    timer: _idleTurnClock(snapshot.settings.timer),
    updatedAt: at,
  );
  final goal = _goal(updated);
  final phase = switch (goal.status) {
    GoalStatus.ambiguous => MatchPhase.roundResult,
    GoalStatus.champion => MatchPhase.championship,
    GoalStatus.inProgress => MatchPhase.physicalResultConfirmation,
  };
  return SessionAccepted(
    updated.copyWith(phase: phase, clearResumePhase: true, updatedAt: at),
  );
}

SessionResult startNextRound(
  MatchSnapshot snapshot, {
  required Random random,
  required DateTime at,
}) {
  if (snapshot.board?.practice == true) {
    return const SessionRejected('Finish the practice turn before the match.');
  }
  if (_goal(snapshot).status != GoalStatus.inProgress) {
    return const SessionRejected(
      'The next round is available while the match is still in progress.',
    );
  }
  final started = snapshot.apply(MatchEvent.startNextRound, at: at);
  if (started == null) {
    return const SessionRejected('Start the next round from the round result.');
  }
  return SessionAccepted(
    started.copyWith(
      roundNumber: snapshot.roundNumber + 1,
      roundOrder: roundPlayerOrder(
        rosterIds: _ids(snapshot),
        order: snapshot.settings.turnOrder,
        roundNumber: snapshot.roundNumber + 1,
        random: random,
      ),
      turnCycle: 1,
      currentPlayerIndex: 0,
      timer: _idleTurnClock(snapshot.settings.timer),
      board: _freshBoard(snapshot, random),
      replaceBoard: true,
      updatedAt: at,
    ),
  );
}

SessionResult abandonRound(
  MatchSnapshot snapshot, {
  required Random random,
  required DateTime at,
}) {
  if (!_allows(_roundPhases, snapshot)) {
    return const SessionRejected('This round cannot be abandoned from here.');
  }
  return SessionAccepted(
    snapshot.copyWith(
      phase: MatchPhase.roundIntroduction,
      clearResumePhase: true,
      roundNumber: snapshot.roundNumber + 1,
      roundOrder: roundPlayerOrder(
        rosterIds: _ids(snapshot),
        order: snapshot.settings.turnOrder,
        roundNumber: snapshot.roundNumber + 1,
        random: random,
      ),
      turnCycle: 1,
      currentPlayerIndex: 0,
      timer: _idleTurnClock(snapshot.settings.timer),
      board: _freshBoard(snapshot, random),
      replaceBoard: true,
      updatedAt: at,
    ),
  );
}

SessionResult skipTurn(MatchSnapshot snapshot, {required DateTime at}) {
  final order = _requireOrder(snapshot);
  if (order != null) {
    return order;
  }
  if (!_allows(_skippablePhases, snapshot)) {
    return const SessionRejected('Skip a turn from the current player.');
  }
  final prepared = _discardPending(snapshot);
  final step = _step(prepared);
  return SessionAccepted(
    prepared.copyWith(
      phase: MatchPhase.playerHandoff,
      clearResumePhase: true,
      currentPlayerIndex: step.index,
      turnCycle: step.cycle,
      timer: _idleTurnClock(snapshot.settings.timer),
      updatedAt: at,
    ),
  );
}

SessionResult pauseSession(MatchSnapshot snapshot, {required DateTime at}) {
  final result = transition(
    phase: snapshot.phase,
    resumePhase: snapshot.resumePhase,
    event: MatchEvent.pause,
  );
  if (result is! TransitionAccepted) {
    return const SessionRejected('This part of the match cannot be paused.');
  }
  return SessionAccepted(
    snapshot.copyWith(
      phase: MatchPhase.paused,
      resumePhase: result.change.resumePhase,
      timer: snapshot.timer.pauseAt(at),
      updatedAt: at,
    ),
  );
}

SessionResult resumeSession(MatchSnapshot snapshot, {required DateTime at}) {
  final resumed = snapshot.apply(MatchEvent.resume, at: at);
  if (resumed == null) {
    return const SessionRejected('There is no paused match to resume.');
  }
  final timer = resumed.phase == MatchPhase.activeTurn
      ? resumed.timer.resumeAt(at)
      : resumed.timer;
  return SessionAccepted(resumed.copyWith(timer: timer, updatedAt: at));
}

SessionResult endEarly(MatchSnapshot snapshot, {required DateTime at}) {
  final frozen = snapshot.copyWith(
    timer: snapshot.timer.pauseAt(at),
    updatedAt: at,
  );
  final ended = frozen.apply(MatchEvent.endUnfinished, at: at);
  if (ended == null) {
    return const SessionRejected(
      'This match cannot be ended as unfinished from here.',
    );
  }
  return SessionAccepted(ended);
}

SessionResult renamePlayer(
  MatchSnapshot snapshot, {
  required String playerId,
  required String rawName,
  required DateTime at,
}) {
  if (snapshot.phase != MatchPhase.paused) {
    return const SessionRejected('Names can be corrected from pause.');
  }
  final index = snapshot.roster.indexWhere((player) => player.id == playerId);
  if (index < 0) {
    return const SessionRejected('That player is not in this match.');
  }
  final name = normalizePlayerName(rawName, index + 1);
  if (!isPlayerNameLengthValid(name)) {
    return const SessionRejected('Player names must be 1 to 20 characters.');
  }
  final roster = [...snapshot.roster];
  final player = roster[index];
  roster[index] = Player(
    id: player.id,
    name: name,
    avatarIndex: player.avatarIndex,
    accentIndex: player.accentIndex,
  );
  return SessionAccepted(snapshot.copyWith(roster: roster, updatedAt: at));
}

SessionResult changeAvatar(
  MatchSnapshot snapshot, {
  required String playerId,
  required int avatarIndex,
  required DateTime at,
}) {
  if (snapshot.phase != MatchPhase.paused) {
    return const SessionRejected('Avatars can be corrected from pause.');
  }
  if (avatarIndex < 0) {
    return const SessionRejected('Choose an avatar.');
  }
  final index = snapshot.roster.indexWhere((player) => player.id == playerId);
  if (index < 0) {
    return const SessionRejected('That player is not in this match.');
  }
  final roster = [...snapshot.roster];
  final player = roster[index];
  roster[index] = Player(
    id: player.id,
    name: player.name,
    avatarIndex: avatarIndex,
    accentIndex: player.accentIndex,
  );
  return SessionAccepted(snapshot.copyWith(roster: roster, updatedAt: at));
}

/// Keeps the roster and locked settings, then opens a fresh round 1.
SessionResult playAgain(
  MatchSnapshot snapshot, {
  required String matchId,
  required Random random,
  required DateTime at,
}) {
  if (snapshot.phase != MatchPhase.championship) {
    return const SessionRejected('Play again from the championship.');
  }
  return openFirstRound(
    MatchSnapshot(
      matchId: matchId,
      mode: snapshot.mode,
      settings: snapshot.settings,
      roster: snapshot.roster,
      updatedAt: at,
    ),
    random: random,
    at: at,
  );
}

SessionResult _phase(
  MatchSnapshot snapshot,
  MatchEvent event, {
  required DateTime at,
}) {
  final next = snapshot.apply(event, at: at);
  if (next == null) {
    return const SessionRejected('That action is not available right now.');
  }
  return SessionAccepted(next);
}

GoalEvaluation _goal(MatchSnapshot snapshot) {
  return evaluateMatchGoal(
    rule: snapshot.settings.winRule,
    target: snapshot.settings.targetRoundWins,
    selectedPlayerId: snapshot.settings.selectedPlayerId,
    scores: snapshot.scores,
  );
}

/// Builds a frozen clock at the full allowance. An off timer stays off.
TurnClock _idleTurnClock(TurnTimerDuration duration) {
  final limit = duration.limit;
  if (limit == null) {
    return const TurnClock();
  }
  return TurnClock(duration: duration, remaining: limit);
}

List<String> _ids(MatchSnapshot snapshot) {
  return [for (final player in snapshot.roster) player.id];
}

SessionResult? _requireOrder(MatchSnapshot snapshot) {
  final index = snapshot.currentPlayerIndex;
  if (snapshot.roundOrder.isEmpty ||
      index == null ||
      index < 0 ||
      index >= snapshot.roundOrder.length) {
    return const SessionRejected('The round order is not ready.');
  }
  return null;
}

({int index, int cycle}) _step(MatchSnapshot snapshot) {
  final length = snapshot.roundOrder.length;
  final next = (snapshot.currentPlayerIndex! + 1) % length;
  final cycle = snapshot.turnCycle + (next == 0 ? 1 : 0);
  return (index: next, cycle: cycle);
}

BottleBoard? _freshBoard(MatchSnapshot snapshot, Random random) {
  final current = snapshot.board;
  if (current == null) {
    return null;
  }
  return dealBoard(
    count: snapshot.settings.bottleCount,
    random: random,
    practice: current.practice,
  );
}

MatchSnapshot _discardPending(MatchSnapshot snapshot) {
  final board = snapshot.board;
  if (board == null) {
    return snapshot;
  }
  return snapshot.copyWith(
    board: board.copyWith(pending: List<int>.of(board.committed)),
  );
}

bool _allows(Set<MatchPhase> phases, MatchSnapshot snapshot) {
  if (phases.contains(snapshot.phase)) {
    return true;
  }
  final resume = snapshot.resumePhase;
  return snapshot.phase == MatchPhase.paused &&
      resume != null &&
      phases.contains(resume);
}
