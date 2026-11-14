import 'dart:math';

import 'package:flutter_bottle_match/domain/models/configuration.dart';
import 'package:flutter_bottle_match/domain/models/match_phase.dart';
import 'package:flutter_bottle_match/domain/models/match_snapshot.dart';
import 'package:flutter_bottle_match/domain/models/round_win.dart';
import 'package:flutter_bottle_match/domain/rules/physical_session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/match_fixtures.dart';

void main() {
  test(
    'a valid setup opens a full shuffled round and can record one point',
    () {
      final at = sampleUpdatedAt;
      var match = _accept(openFirstRound(_setup(), random: Random(1), at: at));

      expect(match.phase, MatchPhase.roundIntroduction);
      expect(match.roundNumber, 1);
      expect(match.turnCycle, 1);
      expect(match.roundOrder.toSet(), {'maya', 'leo'});
      expect(match.wins, isEmpty);

      match = _accept(beginRound(match, at: at));
      match = _accept(markPlayerReady(match, at: at));
      final winner = match.roundOrder[match.currentPlayerIndex!];
      match = _accept(requestWinner(match, at: at));
      match = _accept(confirmWinner(match, winnerId: winner, at: at));

      expect(match.phase, MatchPhase.championship);
      expect(match.scores[winner], 1);
      expect(
        confirmWinner(match, winnerId: winner, at: at),
        isA<SessionRejected>(),
      );
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

    match = _accept(
      advancePlayer(match, at: at.add(const Duration(seconds: 10))),
    );
    expect(match.phase, MatchPhase.playerHandoff);
    expect(match.timer.isRunning, isFalse);
    expect(match.wins, isEmpty);
    expect(match.currentPlayerIndex, 1);
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

      match = _playWinner(match, 'leo', at);
      expect(match.phase, MatchPhase.roundResult);
      expect(match.scores['leo'], 1);

      match = _accept(startNextRound(match, random: Random(2), at: at));
      match = _playWinner(match, 'maya', at);
      expect(match.phase, MatchPhase.championship);
      expect(match.scores['maya'], 1);
    },
  );

  test('correction removes the point and reopens confirmation', () {
    final at = sampleUpdatedAt;
    var match = _accept(openFirstRound(_setup(), random: Random(1), at: at));
    final winner = match.roundOrder.first;
    match = _playWinner(match, winner, at);
    expect(match.phase, MatchPhase.championship);

    match = _accept(correctLastResult(match, at: at));
    expect(match.phase, MatchPhase.physicalResultConfirmation);
    expect(match.scores[winner], 0);

    final other = match.roster.firstWhere((player) => player.id != winner).id;
    match = _accept(confirmWinner(match, winnerId: other, at: at));
    expect(match.phase, MatchPhase.championship);
    expect(match.scores[other], 1);
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

    match = _accept(
      pauseSession(match, at: at.add(const Duration(seconds: 5))),
    );
    expect(match.phase, MatchPhase.paused);
    expect(match.resumePhase, MatchPhase.activeTurn);
    expect(match.timer.remaining, const Duration(seconds: 25));
    expect(match.roundOrder, order);

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

      final won = _playWinner(opened, opened.roundOrder.first, at);
      final again = _accept(
        playAgain(won, matchId: 'next', random: Random(3), at: at),
      );
      expect(again.matchId, 'next');
      expect(again.phase, MatchPhase.roundIntroduction);
      expect(again.wins, isEmpty);
      expect(again.roster.map((player) => player.id), ['maya', 'leo']);
    },
  );
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

MatchSnapshot _playWinner(MatchSnapshot match, String winnerId, DateTime at) {
  var next = _accept(beginRound(match, at: at));
  next = _accept(markPlayerReady(next, at: at));
  next = _accept(requestWinner(next, at: at));
  return _accept(confirmWinner(next, winnerId: winnerId, at: at));
}

MatchSnapshot _accept(SessionResult result) {
  expect(result, isA<SessionAccepted>());
  return (result as SessionAccepted).snapshot;
}
