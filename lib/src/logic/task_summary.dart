import 'package:flutter/foundation.dart';

import '../models/task.dart';

/// The totals block at the bottom of the receipt.
@immutable
class TaskSummary {
  const TaskSummary({required this.open, required this.done});

  factory TaskSummary.of(Iterable<Task> tasks) {
    var done = 0;
    var open = 0;
    for (final task in tasks) {
      task.isCompleted ? done++ : open++;
    }
    return TaskSummary(open: open, done: done);
  }

  final int open;
  final int done;

  int get total => open + done;

  /// Share of tasks done, 0–100, rounded down. Zero when there are no tasks.
  int get percentDone => total == 0 ? 0 : done * 100 ~/ total;

  bool get allDone => total > 0 && open == 0;

  @override
  bool operator ==(Object other) =>
      other is TaskSummary && other.open == open && other.done == done;

  @override
  int get hashCode => Object.hash(open, done);

  @override
  String toString() => 'TaskSummary(open: $open, done: $done)';
}

/// Receipt order: open items first, then done ones. Each group is oldest
/// first, with the id as a tie-breaker so the order is always stable.
List<Task> sortForReceipt(Iterable<Task> tasks) {
  final sorted = [...tasks];
  sorted.sort((a, b) {
    if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
    final byDate = a.createdAt.compareTo(b.createdAt);
    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  });
  return sorted;
}
