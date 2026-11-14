import 'package:flutter_bottle_match/data/serialization/snapshot_codec.dart';
import 'package:flutter_bottle_match/domain/errors/app_failure.dart';
import 'package:flutter_bottle_match/domain/models/bottle_board.dart';
import 'package:flutter_bottle_match/domain/models/match_phase.dart';
import 'package:flutter_bottle_match/domain/models/match_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/match_fixtures.dart';

void main() {
  test('a snapshot round-trips without changing order or phase', () {
    final paused = sampleMatch(
      phase: MatchPhase.paused,
      resumePhase: MatchPhase.activeTurn,
    );
    final restored = SnapshotCodec.decode(SnapshotCodec.encode(paused));

    expect(restored.schemaVersion, 1);
    expect(restored.roundOrder, paused.roundOrder);
    expect(restored.phase, MatchPhase.paused);
    expect(restored.resumePhase, MatchPhase.activeTurn);
    expect(restored.roster.map((player) => player.id), ['maya', 'leo']);
    expect(restored.timer.duration.name, paused.timer.duration.name);
  });

  test('an unknown schema version is rejected', () {
    final raw = SnapshotCodec.encode(
      sampleMatch(),
    ).replaceFirst('"schemaVersion":1', '"schemaVersion":9');

    expect(
      () => SnapshotCodec.decode(raw),
      throwsA(isA<SchemaMismatchFailure>()),
    );
  });

  test('schema 2 keeps the hidden order and rejects a board-less document', () {
    const board = BottleBoard(
      target: [0, 1, 2, 3, 4],
      committed: [1, 0, 2, 3, 4],
      pending: [1, 0, 2, 4, 3],
      guesses: [
        BottleGuess(arrangement: [1, 0, 2, 3, 4], correct: 3),
      ],
    );
    final saved = sampleMatch().copyWith(
      schemaVersion: MatchSnapshot.boardSchemaVersion,
      board: board,
      replaceBoard: true,
    );
    final restored = SnapshotCodec.decode(SnapshotCodec.encode(saved));

    expect(restored.schemaVersion, 2);
    expect(restored.board!.target, board.target);
    expect(restored.board!.pending, board.pending);
    expect(restored.board!.guesses.single.correct, 3);

    final raw = SnapshotCodec.encode(
      sampleMatch(),
    ).replaceFirst('"schemaVersion":1', '"schemaVersion":2');
    expect(() => SnapshotCodec.decode(raw), throwsFormatException);
  });

  test('a paused save without a resume phase is rejected', () {
    final raw = SnapshotCodec.encode(
      sampleMatch(phase: MatchPhase.activeTurn),
    ).replaceFirst('"phase":"activeTurn"', '"phase":"paused"');

    expect(() => SnapshotCodec.decode(raw), throwsFormatException);
  });
}
