import '../models/match_phase.dart';

/// Session events the match shell can accept.
///
/// Guess, feedback, and hint events are absent. Those belong to the proposed
/// digital bottle board and are not part of this shell.
enum MatchEvent {
  startMatch,
  beginRound,
  playerReady,
  advanceToNextPlayer,
  requestPhysicalResult,
  confirmPhysicalResult,
  startNextRound,
  declareChampion,
  endUnfinished,
  pause,
  resume,
}

class PhaseChange {
  const PhaseChange({required this.phase, this.resumePhase});

  final MatchPhase phase;
  final MatchPhase? resumePhase;
}

sealed class TransitionResult {
  const TransitionResult();
}

class TransitionAccepted extends TransitionResult {
  const TransitionAccepted(this.change);

  final PhaseChange change;
}

class TransitionRejected extends TransitionResult {
  const TransitionRejected(this.reason);

  final String reason;
}

const _pausable = {
  MatchPhase.roundIntroduction,
  MatchPhase.playerHandoff,
  MatchPhase.activeTurn,
  MatchPhase.physicalResultConfirmation,
  MatchPhase.roundResult,
};

const _endable = {..._pausable, MatchPhase.paused};

/// Physical result correction stays available on the round result and on the
/// championship screen until another round starts.
bool canCorrectPhysicalResult(MatchPhase phase) {
  return phase == MatchPhase.roundResult || phase == MatchPhase.championship;
}

TransitionResult transition({
  required MatchPhase phase,
  required MatchPhase? resumePhase,
  required MatchEvent event,
}) {
  if (phase == MatchPhase.paused &&
      event != MatchEvent.resume &&
      event != MatchEvent.endUnfinished) {
    return const TransitionRejected('The match is paused.');
  }

  switch (event) {
    case MatchEvent.startMatch:
      return _from(
        phase,
        MatchPhase.setup,
        const PhaseChange(phase: MatchPhase.roundIntroduction),
      );
    case MatchEvent.beginRound:
      return _from(
        phase,
        MatchPhase.roundIntroduction,
        const PhaseChange(phase: MatchPhase.playerHandoff),
      );
    case MatchEvent.playerReady:
      return _from(
        phase,
        MatchPhase.playerHandoff,
        const PhaseChange(phase: MatchPhase.activeTurn),
      );
    case MatchEvent.advanceToNextPlayer:
      return _from(
        phase,
        MatchPhase.activeTurn,
        const PhaseChange(phase: MatchPhase.playerHandoff),
      );
    case MatchEvent.requestPhysicalResult:
      return _from(
        phase,
        MatchPhase.activeTurn,
        const PhaseChange(phase: MatchPhase.physicalResultConfirmation),
      );
    case MatchEvent.confirmPhysicalResult:
      return _from(
        phase,
        MatchPhase.physicalResultConfirmation,
        const PhaseChange(phase: MatchPhase.roundResult),
      );
    case MatchEvent.startNextRound:
      return _from(
        phase,
        MatchPhase.roundResult,
        const PhaseChange(phase: MatchPhase.roundIntroduction),
      );
    case MatchEvent.declareChampion:
      return _from(
        phase,
        MatchPhase.roundResult,
        const PhaseChange(phase: MatchPhase.championship),
      );
    case MatchEvent.endUnfinished:
      if (!_endable.contains(phase)) {
        return const TransitionRejected(
          'This match cannot be ended as unfinished from here.',
        );
      }
      return const TransitionAccepted(
        PhaseChange(phase: MatchPhase.unfinishedMatch),
      );
    case MatchEvent.pause:
      if (!_pausable.contains(phase)) {
        return const TransitionRejected(
          'This part of the match cannot be paused.',
        );
      }
      return TransitionAccepted(
        PhaseChange(phase: MatchPhase.paused, resumePhase: phase),
      );
    case MatchEvent.resume:
      if (phase != MatchPhase.paused ||
          resumePhase == null ||
          resumePhase == MatchPhase.paused) {
        return const TransitionRejected('There is no paused match to resume.');
      }
      return TransitionAccepted(PhaseChange(phase: resumePhase));
  }
}

TransitionResult _from(
  MatchPhase phase,
  MatchPhase expected,
  PhaseChange change,
) {
  if (phase != expected) {
    return TransitionRejected('Cannot do that from ${phase.name}.');
  }
  return TransitionAccepted(change);
}
