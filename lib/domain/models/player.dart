import '../serialization/json_object.dart';

/// A roster member. The id stays stable for the match.
class Player {
  const Player({
    required this.id,
    required this.name,
    required this.avatarIndex,
    this.accentIndex,
  });

  final String id;
  final String name;
  final int avatarIndex;
  final int? accentIndex;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'avatarIndex': avatarIndex,
    'accentIndex': accentIndex,
  };

  factory Player.fromJson(Map<String, Object?> json) {
    final object = JsonObject(json);
    return Player(
      id: object.string('id'),
      name: object.string('name'),
      avatarIndex: object.integer('avatarIndex'),
      accentIndex: object.optionalInt('accentIndex'),
    );
  }
}
