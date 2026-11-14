import 'dart:io';

import 'package:flutter_bottle_match/data/repositories/hive_match_repository.dart';
import 'package:flutter_bottle_match/data/serialization/snapshot_codec.dart';
import 'package:flutter_bottle_match/domain/errors/app_failure.dart';
import 'package:flutter_bottle_match/domain/models/match_phase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

import '../support/match_fixtures.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('bottle_match_hive_');
    Hive.init(directory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  });

  test('a saved match is read back after the box is reopened', () async {
    final box = await Hive.openBox<String>(HiveMatchRepository.boxName);
    final repository = HiveMatchRepository(box);
    await repository.save(sampleMatch());
    await box.close();

    final reopened = await Hive.openBox<String>(HiveMatchRepository.boxName);
    final loaded = await HiveMatchRepository(reopened).readActive();

    expect(loaded!.matchId, 'match-1');
    expect(loaded.roundOrder, ['maya', 'leo']);
  });

  test('a corrupt primary document falls back to the backup', () async {
    final box = await Hive.openBox<String>(HiveMatchRepository.boxName);
    final repository = HiveMatchRepository(box);
    await repository.save(sampleMatch(phase: MatchPhase.setup));
    await repository.save(sampleMatch());
    await box.put(HiveMatchRepository.primaryKey, '{not json');

    final loaded = await repository.readActive();

    expect(loaded!.phase, MatchPhase.setup);
  });

  test('a schema mismatch does not silently load the backup', () async {
    final box = await Hive.openBox<String>(HiveMatchRepository.boxName);
    final repository = HiveMatchRepository(box);
    await repository.save(sampleMatch());
    final mismatched = SnapshotCodec.encode(
      sampleMatch(),
    ).replaceFirst('"schemaVersion":1', '"schemaVersion":9');
    await box.put(HiveMatchRepository.primaryKey, mismatched);

    expect(repository.readActive(), throwsA(isA<SchemaMismatchFailure>()));
  });
}
