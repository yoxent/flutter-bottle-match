import '../domain/models/match_phase.dart';
import '../domain/models/match_snapshot.dart';
import '../domain/repositories/match_repository.dart';
import '../domain/rules/phase_transition.dart';

/// On launch, pauses an in-progress match without reshuffling it.
class LaunchRecovery {
  LaunchRecovery(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final MatchRepository _repository;
  final DateTime Function() _now;

  Future<MatchSnapshot?> prepare() async {
    final saved = await _repository.readActive();
    if (saved == null) {
      return null;
    }
    final paused = pauseForRecovery(saved, at: _now());
    if (identical(paused, saved)) {
      return saved;
    }
    await _repository.save(paused);
    return paused;
  }
}

/// Returns [snapshot] unchanged when it is already paused or cannot be paused.
MatchSnapshot pauseForRecovery(MatchSnapshot snapshot, {required DateTime at}) {
  final result = transition(
    phase: snapshot.phase,
    resumePhase: snapshot.resumePhase,
    event: MatchEvent.pause,
    mode: snapshot.mode,
  );
  if (result is! TransitionAccepted) {
    return snapshot;
  }
  return snapshot.copyWith(
    phase: MatchPhase.paused,
    resumePhase: result.change.resumePhase,
    timer: snapshot.timer.pauseAt(at),
    updatedAt: at,
  );
}
