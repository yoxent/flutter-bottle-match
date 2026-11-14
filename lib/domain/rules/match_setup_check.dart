import '../models/configuration.dart';
import '../models/player.dart';
import 'match_constraints.dart';
import 'player_names.dart';

/// Why Play is or is not available. Issues are for the setup UI.
class MatchSetupCheck {
  const MatchSetupCheck(this.issues);

  final List<String> issues;

  bool get isValid => issues.isEmpty;

  factory MatchSetupCheck.evaluate({
    required List<Player> roster,
    required MatchSettings settings,
  }) {
    final issues = <String>[];
    if (roster.length < MatchConstraints.minPlayers ||
        roster.length > MatchConstraints.maxPlayers) {
      issues.add('Choose 2 to 12 players.');
    }

    final ids = roster.map((player) => player.id).toSet();
    if (ids.length != roster.length || ids.any((id) => id.trim().isEmpty)) {
      issues.add('Each player needs a stable id.');
    }

    if (roster.any((player) => !isPlayerNameLengthValid(player.name))) {
      issues.add('Player names must be 1 to 20 characters.');
    }

    if (settings.bottleCount < MatchConstraints.minBottles ||
        settings.bottleCount > MatchConstraints.maxBottles) {
      issues.add('Choose 5 to 15 bottles.');
    }

    if (settings.targetRoundWins < MatchConstraints.minTarget ||
        settings.targetRoundWins > MatchConstraints.maxTarget) {
      issues.add('Choose a target from 1 to 20 round wins.');
    }

    if (settings.winRule == WinRule.selectedPlayerReachesTarget &&
        (settings.selectedPlayerId == null ||
            !ids.contains(settings.selectedPlayerId))) {
      issues.add('Selected-player mode requires a player from the roster.');
    }

    return MatchSetupCheck(issues);
  }
}
