import 'package:flutter_bottle_match/domain/models/configuration.dart';
import 'package:flutter_bottle_match/domain/models/match_phase.dart';
import 'package:flutter_bottle_match/domain/models/match_snapshot.dart';
import 'package:flutter_bottle_match/domain/models/player.dart';
import 'package:flutter_bottle_match/domain/models/turn_clock.dart';

const maya = Player(id: 'maya', name: 'Maya', avatarIndex: 0);
const leo = Player(id: 'leo', name: 'Leo', avatarIndex: 1);

final sampleUpdatedAt = DateTime.utc(2026, 11, 14, 6);

MatchSnapshot sampleMatch({
  MatchPhase phase = MatchPhase.activeTurn,
  MatchPhase? resumePhase,
  List<String> roundOrder = const ['maya', 'leo'],
  TurnClock timer = const TurnClock(),
  GameMode mode = GameMode.physicalCompanion,
  List<Player> roster = const [maya, leo],
}) {
  return MatchSnapshot(
    matchId: 'match-1',
    mode: mode,
    settings: const MatchSettings(
      physicalEquipmentConfirmed: true,
      bottleCount: 8,
    ),
    roster: roster,
    roundNumber: 2,
    roundOrder: roundOrder,
    turnCycle: 1,
    currentPlayerIndex: 0,
    phase: phase,
    resumePhase: resumePhase,
    timer: timer,
    updatedAt: sampleUpdatedAt,
  );
}
