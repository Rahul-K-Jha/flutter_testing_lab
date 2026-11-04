import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_lab/app.dart';
import 'package:flutter_testing_lab/src/data/task_repository.dart';
import 'package:flutter_testing_lab/src/ui/receipt_keys.dart';

import 'test_tasks.dart';

extension PumpApp on WidgetTester {
  /// Pumps the real app against [repository] with a fixed clock.
  ///
  /// Only the first frame is pumped, so the loading state is still on
  /// screen. Call [pumpAndSettle] to let the initial load finish.
  Future<void> pumpLab(TaskRepository repository) async {
    await pumpWidget(
      TestingLabApp(repository: repository, clock: () => kTestNow),
    );
  }

  /// Taps [finder] after scrolling it into view. The receipt is long, and
  /// widgets below the 800x600 test surface can't receive taps.
  Future<void> tapVisible(Finder finder) async {
    await ensureVisible(finder);
    await pumpAndSettle();
    await tap(finder);
  }
}

/// Finds a widget inside the line for task [taskId].
Finder inLine(String taskId, Finder matching) => find.descendant(
  of: find.byKey(ReceiptKeys.line(taskId)),
  matching: matching,
);

/// The text shown by the widget with [key], e.g. a totals value.
String textOf(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;
