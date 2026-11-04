import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_lab/src/logic/task_summary.dart';

import '../../helpers/test_tasks.dart';

void main() {
  group('TaskSummary', () {
    test('counts open and done tasks', () {
      final summary = TaskSummary.of(sampleTasks());

      expect(summary.open, 2);
      expect(summary.done, 1);
      expect(summary.total, 3);
    });

    test('is all zeros for no tasks', () {
      final summary = TaskSummary.of(const []);

      expect(summary, const TaskSummary(open: 0, done: 0));
      expect(summary.percentDone, 0);
      expect(
        summary.allDone,
        isFalse,
        reason: 'an empty receipt is not "all done"',
      );
    });

    test('rounds percentDone down', () {
      expect(const TaskSummary(open: 2, done: 1).percentDone, 33);
      expect(const TaskSummary(open: 1, done: 2).percentDone, 66);
      expect(const TaskSummary(open: 0, done: 4).percentDone, 100);
    });

    test('allDone is true only when every task is done', () {
      expect(const TaskSummary(open: 0, done: 3).allDone, isTrue);
      expect(const TaskSummary(open: 1, done: 3).allDone, isFalse);
    });
  });

  group('sortForReceipt', () {
    test('puts open tasks before done tasks', () {
      final sorted = sortForReceipt([
        buildTask(id: 'done', done: true, minutesAgo: 60),
        buildTask(id: 'open', minutesAgo: 0),
      ]);

      expect(sorted.map((t) => t.id), ['open', 'done']);
    });

    test('orders each group oldest first', () {
      final sorted = sortForReceipt([
        buildTask(id: 'new', minutesAgo: 1),
        buildTask(id: 'old', minutesAgo: 50),
        buildTask(id: 'mid', minutesAgo: 20),
      ]);

      expect(sorted.map((t) => t.id), ['old', 'mid', 'new']);
    });

    test('breaks date ties by id so the order is stable', () {
      final sorted = sortForReceipt([buildTask(id: 'b'), buildTask(id: 'a')]);

      expect(sorted.map((t) => t.id), ['a', 'b']);
    });

    test('returns a new list and leaves the input untouched', () {
      final input = [buildTask(id: 'b'), buildTask(id: 'a')];

      sortForReceipt(input);

      expect(input.map((t) => t.id), ['b', 'a']);
    });
  });
}
