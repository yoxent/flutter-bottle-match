import 'dart:math';

import 'package:flutter_bottle_match/domain/models/configuration.dart';
import 'package:flutter_bottle_match/domain/models/match_phase.dart';
import 'package:flutter_bottle_match/domain/models/match_snapshot.dart';
import 'package:flutter_bottle_match/domain/models/round_win.dart';
import 'package:flutter_bottle_match/domain/rules/bottle_round.dart';
import 'package:flutter_bottle_match/domain/rules/physical_session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/match_fixtures.dart';

void main() {
  test(
    'a valid setup deals a hidden order and the solver scores one point',
    () {
      final at = sampleUpdatedAt;
      var match = _accept(openFirstRound(_setup(), random: Random(1), at: at));

      expect(match.schemaVersion, MatchSnapshot.boardSchemaVersion);
      expect(match.phase, MatchPhase.roundIntroduction);
      expect(match.roundNumber, 1);
      expect(match.turnCycle, 1);
      expect(match.roundOrder.toSet(), {'maya', 'leo'});
      expect(match.wins, isEmpty);
      expect(match.board!.committed, isNot(match.board!.target));

      match = _accept(beginRound(match, at: at));
      expect(match.phase, MatchPhase.activeTurn);
      expect(requestWinner(match, at: at), isA<SessionRejected>());

      final winner = match.roundOrder[match.currentPlayerIndex!];
      match = _solveActive(match, at);
      expect(match.phase, MatchPhase.championship);
      expect(match.scores[winner], 1);
      expect(submitArrangement(match, at: at), isA<SessionRejected>());
      expect(match.wins.where((win) => !win.reversed), hasLength(1));
    },
  );

  test('the timer starts on ready and the next player does not inherit it', () {
    final at = sampleUpdatedAt;
    var match = _accept(
      openFirstRound(
        _setup(timer: TurnTimerDuration.seconds30),
        random: Random(1),
        at: at,
      ),
    );
    match = _accept(beginRound(match, at: at));
    expect(match.timer.isRunning, isFalse);

    match = _accept(markPlayerReady(match, at: at));
    expect(
      match.timer.remainingAt(at.add(const Duration(seconds: 10))),
      const Duration(seconds: 20),
    );
    final committed = match.board!.committed;
    match = _accept(moveBottle(match, from: 0, to: 1, at: at));

    match = _accept(skipTurn(match, at: at.add(const Duration(seconds: 10))));
    expect(match.phase, MatchPhase.playerHandoff);
    expect(match.timer.isRunning, isFalse);
    expect(match.wins, isEmpty);
    expect(match.currentPlayerIndex, 1);
    expect(match.board!.pending, committed);
    expect(match.board!.opening, committed);
    expect(
      expireTurn(match, at: at.add(const Duration(seconds: 10))),
      isA<SessionRejected>(),
    );
  });

  test('skip and a wrapped turn advance the cycle without a point', () {
    final at = sampleUpdatedAt;
    var match = _accept(openFirstRound(_setup(), random: Random(1), at: at));
    match = _accept(beginRound(match, at: at));
    match = _accept(skipTurn(match, at: at));
    expect(match.currentPlayerIndex, 1);
    expect(match.turnCycle, 1);

    match = _accept(skipTurn(match, at: at));
    expect(match.currentPlayerIndex, 0);
    expect(match.turnCycle, 2);
    expect(match.scores.values.every((score) => score == 0), isTrue);
  });

  test(
    'another player can pass the selected player without ending the match',
    () {
      final at = sampleUpdatedAt;
      var match = _accept(
        openFirstRound(
          _setup(
            settings: const MatchSettings(
              winRule: WinRule.selectedPlayerReachesTarget,
              selectedPlayerId: 'maya',
              targetRoundWins: 1,
              physicalEquipmentConfirmed: true,
            ),
          ),
          random: Random(1),
          at: at,
        ),
      );

      match = _solveAs(match, 'leo', at);
      expect(match.phase, MatchPhase.roundResult);
      expect(match.scores['leo'], 1);

      match = _accept(startNextRound(match, random: Random(2), at: at));
      match = _solveAs(match, 'maya', at);
      expect(match.phase, MatchPhase.championship);
      expect(match.scores['maya'], 1);
    },
  );

  test('correction removes the point and reopens confirmation', () {
    final at = sampleUpdatedAt;
    final match = sampleMatch(phase: MatchPhase.championship).copyWith(
      settings: const MatchSettings(
        targetRoundWins: 1,
        physicalEquipmentConfirmed: true,
      ),
      wins: const [RoundWin(roundNumber: 1, winnerId: 'maya')],
      roundNumber: 1,
    );

    final corrected = _accept(correctLastResult(match, at: at));
    expect(corrected.phase, MatchPhase.physicalResultConfirmation);
    expect(corrected.scores['maya'], 0);

    final confirmed = _accept(
      confirmWinner(corrected, winnerId: 'leo', at: at),
    );
    expect(confirmed.phase, MatchPhase.championship);
    expect(confirmed.scores['leo'], 1);
  });

  test('a judged round cannot be reassigned', () {
    final at = sampleUpdatedAt;
    var match = _accept(openFirstRound(_setup(), random: Random(1), at: at));
    match = _solveAs(match, match.roundOrder.first, at);

    expect(correctLastResult(match, at: at), isA<SessionRejected>());
    expect(match.scores[match.roundOrder.first], 1);
  });

  test('a correction that leaves two players at the target names nobody', () {
    final at = sampleUpdatedAt;
    final match = sampleMatch(phase: MatchPhase.championship).copyWith(
      settings: const MatchSettings(
        targetRoundWins: 1,
        physicalEquipmentConfirmed: true,
      ),
      wins: const [
        RoundWin(roundNumber: 1, winnerId: 'maya'),
        RoundWin(roundNumber: 2, winnerId: 'leo'),
        RoundWin(roundNumber: 3, winnerId: 'leo'),
      ],
    );

    final corrected = _accept(correctLastResult(match, at: at));

    expect(corrected.phase, MatchPhase.roundResult);
    expect(corrected.scores['maya'], 1);
    expect(corrected.scores['leo'], 1);
    expect(
      startNextRound(corrected, random: Random(1), at: at),
      isA<SessionRejected>(),
    );
  });

  test('abandon starts a new round and awards nothing', () {
    final at = sampleUpdatedAt;
    final opened = _accept(openFirstRound(_setup(), random: Random(1), at: at));
    final abandoned = _accept(abandonRound(opened, random: Random(2), at: at));

    expect(abandoned.phase, MatchPhase.roundIntroduction);
    expect(abandoned.roundNumber, 2);
    expect(abandoned.wins, isEmpty);
    expect(abandoned.roundOrder.toSet(), opened.roundOrder.toSet());
    expect(abandoned.board!.guesses, isEmpty);
    expect(abandoned.board!.target, isNot(opened.board!.target));
    expect(abandoned.board!.opening, abandoned.board!.committed);
    expect(
      [
        for (final bottle in abandoned.board!.opening)
          roundBottleLetter(abandoned.board!.labelOrder, bottle),
      ],
      ['A', 'B', 'C', 'D', 'E'],
    );
    final playing = _accept(beginRound(abandoned, at: at));
    final swapped = _accept(moveBottle(playing, from: 0, to: 1, at: at));
    expect(swapped.board!.opening, abandoned.board!.opening);
    expect(
      roundBottleLetter(swapped.board!.labelOrder, swapped.board!.pending[0]),
      'B',
    );
  });

  test('pause freezes the timer and resume continues the same turn', () {
    final at = sampleUpdatedAt;
    var match = _accept(
      openFirstRound(
        _setup(timer: TurnTimerDuration.seconds30),
        random: Random(1),
        at: at,
      ),
    );
    match = _accept(beginRound(match, at: at));
    match = _accept(markPlayerReady(match, at: at));
    final order = match.roundOrder;
    final target = match.board!.target;

    match = _accept(
      pauseSession(match, at: at.add(const Duration(seconds: 5))),
    );
    expect(match.phase, MatchPhase.paused);
    expect(match.resumePhase, MatchPhase.activeTurn);
    expect(match.timer.remaining, const Duration(seconds: 25));
    expect(match.roundOrder, order);
    expect(match.board!.target, target);

    match = _accept(
      resumeSession(match, at: at.add(const Duration(seconds: 5))),
    );
    expect(match.phase, MatchPhase.activeTurn);
    expect(
      match.timer.remainingAt(at.add(const Duration(seconds: 15))),
      const Duration(seconds: 15),
    );
  });

  test(
    'ending early is unfinished and play again only follows a championship',
    () {
      final at = sampleUpdatedAt;
      final opened = _accept(
        openFirstRound(_setup(), random: Random(1), at: at),
      );
      final ended = _accept(endEarly(opened, at: at));
      expect(ended.phase, MatchPhase.unfinishedMatch);
      expect(
        playAgain(ended, matchId: 'next', random: Random(1), at: at),
        isA<SessionRejected>(),
      );

      final won = _solveAs(opened, opened.roundOrder.first, at);
      final again = _accept(
        playAgain(won, matchId: 'next', random: Random(3), at: at),
      );
      expect(again.matchId, 'next');
      expect(again.phase, MatchPhase.roundIntroduction);
      expect(again.wins, isEmpty);
      expect(again.board!.guesses, isEmpty);
      expect(again.roster.map((player) => player.id), ['maya', 'leo']);
    },
  );

  test('a repeated order counts unless the match rejects it', () {
    final at = sampleUpdatedAt;
    var match = _accept(openFirstRound(_setup(), random: Random(1), at: at));
    match = _accept(beginRound(match, at: at));
    match = _accept(submitArrangement(match, at: at));

    expect(match.phase, MatchPhase.activeTurn);
    expect(match.board!.guesses, hasLength(1));
    expect(match.wins, isEmpty);

    match = _accept(submitArrangement(match, at: at));
    expect(match.phase, MatchPhase.activeTurn);
    expect(match.board!.guesses, hasLength(2));

    final rejecting = _accept(
      openFirstRound(
        _setup(
          settings: const MatchSettings(
            targetRoundWins: 1,
            physicalEquipmentConfirmed: true,
            rejectPreviousCombinations: true,
          ),
        ),
        random: Random(1),
        at: at,
      ),
    );
    var blocked = _accept(beginRound(rejecting, at: at));
    blocked = _accept(submitArrangement(blocked, at: at));
    expect(submitArrangement(blocked, at: at), isA<SessionRejected>());
    expect(blocked.board!.guesses, hasLength(1));
  });

  test('the timer discards an unsubmitted arrangement', () {
    final at = sampleUpdatedAt;
    var match = _accept(
      openFirstRound(
        _setup(timer: TurnTimerDuration.seconds30),
        random: Random(1),
        at: at,
      ),
    );
    match = _accept(beginRound(match, at: at));
    match = _accept(markPlayerReady(match, at: at));
    final committed = match.board!.committed;
    match = _accept(moveBottle(match, from: 0, to: 1, at: at));

    expect(
      expireTurn(match, at: at.add(const Duration(seconds: 10))),
      isA<SessionRejected>(),
    );
    match = _accept(expireTurn(match, at: at.add(const Duration(seconds: 30))));
    expect(match.phase, MatchPhase.playerHandoff);
    expect(match.board!.pending, committed);
    expect(match.board!.guesses, isEmpty);
    expect(match.wins, isEmpty);
  });

  test('one hint is available after three full turns and does not score', () {
    final at = sampleUpdatedAt;
    var match = _accept(openFirstRound(_setup(), random: Random(1), at: at));
    match = _accept(beginRound(match, at: at));
    expect(takeHint(match, random: Random(1), at: at), isA<SessionRejected>());

    match = _accept(pauseSession(match, at: at));
    expect(takeHint(match, random: Random(1), at: at), isA<SessionRejected>());
    match = _accept(resumeSession(match, at: at));
    while (match.turnCycle < bottleHintCycle) {
      match = _accept(skipTurn(match, at: at));
    }
    final pending = match.board!.pending;
    match = _accept(pauseSession(match, at: at));
    match = _accept(takeHint(match, random: Random(4), at: at));
    final hint = match.board!.hint!;
    expect(hint.bottle, match.board!.target[hint.position]);
    expect(match.board!.pending, pending);
    expect(match.scores.values.every((score) => score == 0), isTrue);
    expect(takeHint(match, random: Random(4), at: at), isA<SessionRejected>());
  });

  test('practice uses a throwaway order and the real round replaces it', () {
    final at = sampleUpdatedAt;
    var match = _accept(openPractice(_setup(), random: Random(1), at: at));
    expect(match.board!.practice, isTrue);

    match = _solveAs(match, match.roundOrder.first, at);
    expect(match.phase, MatchPhase.roundResult);
    expect(match.wins, isEmpty);
    expect(match.board!.practice, isTrue);

    match = _accept(finishPractice(match, random: Random(2), at: at));
    expect(match.phase, MatchPhase.roundIntroduction);
    expect(match.roundNumber, 1);
    expect(match.board!.practice, isFalse);
    expect(match.board!.guesses, isEmpty);
    expect(match.wins, isEmpty);
  });

  test('linear keeps the roster through the next round', () {
    final at = sampleUpdatedAt;
    var match = _accept(
      openFirstRound(
        _setup(
          settings: const MatchSettings(
            targetRoundWins: 2,
            physicalEquipmentConfirmed: true,
            turnOrder: TurnOrder.linear,
          ),
        ),
        random: Random(1),
        at: at,
      ),
    );

    expect(match.roundOrder, ['maya', 'leo']);
    match = _solveAs(match, 'maya', at);
    match = _accept(startNextRound(match, random: Random(9), at: at));
    expect(match.roundNumber, 2);
    expect(match.roundOrder, ['maya', 'leo']);
  });

  test('a saved manual match can still record a winner', () {
    final at = sampleUpdatedAt;
    var match = sampleMatch();
    final winner = match.roundOrder[match.currentPlayerIndex!];
    match = _accept(requestWinner(match, at: at));
    match = _accept(confirmWinner(match, winnerId: winner, at: at));

    expect(match.board, isNull);
    expect(match.phase, MatchPhase.roundResult);
    expect(match.scores[winner], 1);
  });
}

