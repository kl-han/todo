/// Typed application errors. The REST layer maps these onto Problem
/// Details responses; nothing here knows about HTTP.
sealed class ApplicationException implements Exception {
  ApplicationException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The addressed entity does not exist (or is soft-deleted where deleted
/// entities are invisible). → 404
class EntityNotFoundException extends ApplicationException {
  EntityNotFoundException(super.message);
}

/// The request contradicts current state, e.g. a duplicate active tag
/// name. → 409
class StateConflictException extends ApplicationException {
  StateConflictException(super.message);
}

/// Optimistic concurrency failure: the caller's expected version no longer
/// matches. → 412
class VersionConflictException extends ApplicationException {
  VersionConflictException({required this.currentVersion})
      : super('Expected version does not match current version '
            '$currentVersion.');

  final int currentVersion;
}
