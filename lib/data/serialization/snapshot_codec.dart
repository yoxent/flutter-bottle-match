import 'dart:convert';

import '../../domain/models/match_snapshot.dart';

/// Encodes a whole match as one JSON document so a save replaces it atomically.
abstract final class SnapshotCodec {
  static String encode(MatchSnapshot snapshot) => jsonEncode(snapshot.toJson());

  static MatchSnapshot decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Saved match is not a JSON object.');
    }
    return MatchSnapshot.fromJson(Map<String, Object?>.from(decoded));
  }
}
