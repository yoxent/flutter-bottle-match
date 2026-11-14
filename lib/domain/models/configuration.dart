import '../rules/match_constraints.dart';
import '../serialization/json_object.dart';

/// How the group is playing this match.
///
/// Fully Digital is a Release 2 mode. Its puzzle rules are proposed and are
/// not implemented in this foundation.
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

  /// Physical Companion cannot start until the group confirms it has pieces.
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
