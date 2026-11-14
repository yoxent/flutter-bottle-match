import '../models/round_win.dart';
import 'match_constraints.dart';

/// The round-win ledger is the only source of points.
///
/// Unsuccessful guesses, skips, timeouts, and abandoned rounds are absent
/// from the ledger, so they cannot add a point. Recording the same round
/// twice is rejected.
class Scorebook {
  const Scorebook([this.wins = const []]);

  final List<RoundWin> wins;

  Map<String, int> scoresFor(Iterable<String> playerIds) {
    final scores = {for (final id in playerIds) id: 0};
    for (final win in wins) {
      if (win.reversed || !scores.containsKey(win.winnerId)) {
        continue;
      }
      scores[win.winnerId] =
          scores[win.winnerId]! + MatchConstraints.roundWinPoints;
    }
    return scores;
  }

  ScorebookChange award({required int roundNumber, required String winnerId}) {
    final alreadyAwarded = wins.any(
      (win) => win.roundNumber == roundNumber && !win.reversed,
    );
    if (alreadyAwarded) {
      return ScorebookRejected(
        'Round $roundNumber already has a confirmed winner.',
      );
    }
    return ScorebookAccepted(
      Scorebook([
        ...wins,
        RoundWin(roundNumber: roundNumber, winnerId: winnerId),
      ]),
    );
  }

  /// Reverses only the latest entry, and only once.
  ScorebookChange reverseLast() {
    if (wins.isEmpty || wins.last.reversed) {
      return const ScorebookRejected('There is no round result to correct.');
    }
    final corrected = [
      ...wins.take(wins.length - 1),
      RoundWin(
        roundNumber: wins.last.roundNumber,
        winnerId: wins.last.winnerId,
        reversed: true,
      ),
    ];
    return ScorebookAccepted(Scorebook(corrected));
  }
}

sealed class ScorebookChange {
  const ScorebookChange();
}

class ScorebookAccepted extends ScorebookChange {
  const ScorebookAccepted(this.scorebook);

  final Scorebook scorebook;
}

class ScorebookRejected extends ScorebookChange {
  const ScorebookRejected(this.reason);

  final String reason;
}
