import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_lab/src/data/task_repository.dart';
import 'package:flutter_testing_lab/src/logic/task_validator.dart';
import 'package:flutter_testing_lab/src/ui/receipt_keys.dart';
import 'package:flutter_testing_lab/src/ui/task_detail_page.dart';
import 'package:flutter_testing_lab/src/ui/widgets/receipt_parts.dart';
import 'package:flutter_testing_lab/src/ui/widgets/task_line.dart';

import '../helpers/fake_task_repository.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_tasks.dart';

void main() {
  late FakeTaskRepository repository;

  Future<void> pumpLoaded(WidgetTester tester) async {
    await tester.pumpLab(repository);
    await tester.pumpAndSettle();
  }

  Future<void> typeAndPrint(WidgetTester tester, String title) async {
    await tester.enterText(find.byKey(ReceiptKeys.titleField), title);
    await tester.tapVisible(find.byKey(ReceiptKeys.printButton));
    await tester.pumpAndSettle();
  }

  setUp(() => repository = FakeTaskRepository(tasks: sampleTasks()));

  group('marking a task done', () {
    testWidgets('stamps the line, updates totals and saves it', (tester) async {
      await pumpLoaded(tester);
      expect(inLine('a', find.byKey(ReceiptKeys.lineStamp)), findsNothing);

      await tester.tapVisible(inLine('a', find.byKey(ReceiptKeys.lineToggle)));
      await tester.pumpAndSettle();

      expect(inLine('a', find.byKey(ReceiptKeys.lineStamp)), findsOneWidget);
      expect(textOf(tester, ReceiptKeys.totalDone), '02');
      expect(
        repository.stored.firstWhere((t) => t.id == 'a').isCompleted,
        isTrue,
      );
    });

    testWidgets('moves the done task below the open ones', (tester) async {
      await pumpLoaded(tester);

      await tester.tapVisible(inLine('a', find.byKey(ReceiptKeys.lineToggle)));
      await tester.pumpAndSettle();

      final order = tester
          .widgetList<TaskLine>(find.byType(TaskLine))
          .map((l) => l.task.id);
      expect(order, ['b', 'a', 'c']);
    });

    testWidgets('can be undone by tapping again', (tester) async {
      await pumpLoaded(tester);

      await tester.tapVisible(inLine('c', find.byKey(ReceiptKeys.lineToggle)));
      await tester.pumpAndSettle();

      expect(inLine('c', find.byKey(ReceiptKeys.lineStamp)), findsNothing);
      expect(textOf(tester, ReceiptKeys.totalOpen), '03');
    });

    testWidgets('rolls back and explains when saving fails', (tester) async {
      repository.updateError = const TaskRepositoryException('Offline');
      await pumpLoaded(tester);

      await tester.tapVisible(inLine('a', find.byKey(ReceiptKeys.lineToggle)));
      await tester.pumpAndSettle();

      expect(inLine('a', find.byKey(ReceiptKeys.lineStamp)), findsNothing);
      expect(find.text("COULDN'T UPDATE ITEM. CHANGE UNDONE."), findsOneWidget);
    });
  });

  group('voiding a task', () {
    testWidgets('removes the line and deletes it from storage', (tester) async {
      await pumpLoaded(tester);

      await tester.tapVisible(inLine('b', find.byKey(ReceiptKeys.lineVoid)));
      await tester.pumpAndSettle();

      expect(find.byKey(ReceiptKeys.line('b')), findsNothing);
      expect(find.text('ITEM VOIDED'), findsOneWidget);
      expect(repository.stored.map((t) => t.id), ['a', 'c']);
      expect(textOf(tester, ReceiptKeys.totalItems), '02');
    });

    testWidgets('shows the empty receipt after the last task is voided', (
      tester,
    ) async {
      repository = FakeTaskRepository(tasks: [buildTask(id: 'only')]);
      await pumpLoaded(tester);

      await tester.tapVisible(inLine('only', find.byKey(ReceiptKeys.lineVoid)));
      await tester.pumpAndSettle();

      expect(find.byKey(ReceiptKeys.empty), findsOneWidget);
    });

    testWidgets('puts the line back when deleting fails', (tester) async {
      repository.deleteError = const TaskRepositoryException('Offline');
      await pumpLoaded(tester);

      await tester.tapVisible(inLine('b', find.byKey(ReceiptKeys.lineVoid)));
      await tester.pumpAndSettle();

      expect(find.byKey(ReceiptKeys.line('b')), findsOneWidget);
      expect(find.text("COULDN'T VOID ITEM"), findsOneWidget);
    });
  });

  group('adding a task', () {
    testWidgets('prints a new line and clears the field', (tester) async {
      await pumpLoaded(tester);

      await typeAndPrint(tester, '  Add   golden tests ');

      expect(find.text('Add golden tests'), findsOneWidget);
      expect(repository.stored.last.title, 'Add golden tests');
      expect(
        tester
            .widget<TextField>(find.byKey(ReceiptKeys.titleField))
            .controller!
            .text,
        isEmpty,
      );
      expect(find.byKey(ReceiptKeys.validationMessage), findsNothing);
    });

    testWidgets('submits from the keyboard action too', (tester) async {
      await pumpLoaded(tester);

      await tester.enterText(
        find.byKey(ReceiptKeys.titleField),
        'Add golden tests',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Add golden tests'), findsOneWidget);
    });

    final rejections = {
      '': TaskValidationError.empty,
      'x' * (TaskValidator.maxLength + 1): TaskValidationError.tooLong,
      'write unit tests': TaskValidationError.duplicate,
    };
    for (final MapEntry(key: input, value: error) in rejections.entries) {
      testWidgets('shows "${error.name}" error and saves nothing', (
        tester,
      ) async {
        await pumpLoaded(tester);

        await typeAndPrint(tester, input);

        expect(find.text('! ${error.message}'), findsOneWidget);
        expect(repository.stored, hasLength(3));
      });
    }

    testWidgets('clears the error as soon as the user types', (tester) async {
      await pumpLoaded(tester);
      await typeAndPrint(tester, '');
      expect(find.byKey(ReceiptKeys.validationMessage), findsOneWidget);

      await tester.enterText(find.byKey(ReceiptKeys.titleField), 'A');
      await tester.pump();

      expect(find.byKey(ReceiptKeys.validationMessage), findsNothing);
    });

    testWidgets('shows PRINTING… and blocks double submits while saving', (
      tester,
    ) async {
      repository.addGate = Completer();
      await pumpLoaded(tester);

      await tester.enterText(
        find.byKey(ReceiptKeys.titleField),
        'Add golden tests',
      );
      await tester.tapVisible(find.byKey(ReceiptKeys.printButton));
      await tester.pump();

      final button = find.byKey(ReceiptKeys.printButton);
      expect(
        find.descendant(of: button, matching: find.text('PRINTING…')),
        findsOneWidget,
      );
      expect(tester.widget<ReceiptButton>(button).onPressed, isNull);

      repository.addGate!.complete();
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: button, matching: find.text('PRINT')),
        findsOneWidget,
      );
      expect(repository.stored, hasLength(4));
    });

    testWidgets('reports a storage failure inline', (tester) async {
      repository.addError = const TaskRepositoryException('Disk full');
      await pumpLoaded(tester);

      await typeAndPrint(tester, 'Add golden tests');

      expect(find.text('! Printer offline. Disk full'), findsOneWidget);
    });
  });

  testWidgets('tapping a task title opens its detail stub', (tester) async {
    await pumpLoaded(tester);

    await tester.tapVisible(inLine('b', find.text('Write widget tests')));
    await tester.pumpAndSettle();

    expect(find.byType(TaskDetailPage), findsOneWidget);
    expect(find.byKey(ReceiptKeys.detailTitle), findsOneWidget);
  });
}
