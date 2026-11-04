import '../models/task.dart';

enum TaskValidationError {
  empty("Item name can't be empty."),
  tooLong('Keep it to ${TaskValidator.maxLength} characters or fewer.'),
  duplicate('That item is already open on the receipt.');

  const TaskValidationError(this.message);

  final String message;
}

/// Rules for a new task title. Pure functions, so they are trivial to test.
abstract final class TaskValidator {
  /// One receipt line's worth of text.
  static const maxLength = 48;

  /// Trims the title and collapses runs of whitespace into single spaces.
  static String normalize(String raw) =>
      raw.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Returns the first rule [raw] breaks, or `null` if it is a valid title.
  ///
  /// A title duplicates another only while that other task is still open;
  /// re-adding something already done is allowed.
  static TaskValidationError? validate(
    String raw, {
    Iterable<Task> existing = const [],
  }) {
    final title = normalize(raw);
    if (title.isEmpty) return TaskValidationError.empty;
    if (title.length > maxLength) return TaskValidationError.tooLong;

    final key = title.toLowerCase();
    final isDuplicate = existing.any(
      (task) => !task.isCompleted && task.title.toLowerCase() == key,
    );
    if (isDuplicate) return TaskValidationError.duplicate;
    return null;
  }
}
