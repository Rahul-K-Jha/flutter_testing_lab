import 'package:flutter_testing_lab/src/models/task.dart';

/// A fixed "now" so dates on screen are deterministic.
final kTestNow = DateTime(2026, 11, 4, 9, 30);

/// Builds a task with sensible defaults. [minutesAgo] controls ordering.
Task buildTask({
  String id = 't1',
  String title = 'Write tests',
  bool done = false,
  int minutesAgo = 0,
}) => Task(
  id: id,
  title: title,
  createdAt: kTestNow.subtract(Duration(minutes: minutesAgo)),
  isCompleted: done,
);

/// Two open tasks and one done, in a known order.
List<Task> sampleTasks() => [
  buildTask(id: 'a', title: 'Write unit tests', minutesAgo: 30),
  buildTask(id: 'b', title: 'Write widget tests', minutesAgo: 20),
  buildTask(id: 'c', title: 'Set up CI', minutesAgo: 10, done: true),
];
