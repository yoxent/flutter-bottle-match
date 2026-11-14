import 'package:flutter_bottle_match/data/serialization/snapshot_codec.dart';
import 'package:flutter_bottle_match/domain/errors/app_failure.dart';
import 'package:flutter_bottle_match/domain/models/match_phase.dart';
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
    ).replaceFirst('"schemaVersion":1', '"schemaVersion":2');

    expect(
      () => SnapshotCodec.decode(raw),
      throwsA(isA<SchemaMismatchFailure>()),
    );
  });

  test('a paused save without a resume phase is rejected', () {
    final raw = SnapshotCodec.encode(
      sampleMatch(phase: MatchPhase.activeTurn),
    ).replaceFirst('"phase":"activeTurn"', '"phase":"paused"');

    expect(() => SnapshotCodec.decode(raw), throwsFormatException);
  });
}
