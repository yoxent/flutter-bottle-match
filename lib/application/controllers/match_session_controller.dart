import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/configuration.dart';
import '../../domain/models/match_snapshot.dart';
import '../../domain/models/player.dart';
import '../../domain/rules/physical_session.dart' as session;
import '../match_save_guard.dart';
import '../providers.dart';

/// Clock used by match commands. Tests replace it.
final matchClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Shuffle source for a new round. Tests replace it.
final matchRandomProvider = Provider<Random>((ref) => Random());

final matchSessionProvider =
    AsyncNotifierProvider<MatchSessionController, MatchSnapshot?>(
      MatchSessionController.new,
    );

sealed class StartMatchOutcome {
  const StartMatchOutcome();
}

class StartMatchReady extends StartMatchOutcome {
  const StartMatchReady(this.snapshot);

  final MatchSnapshot snapshot;
}

class StartMatchNeedsConfirmation extends StartMatchOutcome {
  const StartMatchNeedsConfirmation(this.existing);

  final MatchSnapshot existing;
}

class StartMatchRejected extends StartMatchOutcome {
  const StartMatchRejected(this.reason);

  final String reason;
}

class MatchSessionController extends AsyncNotifier<MatchSnapshot?> {
  MatchSnapshot? _pendingStart;
  var _writing = false;

  @override
  Future<MatchSnapshot?> build() {
    return ref.read(matchRepositoryProvider).readActive();
  }

  Future<StartMatchOutcome> startMatch({
    required List<Player> roster,
    required MatchSettings settings,
    bool replaceConfirmed = false,
    bool practice = false,
  }) async {
    await future;
    final at = ref.read(matchClockProvider)();
    final random = ref.read(matchRandomProvider);
    final MatchSnapshot opening;
    if (replaceConfirmed && _pendingStart != null) {
      opening = _pendingStart!;
    } else {
      final draft = MatchSnapshot(
        matchId: 'match-${at.microsecondsSinceEpoch}',
        mode: GameMode.fullyDigital,
        settings: settings,
        roster: roster,
        updatedAt: at,
      );
      final opened = practice
          ? session.openPractice(draft, random: random, at: at)
          : session.openFirstRound(draft, random: random, at: at);
      if (opened is session.SessionRejected) {
        return StartMatchRejected(opened.reason);
      }
      opening = (opened as session.SessionAccepted).snapshot;
    }

    final saved = await MatchSaveGuard(
      ref.read(matchRepositoryProvider),
    ).saveNew(opening, replaceConfirmed: replaceConfirmed);
    if (saved is NewMatchNeedsConfirmation) {
      _pendingStart = opening;
      return StartMatchNeedsConfirmation(saved.snapshot);
    }
    _pendingStart = null;
    state = AsyncData(saved.snapshot);
    return StartMatchReady(saved.snapshot);
  }

  Future<String?> beginRound() {
    return _commit((current, at) => session.beginRound(current, at: at));
  }

  Future<String?> markReady() {
    return _commit((current, at) => session.markPlayerReady(current, at: at));
  }

  Future<String?> advancePlayer() {
    return _commit((current, at) => session.advancePlayer(current, at: at));
  }

  Future<String?> requestWinner() {
    return _commit((current, at) => session.requestWinner(current, at: at));
  }

  Future<String?> confirmWinner(String winnerId) {
    return _commit(
      (current, at) =>
          session.confirmWinner(current, winnerId: winnerId, at: at),
    );
  }

  Future<String?> correctLastResult() {
    return _commit((current, at) => session.correctLastResult(current, at: at));
  }

  Future<String?> startNextRound() {
    return _commit(
      (current, at) => session.startNextRound(
        current,
        random: ref.read(matchRandomProvider),
        at: at,
      ),
    );
  }

  Future<String?> abandonRound() {
    return _commit(
      (current, at) => session.abandonRound(
        current,
        random: ref.read(matchRandomProvider),
        at: at,
      ),
    );
  }

  Future<String?> skipTurn() {
    return _commit((current, at) => session.skipTurn(current, at: at));
  }

  Future<String?> resume() {
    return _commit((current, at) => session.resumeSession(current, at: at));
  }

  Future<String?> endEarly() {
    return _commit((current, at) => session.endEarly(current, at: at));
  }

  Future<String?> renamePlayer({
    required String playerId,
    required String rawName,
  }) {
    return _commit(
      (current, at) => session.renamePlayer(
        current,
        playerId: playerId,
        rawName: rawName,
        at: at,
      ),
    );
  }

  Future<String?> changeAvatar({
    required String playerId,
    required int avatarIndex,
  }) {
    return _commit(
      (current, at) => session.changeAvatar(
        current,
        playerId: playerId,
        avatarIndex: avatarIndex,
        at: at,
      ),
    );
  }

  Future<String?> playAgain() {
    return _commit((current, at) {
      return session.playAgain(
        current,
        matchId: 'match-${at.microsecondsSinceEpoch}',
        random: ref.read(matchRandomProvider),
        at: at,
      );
    });
  }

  Future<String?> moveBottle({required int from, required int to}) {
    return _commit(
      (current, at) => session.moveBottle(current, from: from, to: to, at: at),
    );
  }

  Future<String?> submitArrangement() {
    return _commit((current, at) => session.submitArrangement(current, at: at));
  }

  Future<String?> takeHint() {
    return _commit(
      (current, at) => session.takeHint(
        current,
        random: ref.read(matchRandomProvider),
        at: at,
      ),
    );
  }

  Future<String?> expireTurn() {
    return _commit((current, at) => session.expireTurn(current, at: at));
  }

  Future<String?> finishPractice() {
    return _commit(
      (current, at) => session.finishPractice(
        current,
        random: ref.read(matchRandomProvider),
        at: at,
      ),
    );
  }

  /// Freezes a pausable match when the app or the screen is left.
  Future<void> pauseForInterruption() async {
    if (_writing) {
      return;
    }
    await future;
    final current = state.value;
    if (current == null) {
      return;
    }
    final result = session.pauseSession(
      current,
      at: ref.read(matchClockProvider)(),
    );
    if (result is! session.SessionAccepted) {
      return;
    }
    _writing = true;
    try {
      await ref.read(matchRepositoryProvider).save(result.snapshot);
      state = AsyncData(result.snapshot);
    } catch (_) {
      // The in-memory match stays as it was. Launch recovery pauses on the
      // next cold start if this write did not land.
    } finally {
      _writing = false;
    }
  }

  Future<String?> _commit(
    session.SessionResult Function(MatchSnapshot current, DateTime at) apply,
  ) async {
    if (_writing) {
      return 'Wait for the last action to finish.';
    }
    await future;
    final current = state.value;
    if (current == null) {
      return 'There is no match to update.';
    }
    _writing = true;
    try {
      final result = apply(current, ref.read(matchClockProvider)());
      if (result is session.SessionRejected) {
        return result.reason;
      }
      final accepted = (result as session.SessionAccepted).snapshot;
      await ref.read(matchRepositoryProvider).save(accepted);
      state = AsyncData(accepted);
      return null;
    } catch (_) {
      return 'The match could not be saved.';
    } finally {
      _writing = false;
    }
  }
}
