import 'package:flutter_bottle_match/domain/models/configuration.dart';
import 'package:flutter_bottle_match/domain/models/match_phase.dart';
import 'package:flutter_bottle_match/domain/rules/phase_transition.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/match_fixtures.dart';

void main() {
  test('physical play can reach a result and then pause back to it', () {
    final at = sampleUpdatedAt;
    var match = sampleMatch(phase: MatchPhase.setup);

    match = match.apply(MatchEvent.startMatch, at: at)!;
    match = match.apply(MatchEvent.beginRound, at: at)!;
    match = match.apply(MatchEvent.playerReady, at: at)!;
    expect(match.apply(MatchEvent.confirmPhysicalResult, at: at), isNull);
    match = match.apply(MatchEvent.requestPhysicalResult, at: at)!;
    match = match.apply(MatchEvent.confirmPhysicalResult, at: at)!;
    expect(match.phase, MatchPhase.roundResult);
    expect(canCorrectPhysicalResult(match.phase), isTrue);

    final paused = match.apply(MatchEvent.pause, at: at)!;
    expect(paused.phase, MatchPhase.paused);
    expect(paused.resumePhase, MatchPhase.roundResult);
    expect(paused.apply(MatchEvent.pause, at: at), isNull);
    expect(paused.roundOrder, match.roundOrder);

    final resumed = paused.apply(MatchEvent.resume, at: at)!;
    expect(resumed.phase, MatchPhase.roundResult);
    expect(resumed.resumePhase, isNull);
  });

  test('digital mode cannot record a physical result', () {
    final match = sampleMatch(mode: GameMode.fullyDigital);
    expect(
      match.apply(MatchEvent.requestPhysicalResult, at: sampleUpdatedAt),
      isNull,
    );
  });

  test('ending early is unfinished and is not a championship', () {
    final ended = sampleMatch().apply(
      MatchEvent.endUnfinished,
      at: sampleUpdatedAt,
    )!;

    expect(ended.phase, MatchPhase.unfinishedMatch);
    expect(
      ended.apply(MatchEvent.declareChampion, at: sampleUpdatedAt),
      isNull,
    );
  });
}
