/// A saved match could not be read or written.
class PersistenceFailure implements Exception {
  const PersistenceFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The saved document uses a schema this version of the app cannot read.
class SchemaMismatchFailure extends PersistenceFailure {
  SchemaMismatchFailure(int version)
    : super(
        'Saved match uses schema version $version, which this version of '
        'the app cannot read.',
      );
}
