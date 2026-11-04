import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_lab/src/data/task_repository.dart';
import 'package:flutter_testing_lab/src/ui/receipt_keys.dart';
import 'package:flutter_testing_lab/src/ui/widgets/task_line.dart';

import '../helpers/fake_task_repository.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_tasks.dart';

void main() {
  testWidgets('shows the printing indicator while tasks load', (tester) async {
    final repository = FakeTaskRepository(tasks: sampleTasks())
      ..fetchGate = Completer();

    await tester.pumpLab(repository);
    // Not pumpAndSettle: the indeterminate progress bar never settles.
    await tester.pump();

    expect(find.byKey(ReceiptKeys.loading), findsOneWidget);
    expect(find.text('PRINTING RECEIPT…'), findsOneWidget);
    expect(find.byType(TaskLine), findsNothing);

    repository.fetchGate!.complete();
    await tester.pumpAndSettle();

    expect(find.byKey(ReceiptKeys.loading), findsNothing);
    expect(find.byType(TaskLine), findsNWidgets(3));
  });

  testWidgets('disables adding until the receipt has loaded', (tester) async {
    final repository = FakeTaskRepository()..fetchGate = Completer();

    await tester.pumpLab(repository);
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byKey(ReceiptKeys.titleField)).enabled,
      isFalse,
    );

    repository.fetchGate!.complete();
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byKey(ReceiptKeys.titleField)).enabled,
      isTrue,
    );
  });

  testWidgets('shows the empty receipt when there are no tasks', (
    tester,
  ) async {
    await tester.pumpLab(FakeTaskRepository());
    await tester.pumpAndSettle();

    expect(find.byKey(ReceiptKeys.empty), findsOneWidget);
    expect(find.text('NO ITEMS ON THIS RECEIPT'), findsOneWidget);
    expect(
      find.byKey(ReceiptKeys.totals),
      findsNothing,
      reason: 'no totals on an empty receipt',
    );
  });

  testWidgets('shows a paper jam with the reason when loading fails', (
    tester,
  ) async {
    final repository = FakeTaskRepository()
      ..fetchError = const TaskRepositoryException('Printer offline');

    await tester.pumpLab(repository);
    await tester.pumpAndSettle();

    expect(find.byKey(ReceiptKeys.error), findsOneWidget);
    expect(find.text('*** PAPER JAM ***'), findsOneWidget);
    expect(find.text('Printer offline'), findsOneWidget);
    expect(find.byKey(ReceiptKeys.retryButton), findsOneWidget);
  });

  testWidgets('retry reloads and recovers from a paper jam', (tester) async {
    final repository = FakeTaskRepository(tasks: sampleTasks())
      ..fetchError = const TaskRepositoryException('Printer offline');
    await tester.pumpLab(repository);
    await tester.pumpAndSettle();

    repository.fetchError = null;
    await tester.tapVisible(find.byKey(ReceiptKeys.retryButton));
    await tester.pumpAndSettle();

    expect(repository.fetchCount, 2);
    expect(find.byKey(ReceiptKeys.error), findsNothing);
    expect(find.byType(TaskLine), findsNWidgets(3));
  });

  testWidgets('prints one line per task, open first, with totals', (
    tester,
  ) async {
    await tester.pumpLab(FakeTaskRepository(tasks: sampleTasks()));
    await tester.pumpAndSettle();

    final lines = tester.widgetList<TaskLine>(find.byType(TaskLine)).toList();
    expect(lines.map((l) => l.task.id), ['a', 'b', 'c']);
    expect(lines.map((l) => l.number), [1, 2, 3]);

    expect(textOf(tester, ReceiptKeys.totalOpen), '02');
    expect(textOf(tester, ReceiptKeys.totalDone), '01');
    expect(textOf(tester, ReceiptKeys.totalItems), '03');
    expect(textOf(tester, ReceiptKeys.totalProgress), '33%');
  });

  testWidgets('prints the date from the injected clock', (tester) async {
    await tester.pumpLab(FakeTaskRepository());
    await tester.pumpAndSettle();

    expect(find.text('04 NOV 2026'), findsOneWidget);
    expect(find.text('09:30'), findsOneWidget);
  });
}
