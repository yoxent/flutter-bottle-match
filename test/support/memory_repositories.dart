import 'package:flutter_bottle_match/domain/models/app_settings.dart';
import 'package:flutter_bottle_match/domain/models/match_snapshot.dart';
import 'package:flutter_bottle_match/domain/repositories/match_repository.dart';
import 'package:flutter_bottle_match/domain/repositories/settings_repository.dart';

class MemoryMatchRepository implements MatchRepository {
  MatchSnapshot? active;
  var saves = 0;

  @override
  Future<void> clear() async {
    active = null;
  }

  @override
  Future<MatchSnapshot?> readActive() async => active;

  @override
  Future<void> save(MatchSnapshot snapshot) async {
    active = snapshot;
    saves += 1;
  }
}

class MemorySettingsRepository implements SettingsRepository {
  AppSettings value = const AppSettings();
  var failNextSave = false;

  @override
  Future<AppSettings> read() async => value;

  @override
  Future<void> save(AppSettings settings) async {
    if (failNextSave) {
      failNextSave = false;
      throw StateError('disk full');
    }
    value = settings;
  }
}
