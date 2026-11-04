import 'dart:async';

import 'package:flutter_testing_lab/src/data/task_repository.dart';
import 'package:flutter_testing_lab/src/models/task.dart';

import 'test_tasks.dart';

/// A hand-written fake for widget tests. Unlike a mock it has real behaviour
/// (it stores tasks), plus switches for driving the UI into any state:
///
/// * a gate ([fetchGate], [addGate]) holds a call open, freezing the UI in its
///   loading state until the test completes the [Completer];
/// * an error field ([fetchError], ...) makes that call throw.
class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository({List<Task> tasks = const []}) : _tasks = [...tasks];

  final List<Task> _tasks;

  Completer<void>? fetchGate;
  Completer<void>? addGate;

  Object? fetchError;
  Object? addError;
  Object? updateError;
  Object? deleteError;

  int fetchCount = 0;

  /// What is currently "persisted", to assert the UI really saved a change.
  List<Task> get stored => List.unmodifiable(_tasks);

  @override
  Future<List<Task>> fetchTasks() async {
    fetchCount++;
    await fetchGate?.future;
    if (fetchError case final error?) throw error;
    return [..._tasks];
  }

  @override
  Future<Task> addTask(String title) async {
    await addGate?.future;
    if (addError case final error?) throw error;
    final task = Task(
      id: 'fake-${_tasks.length + 1}',
      title: title,
      createdAt: kTestNow,
    );
    _tasks.add(task);
    return task;
  }

  @override
  Future<Task> updateTask(Task task) async {
    if (updateError case final error?) throw error;
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index < 0) throw TaskNotFoundException(task.id);
    _tasks[index] = task;
    return task;
  }

  @override
  Future<void> deleteTask(String id) async {
    if (deleteError case final error?) throw error;
    final before = _tasks.length;
    _tasks.removeWhere((t) => t.id == id);
    if (_tasks.length == before) throw TaskNotFoundException(id);
  }
}
