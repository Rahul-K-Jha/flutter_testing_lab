import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_lab/app.dart';
import 'package:flutter_testing_lab/src/data/in_memory_task_repository.dart';
import 'package:flutter_testing_lab/src/ui/receipt_keys.dart';

import '../robots/receipt_robot.dart';

/// The full user journey through the real app: real controller, real
/// repository (with latency), real navigation. Nothing is faked.
///
/// Kept as a plain function so the integration test can run it on a device.
Future<void> runFullTaskFlow(WidgetTester tester) async {
  final robot = ReceiptRobot(tester);
  await tester.pumpWidget(
    TestingLabApp(
      repository: InMemoryTaskRepository(
        latency: const Duration(milliseconds: 250),
      ),
    ),
  );

  // 1. A fresh receipt is empty.
  await robot.waitForReceipt();
  expect(find.byKey(ReceiptKeys.empty), findsOneWidget);

  // 2. Validation stops a blank item.
  await robot.addItem('   ');
  expect(robot.validationMessage, findsOneWidget);

  // 3. Add two items.
  await robot.addItem('Write widget tests');
  await robot.addItem('Set up CI');
  expect(robot.validationMessage, findsNothing);
  expect(robot.line('Write widget tests'), findsOneWidget);
  expect(robot.line('Set up CI'), findsOneWidget);
  expect(robot.total(ReceiptKeys.totalItems), '02');

  // 4. Duplicates of open items are rejected, whatever the casing.
  await robot.addItem('write WIDGET tests');
  expect(robot.validationMessage, findsOneWidget);
  expect(robot.total(ReceiptKeys.totalItems), '02');

  // 5. Mark one done straight from the list.
  await robot.toggleFromList('Write widget tests');
  expect(robot.isStamped('Write widget tests'), isTrue);
  expect(robot.total(ReceiptKeys.totalProgress), '50%');

  // 6. View the other one, mark it done there, and come back.
  await robot.openItem('Set up CI');
  expect(robot.detailStatus(), 'OPEN');
  await robot.markDoneOnDetail();
  expect(robot.detailStatus(), 'DONE');
  await robot.goBack();
  expect(robot.isStamped('Set up CI'), isTrue);
  expect(robot.total(ReceiptKeys.totalProgress), '100%');

  // 7. Void one from its detail page, the other from the list.
  await robot.openItem('Set up CI');
  await robot.voidOnDetail();
  expect(robot.line('Set up CI'), findsNothing);
  expect(find.text('ITEM VOIDED'), findsOneWidget);

  await robot.voidFromList('Write widget tests');

  // 8. Back to an empty receipt.
  expect(find.byKey(ReceiptKeys.empty), findsOneWidget);
}
