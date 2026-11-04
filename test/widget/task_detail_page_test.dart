import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_lab/src/data/task_repository.dart';
import 'package:flutter_testing_lab/src/state/task_controller.dart';
import 'package:flutter_testing_lab/src/ui/receipt_keys.dart';
import 'package:flutter_testing_lab/src/ui/receipt_theme.dart';
import 'package:flutter_testing_lab/src/ui/task_detail_page.dart';

import '../helpers/fake_task_repository.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_tasks.dart';

void main() {
  late FakeTaskRepository repository;
  late TaskController controller;

  setUp(() async {
    repository = FakeTaskRepository(
      tasks: [buildTask(id: 't1', title: 'Write widget tests')],
    );
    controller = TaskController(repository);
    await controller.load();
  });

  tearDown(() => controller.dispose());

  /// Pushes the detail page on top of a placeholder, like the app does, so
  /// popping has somewhere to go.
  Future<void> pumpDetail(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: Receipt.theme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        TaskDetailPage(controller: controller, taskId: 't1'),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  bool statusShows(WidgetTester tester, String text) => find
      .descendant(
        of: find.byKey(ReceiptKeys.detailStatus),
        matching: find.text(text),
        matchRoot: true,
      )
      .evaluate()
      .isNotEmpty;

  testWidgets('shows the title, status and print date', (tester) async {
    await pumpDetail(tester);

    expect(find.text('Write widget tests'), findsOneWidget);
    expect(statusShows(tester, 'OPEN'), isTrue);
    expect(find.text('04 NOV 2026  09:30'), findsOneWidget);
    expect(find.text('T1'), findsOneWidget);
  });

  testWidgets('MARK AS DONE stamps the stub and offers REOPEN', (tester) async {
    await pumpDetail(tester);

    await tester.tapVisible(find.byKey(ReceiptKeys.detailToggle));
    await tester.pumpAndSettle();

    expect(statusShows(tester, 'DONE'), isTrue);
    expect(find.text('REOPEN ITEM'), findsOneWidget);
    expect(repository.stored.single.isCompleted, isTrue);
  });

  testWidgets('VOID ITEM deletes the task and goes back', (tester) async {
    await pumpDetail(tester);

    await tester.tapVisible(find.byKey(ReceiptKeys.detailVoid));
    await tester.pumpAndSettle();

    expect(find.byType(TaskDetailPage), findsNothing);
    expect(find.text('ITEM VOIDED'), findsOneWidget);
    expect(repository.stored, isEmpty);
  });

  testWidgets('stays open and explains when voiding fails', (tester) async {
    repository.deleteError = const TaskRepositoryException('Offline');
    await pumpDetail(tester);

    await tester.tapVisible(find.byKey(ReceiptKeys.detailVoid));
    await tester.pumpAndSettle();

    expect(find.byType(TaskDetailPage), findsOneWidget);
    expect(find.text("COULDN'T VOID ITEM"), findsOneWidget);
  });
}
