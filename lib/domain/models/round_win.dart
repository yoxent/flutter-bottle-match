import '../serialization/json_object.dart';

/// One confirmed round win. A reversed entry no longer contributes a point.
class RoundWin {
  const RoundWin({
    required this.roundNumber,
    required this.winnerId,
    this.reversed = false,
  });

  final int roundNumber;
  final String winnerId;
  final bool reversed;

  Map<String, Object?> toJson() => {
    'roundNumber': roundNumber,
    'winnerId': winnerId,
    'reversed': reversed,
  };

  factory RoundWin.fromJson(Map<String, Object?> json) {
    final object = JsonObject(json);
    return RoundWin(
      roundNumber: object.integer('roundNumber'),
      winnerId: object.string('winnerId'),
      reversed: object.boolean('reversed'),
    );
  }
}
