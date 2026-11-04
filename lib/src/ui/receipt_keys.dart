import 'package:flutter/widgets.dart';

/// Stable keys for the widgets tests interact with, so finders never depend
/// on copy or layout.
abstract final class ReceiptKeys {
  static const loading = Key('receipt-loading');
  static const empty = Key('receipt-empty');
  static const error = Key('receipt-error');
  static const retryButton = Key('receipt-retry');
  static const totals = Key('receipt-totals');
  static const totalOpen = Key('receipt-total-open');
  static const totalDone = Key('receipt-total-done');
  static const totalItems = Key('receipt-total-items');
  static const totalProgress = Key('receipt-total-progress');

  static const titleField = Key('add-title-field');
  static const printButton = Key('add-print-button');
  static const validationMessage = Key('add-validation-message');

  /// A whole task line; its toggle and void buttons use the keys below and
  /// are found with `find.descendant(of: line, ...)`.
  static Key line(String taskId) => ValueKey('task-line-$taskId');
  static const lineToggle = Key('task-line-toggle');
  static const lineVoid = Key('task-line-void');
  static const lineStamp = Key('task-line-done-stamp');

  static const detailTitle = Key('detail-title');
  static const detailStatus = Key('detail-status');
  static const detailToggle = Key('detail-toggle');
  static const detailVoid = Key('detail-void');
}
