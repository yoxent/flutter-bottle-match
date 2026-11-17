import '../domain/models/match_snapshot.dart';
import '../domain/repositories/match_repository.dart';
import '../domain/rules/physical_session.dart';

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
  final result = pauseSession(snapshot, at: at);
  if (result is SessionAccepted) {
    return result.snapshot;
  }
  return snapshot;
}
