import 'package:flutter/foundation.dart';

import '../data/task_repository.dart';
import '../logic/task_summary.dart';
import '../logic/task_validator.dart';
import '../models/task.dart';

enum LoadStatus { initial, loading, ready, failure }

/// Outcome of [TaskController.addTask].
sealed class AddTaskResult {
  const AddTaskResult();
}

final class TaskAdded extends AddTaskResult {
  const TaskAdded(this.task);
  final Task task;
}

/// The title broke a validation rule; the repository was never called.
final class TaskRejected extends AddTaskResult {
  const TaskRejected(this.error);
  final TaskValidationError error;
}

/// The title was valid but the repository failed to store it.
final class TaskAddFailed extends AddTaskResult {
  const TaskAddFailed(this.message);
  final String message;
}

/// Screen state for the receipt. Toggle and delete are optimistic: the UI
/// updates at once and rolls back if the repository call fails.
class TaskController extends ChangeNotifier {
  TaskController(this._repository);

  final TaskRepository _repository;

  LoadStatus _status = LoadStatus.initial;
  List<Task> _tasks = const [];
  String? _errorMessage;
  bool _isAdding = false;
  bool _disposed = false;

  LoadStatus get status => _status;

  /// Tasks in receipt order (open first, oldest first).
  List<Task> get tasks => List.unmodifiable(sortForReceipt(_tasks));

  TaskSummary get summary => TaskSummary.of(_tasks);

  /// Why the last [load] failed, when [status] is [LoadStatus.failure].
  String? get errorMessage => _errorMessage;

  bool get isAdding => _isAdding;

  Task? taskById(String id) {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  Future<void> load() async {
    _status = LoadStatus.loading;
    _errorMessage = null;
    _notify();
    try {
      _tasks = await _repository.fetchTasks();
      _status = LoadStatus.ready;
    } catch (error) {
      _status = LoadStatus.failure;
      _errorMessage = _describe(error);
    }
    _notify();
  }

  Future<AddTaskResult> addTask(String rawTitle) async {
    final error = TaskValidator.validate(rawTitle, existing: _tasks);
    if (error != null) return TaskRejected(error);

    _isAdding = true;
    _notify();
    try {
      final task = await _repository.addTask(TaskValidator.normalize(rawTitle));
      _tasks = [..._tasks, task];
      return TaskAdded(task);
    } catch (error) {
      return TaskAddFailed(_describe(error));
    } finally {
      _isAdding = false;
      _notify();
    }
  }

  /// Flips a task between open and done. Returns `false` if the change had
  /// to be rolled back.
  Future<bool> toggle(String id) async {
    final original = taskById(id);
    if (original == null) return false;

    final updated = original.toggled();
    _replace(id, updated);
    try {
      await _repository.updateTask(updated);
      return true;
    } catch (_) {
      _replace(id, original);
      return false;
    }
  }

  /// Removes a task. Returns `false` if the removal had to be rolled back.
  Future<bool> delete(String id) async {
    final original = taskById(id);
    if (original == null) return false;

    _tasks = [
      for (final task in _tasks)
        if (task.id != id) task,
    ];
    _notify();
    try {
      await _repository.deleteTask(id);
      return true;
    } catch (_) {
      if (taskById(id) == null) _tasks = [..._tasks, original];
      _notify();
      return false;
    }
  }

  void _replace(String id, Task task) {
    _tasks = [for (final t in _tasks) t.id == id ? task : t];
    _notify();
  }

  static String _describe(Object error) => error is TaskRepositoryException
      ? error.message
      : 'Something went wrong. Please try again.';

  /// Async work can finish after the screen is gone; never notify then.
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
