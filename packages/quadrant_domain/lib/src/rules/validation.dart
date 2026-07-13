/// Domain validation rules, shared by every backend. Failures throw
/// [DomainValidationError], which the REST layer maps to a 400 problem.
class DomainValidationError extends Error {
  DomainValidationError(this.message);

  final String message;

  @override
  String toString() => 'DomainValidationError: $message';
}

const int maxTitleLength = 500;
const int maxNotesLength = 10000;
const int maxTagNameLength = 100;
const int maxEstimatedMinutes = 10080; // one week

final RegExp _colorPattern = RegExp(r'^#[0-9a-fA-F]{6}$');

String validateTaskTitle(String title) {
  final trimmed = title.trim();
  if (trimmed.isEmpty) {
    throw DomainValidationError('Task title must not be empty.');
  }
  if (trimmed.length > maxTitleLength) {
    throw DomainValidationError(
      'Task title must be at most $maxTitleLength characters.',
    );
  }
  return trimmed;
}

String validateTaskNotes(String notes) {
  if (notes.length > maxNotesLength) {
    throw DomainValidationError(
      'Task notes must be at most $maxNotesLength characters.',
    );
  }
  return notes;
}

int validateEstimatedMinutes(int minutes) {
  if (minutes < 1 || minutes > maxEstimatedMinutes) {
    throw DomainValidationError(
      'estimated_minutes must be between 1 and $maxEstimatedMinutes.',
    );
  }
  return minutes;
}

String validateTagName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    throw DomainValidationError('Tag name must not be empty.');
  }
  if (trimmed.length > maxTagNameLength) {
    throw DomainValidationError(
      'Tag name must be at most $maxTagNameLength characters.',
    );
  }
  return trimmed;
}

String validateTagColor(String color) {
  if (!_colorPattern.hasMatch(color)) {
    throw DomainValidationError('Tag color must match #RRGGBB.');
  }
  return color.toLowerCase();
}
