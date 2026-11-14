import '../serialization/json_object.dart';

/// One accepted guess. The arrangement is the order that was checked.
class BottleGuess {
  const BottleGuess({required this.arrangement, required this.correct});

  final List<int> arrangement;
  final int correct;

  Map<String, Object?> toJson() => {
    'arrangement': arrangement,
    'correct': correct,
  };

  factory BottleGuess.fromJson(Map<String, Object?> json) {
    final object = JsonObject(json);
    return BottleGuess(
      arrangement: _intList(object, 'arrangement'),
      correct: object.integer('correct'),
    );
  }
}

/// One revealed identity-position pair. It does not move a bottle.
class BottleHint {
  const BottleHint({required this.position, required this.bottle});

  final int position;
  final int bottle;

  Map<String, Object?> toJson() => {'position': position, 'bottle': bottle};

  factory BottleHint.fromJson(Map<String, Object?> json) {
    final object = JsonObject(json);
    return BottleHint(
      position: object.integer('position'),
      bottle: object.integer('bottle'),
    );
  }
}

/// The hidden order and the arrangements players can see.
///
/// [target] stays concealed until a round is solved. [committed] is the last
/// submitted order, or the starting order before the first guess. [pending]
/// is the order being edited on the active turn.
class BottleBoard {
  const BottleBoard({
    required this.target,
    required this.committed,
    required this.pending,
    this.opening = const [],
    this.guesses = const [],
    this.hint,
    this.practice = false,
  });

  final List<int> target;
  final List<int> committed;
  final List<int> pending;

  /// The order first shown this round. Letters A, B, C are assigned from it.
  /// An empty list is an older save, whose letters stay tied to bottle identity.
  final List<int> opening;
  final List<BottleGuess> guesses;
  final BottleHint? hint;
  final bool practice;

  /// Positions that own this round's letters. Missing history uses identity.
  List<int> get labelOrder {
    if (opening.length == target.length) {
      return opening;
    }
    return [for (var index = 0; index < target.length; index++) index];
  }

  BottleBoard copyWith({
    List<int>? committed,
    List<int>? pending,
    List<BottleGuess>? guesses,
    BottleHint? hint,
    bool clearHint = false,
    bool? practice,
  }) {
    return BottleBoard(
      target: target,
      committed: committed ?? this.committed,
      pending: pending ?? this.pending,
      opening: opening,
      guesses: guesses ?? this.guesses,
      hint: clearHint ? null : (hint ?? this.hint),
      practice: practice ?? this.practice,
    );
  }

  Map<String, Object?> toJson() => {
    'target': target,
    'committed': committed,
    'pending': pending,
    'opening': opening,
    'guesses': guesses.map((guess) => guess.toJson()).toList(),
    'hint': hint?.toJson(),
    'practice': practice,
  };

  factory BottleBoard.fromJson(Map<String, Object?> json) {
    final object = JsonObject(json);
    final hint = object.asMap()['hint'];
    final saved = object.asMap();
    return BottleBoard(
      target: _intList(object, 'target'),
      committed: _intList(object, 'committed'),
      pending: _intList(object, 'pending'),
      opening: saved.containsKey('opening')
          ? _intList(object, 'opening')
          : const [],
      guesses: [
        for (final guess in object.objectList('guesses'))
          BottleGuess.fromJson(guess.asMap()),
      ],
      hint: hint == null
          ? null
          : BottleHint.fromJson(JsonObject.parseMap(hint, 'hint').asMap()),
      practice: object.boolean('practice'),
    );
  }
}

List<int> _intList(JsonObject object, String key) {
  final value = object.asMap()[key];
  if (value is! List) {
    throw FormatException('Expected a list for $key.');
  }
  return [
    for (final item in value)
      if (item is int)
        item
      else
        throw FormatException('Expected integers in $key.'),
  ];
}
