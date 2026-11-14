import 'package:hive_ce/hive_ce.dart';

import '../../domain/errors/app_failure.dart';
import '../../domain/models/match_snapshot.dart';
import '../../domain/repositories/match_repository.dart';
import '../serialization/snapshot_codec.dart';

/// Stores the active match in one Hive box.
///
/// The previous document is copied to a backup key before the new document is
/// written. A corrupt primary document falls back to that backup. A schema
/// mismatch does not fall back, because an older backup is a different match
/// version and should not be presented as the current save.
///
/// Hive CE uses the file system on mobile and IndexedDB in the browser.
class HiveMatchRepository implements MatchRepository {
  HiveMatchRepository(this._box);

  static const boxName = 'active_match';
  static const primaryKey = 'primary';
  static const backupKey = 'backup';

  final Box<String> _box;

  @override
  Future<MatchSnapshot?> readActive() async {
    final primary = _box.get(primaryKey);
    if (primary == null) {
      return _readBackup(required: false);
    }
    try {
      return SnapshotCodec.decode(primary);
    } on SchemaMismatchFailure {
      rethrow;
    } on FormatException {
      return _readBackup(required: true);
    } on TypeError {
      return _readBackup(required: true);
    }
  }

  @override
  Future<void> save(MatchSnapshot snapshot) async {
    final current = _box.get(primaryKey);
    if (current != null) {
      await _box.put(backupKey, current);
    }
    await _box.put(primaryKey, SnapshotCodec.encode(snapshot));
    await _box.flush();
  }

  @override
  Future<void> clear() async {
    await _box.delete(primaryKey);
    await _box.delete(backupKey);
    await _box.flush();
  }

  Future<MatchSnapshot?> _readBackup({required bool required}) async {
    final backup = _box.get(backupKey);
    if (backup == null) {
      if (required) {
        throw const PersistenceFailure(
          'The saved match could not be read, and no backup is available.',
        );
      }
      return null;
    }
    try {
      return SnapshotCodec.decode(backup);
    } on SchemaMismatchFailure {
      rethrow;
    } on FormatException {
      throw const PersistenceFailure(
        'The saved match and its backup could not be read.',
      );
    }
  }
}
