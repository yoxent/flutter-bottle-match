import '../domain/models/match_snapshot.dart';
import '../domain/repositories/match_repository.dart';

sealed class NewMatchSave {
  const NewMatchSave(this.snapshot);

  final MatchSnapshot snapshot;
}

class NewMatchSaved extends NewMatchSave {
  const NewMatchSaved(super.snapshot);
}

class NewMatchNeedsConfirmation extends NewMatchSave {
  const NewMatchNeedsConfirmation(super.snapshot);
}

/// Blocks replacement of an unfinished match until the caller confirms it.
class MatchSaveGuard {
  const MatchSaveGuard(this._repository);

  final MatchRepository _repository;

  Future<NewMatchSave> saveNew(
    MatchSnapshot next, {
    required bool replaceConfirmed,
  }) async {
    final current = await _repository.readActive();
    final unfinished = current != null && !current.replacesWithoutConfirmation;
    if (unfinished && !replaceConfirmed) {
      return NewMatchNeedsConfirmation(current);
    }
    await _repository.save(next);
    return NewMatchSaved(next);
  }
}
