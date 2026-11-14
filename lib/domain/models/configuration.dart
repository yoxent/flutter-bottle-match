import '../rules/match_constraints.dart';
import '../serialization/json_object.dart';

/// How a saved match was started.
///
/// New matches are [fullyDigital]. [physicalCompanion] remains so a version 1
/// snapshot can still be read. The app no longer offers that mode.
enum GameMode { physicalCompanion, fullyDigital }

/// The two confirmed ways a match can end.
enum WinRule {
  /// Any player who reaches the target becomes champion.
  firstToTarget,

  /// Only the selected player reaching the target ends the match.
  selectedPlayerReachesTarget,
}

/// Optional turn timer. Off is the default.
enum TurnTimerDuration {
  off,
  seconds30,
  seconds60,
  seconds90;

  Duration? get limit => switch (this) {
    TurnTimerDuration.off => null,
    TurnTimerDuration.seconds30 => const Duration(seconds: 30),
    TurnTimerDuration.seconds60 => const Duration(seconds: 60),
    TurnTimerDuration.seconds90 => const Duration(seconds: 90),
  };
}

/// Locked match rules. Names and avatars can change later; these cannot.
class MatchSettings {
  const MatchSettings({
    this.winRule = WinRule.firstToTarget,
    this.targetRoundWins = MatchConstraints.defaultTarget,
    this.selectedPlayerId,
    this.bottleCount = MatchConstraints.defaultBottles,
    this.timer = TurnTimerDuration.off,
    this.physicalEquipmentConfirmed = false,
  });

  final WinRule winRule;
  final int targetRoundWins;
  final String? selectedPlayerId;
  final int bottleCount;
  final TurnTimerDuration timer;

  /// Kept on the version 1 snapshot. Play starts the match, so this value
  /// does not decide whether setup is valid.
  final bool physicalEquipmentConfirmed;

  Map<String, Object?> toJson() => {
    'winRule': winRule.name,
    'targetRoundWins': targetRoundWins,
    'selectedPlayerId': selectedPlayerId,
    'bottleCount': bottleCount,
    'timer': timer.name,
    'physicalEquipmentConfirmed': physicalEquipmentConfirmed,
  };

  factory MatchSettings.fromJson(Map<String, Object?> json) {
    final object = JsonObject(json);
    return MatchSettings(
      winRule: enumByName(WinRule.values, object.string('winRule'), 'winRule'),
      targetRoundWins: object.integer('targetRoundWins'),
      selectedPlayerId: object.optionalString('selectedPlayerId'),
      bottleCount: object.integer('bottleCount'),
      timer: enumByName(
        TurnTimerDuration.values,
        object.string('timer'),
        'timer',
      ),
      physicalEquipmentConfirmed: object.boolean('physicalEquipmentConfirmed'),
    );
  }
}
