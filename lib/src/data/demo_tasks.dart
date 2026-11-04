import '../models/task.dart';

/// A few items so the running app has something on its first receipt.
List<Task> demoTasks(DateTime now) => [
  Task(
    id: 'demo-1',
    title: 'Write unit tests for the validator',
    createdAt: now.subtract(const Duration(hours: 3)),
    isCompleted: true,
  ),
  Task(
    id: 'demo-2',
    title: 'Mock the repository with mocktail',
    createdAt: now.subtract(const Duration(hours: 2)),
    isCompleted: true,
  ),
  Task(
    id: 'demo-3',
    title: 'Cover the paper jam error state',
    createdAt: now.subtract(const Duration(hours: 1)),
  ),
  Task(
    id: 'demo-4',
    title: 'Run integration tests on every push',
    createdAt: now.subtract(const Duration(minutes: 20)),
  ),
];
