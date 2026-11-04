import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_lab/src/models/task.dart';

import '../../helpers/test_tasks.dart';

void main() {
  group('Task', () {
    test('is open by default', () {
      final task = Task(id: '1', title: 'Write tests', createdAt: kTestNow);

      expect(task.isCompleted, isFalse);
    });

    test('copyWith replaces only the given fields', () {
      final task = buildTask(title: 'Old');

      final renamed = task.copyWith(title: 'New');

      expect(renamed.title, 'New');
      expect(renamed.id, task.id);
      expect(renamed.createdAt, task.createdAt);
      expect(renamed.isCompleted, task.isCompleted);
    });

    test('toggled flips completion and nothing else', () {
      final open = buildTask();

      final done = open.toggled();

      expect(done.isCompleted, isTrue);
      expect(done.toggled(), open);
      expect(done.copyWith(isCompleted: false), open);
    });

    test('uses value equality', () {
      expect(buildTask(), buildTask());
      expect(buildTask().hashCode, buildTask().hashCode);
      expect(buildTask(), isNot(buildTask(done: true)));
      expect(buildTask(), isNot(buildTask(id: 'other')));
    });

    test('toString names the task and its state', () {
      expect(buildTask(title: 'Ship it').toString(), contains('"Ship it"'));
      expect(buildTask(done: true).toString(), contains('done'));
    });
  });
}
