import '../models/player.dart';
import 'match_constraints.dart';

/// Blank input becomes "Player N". Longer names stay unchanged for validation.
String normalizePlayerName(String raw, int playerNumber) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return 'Player $playerNumber';
  }
  return trimmed;
}

/// Numbers every copy when a name is shared, including the first copy.
///
/// "Maya" and "Maya" become "Maya 1" and "Maya 2". The GDD requires a visible
/// distinguishing number and does not say whether the first copy is numbered.
List<String> visiblePlayerNames(List<Player> players) {
  final counts = <String, int>{};
  for (final player in players) {
    counts[player.name] = (counts[player.name] ?? 0) + 1;
  }
  final seen = <String, int>{};
  final names = <String>[];
  for (final player in players) {
    if ((counts[player.name] ?? 0) < 2) {
      names.add(player.name);
      continue;
    }
    final next = (seen[player.name] ?? 0) + 1;
    seen[player.name] = next;
    names.add('${player.name} $next');
  }
  return names;
}

bool isPlayerNameLengthValid(String name) {
  final trimmed = name.trim();
  return trimmed.isNotEmpty && trimmed.length <= MatchConstraints.maxNameLength;
}
