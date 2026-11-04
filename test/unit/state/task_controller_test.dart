import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_lab/src/data/task_repository.dart';
import 'package:flutter_testing_lab/src/logic/task_validator.dart';
import 'package:flutter_testing_lab/src/models/task.dart';
import 'package:flutter_testing_lab/src/state/task_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_tasks.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository repository;
  late TaskController controller;

  setUpAll(() {
    // Needed so `any()` can stand in for a Task argument.
    registerFallbackValue(buildTask());
  });

  setUp(() {
    repository = MockTaskRepository();
    controller = TaskController(repository);
  });

  tearDown(() => controller.dispose());

  /// Loads [tasks] through the mock so a test can start from a ready state.
  Future<void> loadWith(List<Task> tasks) async {
    when(() => repository.fetchTasks()).thenAnswer((_) async => tasks);
    await controller.load();
  }

  /// Records the status after every notification.
  List<LoadStatus> recordStatuses() {
    final statuses = <LoadStatus>[];
    controller.addListener(() => statuses.add(controller.status));
    return statuses;
  }

  test('starts in the initial state with no tasks', () {
    expect(controller.status, LoadStatus.initial);
    expect(controller.tasks, isEmpty);
    expect(controller.errorMessage, isNull);
  });

  group('load', () {
    test('goes loading -> ready and exposes the tasks', () async {
      final statuses = recordStatuses();

      await loadWith(sampleTasks());

      expect(statuses, [LoadStatus.loading, LoadStatus.ready]);
      expect(controller.tasks, hasLength(3));
      verify(() => repository.fetchTasks()).called(1);
    });

    test('goes loading -> failure with the repository message', () async {
      when(() => repository.fetchTasks())
          .thenThrow(const TaskRepositoryException('Printer offline'));
      final statuses = recordStatuses();

      await controller.load();

      expect(statuses, [LoadStatus.loading, LoadStatus.failure]);
      expect(controller.errorMessage, 'Printer offline');
    });

    test('uses a generic message for unexpected errors', () async {
      when(() => repository.fetchTasks()).thenThrow(StateError('boom'));

      await controller.load();

      expect(
        controller.errorMessage,
        'Something went wrong. Please try again.',
      );
    });

    test('clears a previous error when retried', () async {
      when(() => repository.fetchTasks())
          .thenThrow(const TaskRepositoryException('Offline'));
      await controller.load();

      await loadWith(const []);

      expect(controller.status, LoadStatus.ready);
      expect(controller.errorMessage, isNull);
    });
  });

  test('exposes tasks in receipt order with a matching summary', () async {
    await loadWith(sampleTasks());

    expect(controller.tasks.map((t) => t.id), ['a', 'b', 'c']);
    expect(controller.tasks.last.isCompleted, isTrue);
    expect(controller.summary.open, 2);
    expect(controller.summary.done, 1);
  });

  group('addTask', () {
    setUp(() => loadWith(sampleTasks()));

    test('rejects an invalid title without touching the repository', () async {
      final result = await controller.addTask('   ');

      expect(
        result,
        isA<TaskRejected>().having(
          (r) => r.error,
          'error',
          TaskValidationError.empty,
        ),
      );
      verifyNever(() => repository.addTask(any()));
    });

    test('rejects a duplicate of an open task', () async {
      final result = await controller.addTask('write UNIT tests');

      expect(
        result,
        isA<TaskRejected>().having(
          (r) => r.error,
          'error',
          TaskValidationError.duplicate,
        ),
      );
    });

    test('stores the normalized title and appends the new task', () async {
      final created = buildTask(id: 'new', title: 'Add golden tests');
      when(() => repository.addTask(any())).thenAnswer((_) async => created);

      final result = await controller.addTask('  Add   golden tests ');

      expect(result, isA<TaskAdded>().having((r) => r.task, 'task', created));
      verify(() => repository.addTask('Add golden tests')).called(1);
      expect(controller.taskById('new'), created);
    });

    test('is busy while the repository call is in flight', () async {
      final pending = Completer<Task>();
      when(() => repository.addTask(any())).thenAnswer((_) => pending.future);

      final future = controller.addTask('Add golden tests');
      expect(controller.isAdding, isTrue);

      pending.complete(buildTask(id: 'new', title: 'Add golden tests'));
      await future;
      expect(controller.isAdding, isFalse);
    });

    test('reports a repository failure and keeps the list unchanged', () async {
      when(() => repository.addTask(any()))
          .thenThrow(const TaskRepositoryException('Disk full'));

      final result = await controller.addTask('Add golden tests');

      expect(
        result,
        isA<TaskAddFailed>().having((r) => r.message, 'message', 'Disk full'),
      );
      expect(controller.tasks, hasLength(3));
      expect(controller.isAdding, isFalse);
    });
  });

  group('toggle', () {
    setUp(() => loadWith(sampleTasks()));

    test('updates the UI before the repository answers (optimistic)', () async {
      final pending = Completer<Task>();
      when(() => repository.updateTask(any()))
          .thenAnswer((_) => pending.future);

      final future = controller.toggle('a');

      expect(controller.taskById('a')!.isCompleted, isTrue);
      pending.complete(controller.taskById('a')!);
      expect(await future, isTrue);
    });

    test('persists the toggled task', () async {
      when(() => repository.updateTask(any()))
          .thenAnswer((i) async => i.positionalArguments.single as Task);

      await controller.toggle('a');

      final saved =
          verify(() => repository.updateTask(captureAny())).captured.single
              as Task;
      expect(saved.id, 'a');
      expect(saved.isCompleted, isTrue);
    });

    test('rolls back and returns false when the repository fails', () async {
      when(() => repository.updateTask(any()))
          .thenThrow(const TaskRepositoryException('Offline'));

      final ok = await controller.toggle('a');

      expect(ok, isFalse);
      expect(controller.taskById('a')!.isCompleted, isFalse);
    });

    test('returns false for an unknown id', () async {
      expect(await controller.toggle('missing'), isFalse);
      verifyNever(() => repository.updateTask(any()));
    });
  });

  group('delete', () {
    setUp(() => loadWith(sampleTasks()));

    test('removes the task and calls the repository', () async {
      when(() => repository.deleteTask(any())).thenAnswer((_) async {});

      expect(await controller.delete('b'), isTrue);

      expect(controller.taskById('b'), isNull);
      verify(() => repository.deleteTask('b')).called(1);
    });

    test('restores the task when the repository fails', () async {
      when(() => repository.deleteTask(any()))
          .thenThrow(const TaskRepositoryException('Offline'));

      expect(await controller.delete('b'), isFalse);

      expect(controller.taskById('b'), isNotNull);
      expect(controller.tasks.map((t) => t.id), [
        'a',
        'b',
        'c',
      ], reason: 'restored in its original position');
    });
  });

  test('ignores results that arrive after dispose', () async {
    final pending = Completer<List<Task>>();
    when(() => repository.fetchTasks()).thenAnswer((_) => pending.future);
    final disposable = TaskController(repository);

    final future = disposable.load();
    disposable.dispose();
    pending.complete(sampleTasks());

    await expectLater(future, completes);
  });
}
