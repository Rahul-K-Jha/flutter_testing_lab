import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_lab/src/models/task.dart';
import 'package:flutter_testing_lab/src/ui/receipt_keys.dart';
import 'package:flutter_testing_lab/src/ui/widgets/task_line.dart';

import '../helpers/test_tasks.dart';

void main() {
  /// Pumps one [TaskLine] in isolation and records which callback fired.
  Future<List<String>> pumpLine(WidgetTester tester, Task task) async {
    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TaskLine(
            task: task,
            number: 7,
            onToggle: () => calls.add('toggle'),
            onVoid: () => calls.add('void'),
            onOpen: () => calls.add('open'),
          ),
        ),
      ),
    );
    return calls;
  }

  TextStyle titleStyle(WidgetTester tester, String title) =>
      tester.widget<Text>(find.text(title)).style!;

  testWidgets('prints an open task with its number and OPEN status', (
    tester,
  ) async {
    await pumpLine(tester, buildTask(title: 'Write tests'));

    expect(find.text('[ ]'), findsOneWidget);
    expect(find.text('07'), findsOneWidget);
    expect(find.text('OPEN'), findsOneWidget);
    expect(find.byKey(ReceiptKeys.lineStamp), findsNothing);
    expect(
      titleStyle(tester, 'Write tests').decoration,
      isNot(TextDecoration.lineThrough),
    );
  });

  testWidgets('strikes through a done task and stamps it', (tester) async {
    await pumpLine(tester, buildTask(title: 'Write tests', done: true));

    expect(find.text('[x]'), findsOneWidget);
    expect(find.byKey(ReceiptKeys.lineStamp), findsOneWidget);
    expect(find.text('OPEN'), findsNothing);
    expect(
      titleStyle(tester, 'Write tests').decoration,
      TextDecoration.lineThrough,
    );
  });

  testWidgets('routes each tap target to its own callback', (tester) async {
    final calls = await pumpLine(tester, buildTask(title: 'Write tests'));

    await tester.tap(find.byKey(ReceiptKeys.lineToggle));
    await tester.tap(find.text('Write tests'));
    await tester.tap(find.byKey(ReceiptKeys.lineVoid));

    expect(calls, ['toggle', 'open', 'void']);
  });

  testWidgets('exposes the toggle to screen readers as a checkbox', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpLine(tester, buildTask(title: 'Write tests', done: true));

    expect(
      tester.getSemantics(find.byKey(ReceiptKeys.lineToggle)),
      isSemantics(
        label: 'Reopen Write tests',
        hasCheckedState: true,
        isChecked: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('labels the void button for screen readers', (tester) async {
    await pumpLine(tester, buildTask(title: 'Write tests'));

    expect(find.byTooltip('Void Write tests'), findsOneWidget);
  });
}
