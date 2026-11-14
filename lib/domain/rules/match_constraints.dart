/// Confirmed numeric limits from the GDD. Difficulty does not change scoring.
abstract final class MatchConstraints {
  static const minPlayers = 2;
  static const maxPlayers = 12;
  static const minBottles = 5;
  static const maxBottles = 15;
  static const minTarget = 1;
  static const maxTarget = 20;
  static const defaultTarget = 3;
  static const defaultBottles = 5;
  static const maxNameLength = 20;
  static const roundWinPoints = 1;
}

/// Suggested bottle-count labels. They do not change feedback, timer, or points.
String bottleDifficultyLabel(int bottleCount) {
  if (bottleCount >= 5 && bottleCount <= 6) {
    return 'Easy';
  }
  if (bottleCount >= 7 && bottleCount <= 9) {
    return 'Medium';
  }
  if (bottleCount >= 10 && bottleCount <= 12) {
    return 'Hard';
  }
  if (bottleCount >= 13 && bottleCount <= 15) {
    return 'Expert';
  }
  return 'Outside the supported range';
}
