import '../errors/app_failure.dart';
import '../rules/phase_transition.dart';
import '../rules/scorebook.dart';
import '../serialization/json_object.dart';
import 'configuration.dart';
import 'match_phase.dart';
import 'player.dart';
import 'round_win.dart';
import 'turn_clock.dart';

/// Versioned, serializable match session.
///
/// Scores are derived from [wins] so a save cannot disagree with the ledger.
/// Digital bottle-board state is not stored here. Adding it will be a new
/// schema version rather than a silent change to version 1.
class MatchSnapshot {
  const MatchSnapshot({
    required this.matchId,
    required this.mode,
    required this.settings,
    required this.roster,
    required this.updatedAt,
    this.schemaVersion = currentSchemaVersion,
    this.roundNumber = 0,
    this.roundOrder = const [],
    this.turnCycle = 0,
    this.currentPlayerIndex,
    this.phase = MatchPhase.setup,
    this.resumePhase,
    this.wins = const [],
    this.timer = const TurnClock(),
  });

  static const currentSchemaVersion = 1;

  final int schemaVersion;
  final String matchId;
  final GameMode mode;
  final MatchSettings settings;
  final List<Player> roster;
  final int roundNumber;
  final List<String> roundOrder;
  final int turnCycle;
  final int? currentPlayerIndex;
  final MatchPhase phase;
  final MatchPhase? resumePhase;
  final List<RoundWin> wins;
  final TurnClock timer;
  final DateTime updatedAt;

  Scorebook get scorebook => Scorebook(wins);

  Map<String, int> get scores =>
      scorebook.scoresFor(roster.map((player) => player.id));

  bool get replacesWithoutConfirmation => phase == MatchPhase.championship;

  MatchSnapshot copyWith({
    GameMode? mode,
    MatchSettings? settings,
    List<Player>? roster,
    int? roundNumber,
    List<String>? roundOrder,
    int? turnCycle,
    int? currentPlayerIndex,
    bool clearCurrentPlayer = false,
    MatchPhase? phase,
    MatchPhase? resumePhase,
    bool clearResumePhase = false,
    List<RoundWin>? wins,
    TurnClock? timer,
    DateTime? updatedAt,
  }) {
    return MatchSnapshot(
      schemaVersion: schemaVersion,
      matchId: matchId,
      mode: mode ?? this.mode,
      settings: settings ?? this.settings,
      roster: roster ?? this.roster,
      roundNumber: roundNumber ?? this.roundNumber,
      roundOrder: roundOrder ?? this.roundOrder,
      turnCycle: turnCycle ?? this.turnCycle,
      currentPlayerIndex: clearCurrentPlayer
          ? null
          : (currentPlayerIndex ?? this.currentPlayerIndex),
      phase: phase ?? this.phase,
      resumePhase: clearResumePhase ? null : (resumePhase ?? this.resumePhase),
      wins: wins ?? this.wins,
      timer: timer ?? this.timer,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Applies a legal transition. A rejected event returns null and does not
  /// change the snapshot, so a repeated tap cannot advance the phase twice.
  MatchSnapshot? apply(MatchEvent event, {required DateTime at}) {
    final result = transition(
      phase: phase,
      resumePhase: resumePhase,
      event: event,
    );
    if (result is! TransitionAccepted) {
      return null;
    }
    return copyWith(
      phase: result.change.phase,
      resumePhase: result.change.resumePhase,
      clearResumePhase: result.change.resumePhase == null,
      updatedAt: at,
    );
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'matchId': matchId,
    'mode': mode.name,
    'settings': settings.toJson(),
    'roster': roster.map((player) => player.toJson()).toList(),
    'roundNumber': roundNumber,
    'roundOrder': roundOrder,
    'turnCycle': turnCycle,
    'currentPlayerIndex': currentPlayerIndex,
    'phase': phase.name,
    'resumePhase': resumePhase?.name,
    'wins': wins.map((win) => win.toJson()).toList(),
    'timer': timer.toJson(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  factory MatchSnapshot.fromJson(Map<String, Object?> json) {
    final object = JsonObject(json);
    final version = object.integer('schemaVersion');
    if (version != currentSchemaVersion) {
      throw SchemaMismatchFailure(version);
    }

    final phase = enumByName(
      MatchPhase.values,
      object.string('phase'),
      'phase',
    );
    final resumeName = object.optionalString('resumePhase');
    final resumePhase = resumeName == null
        ? null
        : enumByName(MatchPhase.values, resumeName, 'resumePhase');
    _validatePausePair(phase, resumePhase);

    return MatchSnapshot(
      schemaVersion: version,
      matchId: object.string('matchId'),
      mode: enumByName(GameMode.values, object.string('mode'), 'mode'),
      settings: MatchSettings.fromJson(object.object('settings').asMap()),
      roster: [
        for (final player in object.objectList('roster'))
          Player.fromJson(player.asMap()),
      ],
      roundNumber: object.integer('roundNumber'),
      roundOrder: object.stringList('roundOrder'),
      turnCycle: object.integer('turnCycle'),
      currentPlayerIndex: object.optionalInt('currentPlayerIndex'),
      phase: phase,
      resumePhase: resumePhase,
      wins: [
        for (final win in object.objectList('wins'))
          RoundWin.fromJson(win.asMap()),
      ],
      timer: TurnClock.fromJson(object.object('timer').asMap()),
      updatedAt: DateTime.parse(object.string('updatedAt')).toUtc(),
    );
  }
}

void _validatePausePair(MatchPhase phase, MatchPhase? resumePhase) {
  if (phase == MatchPhase.paused) {
    if (resumePhase == null || resumePhase == MatchPhase.paused) {
      throw const FormatException('A paused match must remember its phase.');
    }
    return;
  }
  if (resumePhase != null) {
    throw const FormatException(
      'Only a paused match can store a resume phase.',
    );
  }
}