MatchSnapshot _setup({
  TurnTimerDuration timer = TurnTimerDuration.off,
  MatchSettings? settings,
}) {
  return MatchSnapshot(
    matchId: 'match-1',
    mode: GameMode.physicalCompanion,
    settings:
        settings ??
        MatchSettings(
          targetRoundWins: 1,
          physicalEquipmentConfirmed: true,
          timer: timer,
        ),
    roster: const [maya, leo],
    updatedAt: sampleUpdatedAt,
  );
}

MatchSnapshot _solveAs(MatchSnapshot match, String winnerId, DateTime at) {
  var next = match;
  if (next.phase == MatchPhase.roundIntroduction) {
    next = _accept(beginRound(next, at: at));
  }
  var guard = 0;
  while (next.roundOrder[next.currentPlayerIndex!] != winnerId && guard < 12) {
    next = _accept(skipTurn(next, at: at));
    guard++;
  }
  expect(next.roundOrder[next.currentPlayerIndex!], winnerId);
  if (next.phase == MatchPhase.playerHandoff) {
    next = _accept(markPlayerReady(next, at: at));
  }
  return _solveActive(next, at);
}

MatchSnapshot _solveActive(MatchSnapshot match, DateTime at) {
  var next = match;
  final target = next.board!.target;
  for (var index = 0; index < target.length; index++) {
    final from = next.board!.pending.indexOf(target[index]);
    if (from == index) {
      continue;
    }
    next = _accept(moveBottle(next, from: from, to: index, at: at));
  }
  return _accept(submitArrangement(next, at: at));
}

MatchSnapshot _accept(SessionResult result) {
  expect(result, isA<SessionAccepted>());
  return (result as SessionAccepted).snapshot;
}
