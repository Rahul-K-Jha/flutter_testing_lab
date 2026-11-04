import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_lab/src/data/in_memory_task_repository.dart';
import 'package:flutter_testing_lab/src/data/task_repository.dart';

import '../../helpers/test_tasks.dart';

void main() {
  late InMemoryTaskRepository repository;

  setUp(() {
    repository = InMemoryTaskRepository(clock: () => kTestNow);
  });

  test('starts empty', () async {
    expect(await repository.fetchTasks(), isEmpty);
  });

  test('returns seeded tasks in seed order', () async {
    final seeded = InMemoryTaskRepository(seed: sampleTasks());

    expect(await seeded.fetchTasks(), sampleTasks());
  });

  test('fetchTasks returns a read-only snapshot', () async {
    final tasks = await repository.fetchTasks();

    expect(() => tasks.add(buildTask()), throwsUnsupportedError);
  });

  group('addTask', () {
    test('stores an open task stamped with the clock', () async {
      final task = await repository.addTask('Write tests');

      expect(task.title, 'Write tests');
      expect(task.isCompleted, isFalse);
      expect(task.createdAt, kTestNow);
      expect(await repository.fetchTasks(), [task]);
    });

    test('gives every task a unique id', () async {
      final a = await repository.addTask('A');
      final b = await repository.addTask('B');

      expect(a.id, isNot(b.id));
    });

    test('never reuses an id taken by a seeded task', () async {
      final seeded = InMemoryTaskRepository(seed: [buildTask(id: 'task-1')]);

      final added = await seeded.addTask('New');

      expect(added.id, isNot('task-1'));
      expect(await seeded.fetchTasks(), hasLength(2));
    });
  });

  group('updateTask', () {
    test('replaces the stored task', () async {
      final task = await repository.addTask('Write tests');

      await repository.updateTask(task.toggled());

      expect((await repository.fetchTasks()).single.isCompleted, isTrue);
    });

    test('throws TaskNotFoundException for an unknown id', () {
      expect(
        repository.updateTask(buildTask(id: 'missing')),
        throwsA(
          isA<TaskNotFoundException>().having((e) => e.id, 'id', 'missing'),
        ),
      );
    });
  });

  group('deleteTask', () {
    test('removes the task', () async {
      final task = await repository.addTask('Write tests');

      await repository.deleteTask(task.id);

      expect(await repository.fetchTasks(), isEmpty);
    });

    test('throws TaskNotFoundException for an unknown id', () {
      expect(
        repository.deleteTask('missing'),
        throwsA(isA<TaskNotFoundException>()),
      );
    });
  });
}
