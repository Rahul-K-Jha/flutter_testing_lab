import '../models/task.dart';

/// Storage boundary for tasks. The app depends only on this interface, so
/// tests can swap in a fake or a mock.
abstract interface class TaskRepository {
  Future<List<Task>> fetchTasks();

  /// Stores a new open task with [title] and returns it.
  Future<Task> addTask(String title);

  /// Replaces the stored task that has the same id as [task].
  Future<Task> updateTask(Task task);

  Future<void> deleteTask(String id);
}

/// A recoverable storage failure, with a message fit for the UI.
class TaskRepositoryException implements Exception {
  const TaskRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'TaskRepositoryException: $message';
}

class TaskNotFoundException extends TaskRepositoryException {
  const TaskNotFoundException(this.id) : super('No task with id "$id".');

  final String id;
}
