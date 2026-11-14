import '../models/match_snapshot.dart';

/// Persistence contract for the single active match.
///
/// UI and game rules depend on this contract, not on Hive.
abstract interface class MatchRepository {
  Future<MatchSnapshot?> readActive();

  Future<void> save(MatchSnapshot snapshot);

  Future<void> clear();
}
