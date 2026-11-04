import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_lab/src/ui/receipt_keys.dart';
import 'package:flutter_testing_lab/src/ui/widgets/task_line.dart';

/// Page object for the receipt. Tests describe what a user does
/// ("add an item", "void it") and the robot knows how to find widgets.
///
/// Works on a real device (the integration binding, real time) and under
/// `flutter test` (fake time), because all waiting is done with `pump`.
class ReceiptRobot {
  ReceiptRobot(this.tester);

  final WidgetTester tester;

  /// Pumps frames until [condition] holds, failing after [timeout].
  ///
  /// The repository takes real time to answer and the loading bar never
  /// settles, so `pumpAndSettle` alone can't wait for data.
  Future<void> pumpUntil(
    bool Function() condition, {
    required String waitingFor,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    const step = Duration(milliseconds: 100);
    var waited = Duration.zero;
    while (!condition()) {
      if (waited >= timeout) {
        fail('Timed out after $timeout waiting for $waitingFor');
      }
      await tester.pump(step);
      waited += step;
    }
    await tester.pumpAndSettle();
  }

  Future<void> pumpUntilFound(Finder finder) =>
      pumpUntil(() => finder.evaluate().isNotEmpty, waitingFor: '$finder');

  Future<void> pumpUntilGone(Finder finder) =>
      pumpUntil(() => finder.evaluate().isEmpty, waitingFor: 'no $finder');

  /// Waits for the initial "printing" state to finish.
  Future<void> waitForReceipt() async {
    await tester.pump();
    await pumpUntilGone(find.byKey(ReceiptKeys.loading));
  }

  Finder line(String title) => find.widgetWithText(TaskLine, title);

  Finder get validationMessage => find.byKey(ReceiptKeys.validationMessage);

  Future<void> addItem(String title) async {
    await tester.enterText(find.byKey(ReceiptKeys.titleField), title);
    await _tap(find.byKey(ReceiptKeys.printButton));
    // The save is done once the button stops saying PRINTING….
    await pumpUntilFound(
      find.descendant(
        of: find.byKey(ReceiptKeys.printButton),
        matching: find.text('PRINT'),
      ),
    );
  }

  Future<void> toggleFromList(String title) =>
      _tap(_inLine(title, ReceiptKeys.lineToggle));

  Future<void> voidFromList(String title) async {
    await _tap(_inLine(title, ReceiptKeys.lineVoid));
    await pumpUntilGone(line(title));
  }

  Future<void> openItem(String title) async {
    await _tap(find.descendant(of: line(title), matching: find.text(title)));
    await pumpUntilFound(find.byKey(ReceiptKeys.detailTitle));
  }

  Future<void> markDoneOnDetail() => _tap(find.byKey(ReceiptKeys.detailToggle));

  Future<void> voidOnDetail() async {
    await _tap(find.byKey(ReceiptKeys.detailVoid));
    await pumpUntilGone(find.byKey(ReceiptKeys.detailTitle));
  }

  Future<void> goBack() async {
    await tester.pageBack();
    await tester.pumpAndSettle();
  }

  bool isStamped(String title) => find
      .descendant(of: line(title), matching: find.byKey(ReceiptKeys.lineStamp))
      .evaluate()
      .isNotEmpty;

  String detailStatus() {
    final status = find.byKey(ReceiptKeys.detailStatus);
    final open = find.descendant(
      of: status,
      matching: find.text('OPEN'),
      matchRoot: true,
    );
    return open.evaluate().isNotEmpty ? 'OPEN' : 'DONE';
  }

  String total(Key key) => tester.widget<Text>(find.byKey(key)).data!;

  Finder _inLine(String title, Key key) =>
      find.descendant(of: line(title), matching: find.byKey(key));

  Future<void> _tap(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }
}
