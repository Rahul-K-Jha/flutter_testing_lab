import '../models/task.dart';
import 'task_repository.dart';

typedef Clock = DateTime Function();

/// Keeps tasks in memory, with optional artificial latency so the loading
/// state is visible in the running app.
class InMemoryTaskRepository implements TaskRepository {
  InMemoryTaskRepository({
    Iterable<Task> seed = const [],
    this.latency = Duration.zero,
    Clock? clock,
  }) : _clock = clock ?? DateTime.now {
    for (final task in seed) {
      _tasks[task.id] = task;
    }
  }

  final Duration latency;
  final Clock _clock;
  final _tasks = <String, Task>{};
  var _nextId = 1;

  @override
  Future<List<Task>> fetchTasks() =>
      _respond(() => List.unmodifiable(_tasks.values));

  @override
  Future<Task> addTask(String title) => _respond(() {
    final task = Task(id: _newId(), title: title, createdAt: _clock());
    _tasks[task.id] = task;
    return task;
  });

  @override
  Future<Task> updateTask(Task task) => _respond(() {
    if (!_tasks.containsKey(task.id)) throw TaskNotFoundException(task.id);
    _tasks[task.id] = task;
    return task;
  });

  @override
  Future<void> deleteTask(String id) => _respond(() {
    if (_tasks.remove(id) == null) throw TaskNotFoundException(id);
  });

  String _newId() {
    String id;
    do {
      id = 'task-${_nextId++}';
    } while (_tasks.containsKey(id));
    return id;
  }

  Future<T> _respond<T>(T Function() body) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    return body();
  }
}
