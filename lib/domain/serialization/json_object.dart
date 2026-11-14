/// Reads a JSON object without leaking loosely typed maps through the domain.
class JsonObject {
  JsonObject(Map<String, Object?> json) : _json = json;

  final Map<String, Object?> _json;

  static JsonObject parseMap(Object? value, String field) {
    if (value is! Map) {
      throw FormatException('Expected an object for $field.');
    }
    return JsonObject(Map<String, Object?>.from(value));
  }

  String string(String key) {
    final value = _json[key];
    if (value is! String) {
      throw FormatException('Expected a string for $key.');
    }
    return value;
  }

  String? optionalString(String key) {
    final value = _json[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException('Expected a string for $key.');
    }
    return value;
  }

  int integer(String key) {
    final value = optionalInt(key);
    if (value == null) {
      throw FormatException('Expected an integer for $key.');
    }
    return value;
  }

  int? optionalInt(String key) {
    final value = _json[key];
    if (value == null) {
      return null;
    }
    if (value is! int) {
      throw FormatException('Expected an integer for $key.');
    }
    return value;
  }

  bool boolean(String key) {
    final value = _json[key];
    if (value is! bool) {
      throw FormatException('Expected a boolean for $key.');
    }
    return value;
  }

  List<String> stringList(String key) {
    final value = _json[key];
    if (value is! List) {
      throw FormatException('Expected a list for $key.');
    }
    return [
      for (final item in value)
        if (item is String)
          item
        else
          throw FormatException('Expected strings in $key.'),
    ];
  }

  List<JsonObject> objectList(String key) {
    final value = _json[key];
    if (value is! List) {
      throw FormatException('Expected a list for $key.');
    }
    return [
      for (var index = 0; index < value.length; index++)
        JsonObject.parseMap(value[index], '$key[$index]'),
    ];
  }

  JsonObject object(String key) => JsonObject.parseMap(_json[key], key);

  Map<String, Object?> asMap() => _json;
}

T enumByName<T extends Enum>(List<T> values, String name, String field) {
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  throw FormatException('Unknown $field "$name".');
}
