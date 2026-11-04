import 'package:flutter/material.dart';

import '../data/in_memory_task_repository.dart';
import '../logic/task_summary.dart';
import '../models/task.dart';
import '../state/task_controller.dart';
import 'receipt_format.dart';
import 'receipt_keys.dart';
import 'receipt_theme.dart';
import 'task_detail_page.dart';
import 'widgets/add_item_bar.dart';
import 'widgets/receipt_parts.dart';
import 'widgets/state_views.dart';
import 'widgets/task_line.dart';

/// The whole task list, printed as one long receipt.
class ReceiptPage extends StatelessWidget {
  const ReceiptPage({super.key, required this.controller, required this.clock});

  final TaskController controller;
  final Clock clock;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final status = controller.status;
            final tasks = controller.tasks;
            final summary = controller.summary;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 48),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: ReceiptPaper(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Header(now: clock()),
                        const SizedBox(height: 16),
                        const DashedRule(),
                        const SizedBox(height: 8),
                        const _ColumnLabels(),
                        const SizedBox(height: 4),
                        _body(context, status, tasks),
                        const SizedBox(height: 10),
                        const DashedRule(),
                        const SizedBox(height: 12),
                        if (status == LoadStatus.ready && tasks.isNotEmpty) ...[
                          _Totals(summary: summary),
                          const SizedBox(height: 14),
                        ],
                        const DoubleRule(),
                        const SizedBox(height: 18),
                        AddItemBar(
                          controller: controller,
                          enabled: status == LoadStatus.ready,
                        ),
                        const SizedBox(height: 28),
                        Barcode(seed: Object.hash(summary, tasks.length)),
                        const SizedBox(height: 12),
                        Text(
                          'THANK YOU FOR TESTING',
                          textAlign: TextAlign.center,
                          style: Receipt.text(
                            weight: FontWeight.w700,
                            spacing: 2,
                          ),
                        ),
                        Text(
                          '*** KEEP THIS RECEIPT ***',
                          textAlign: TextAlign.center,
                          style: Receipt.text(
                            size: 11,
                            color: Receipt.fadedInk,
                            spacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _body(BuildContext context, LoadStatus status, List<Task> tasks) {
    switch (status) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.failure:
        return ErrorView(
          message: controller.errorMessage ?? '',
          onRetry: controller.load,
        );
      case LoadStatus.ready when tasks.isEmpty:
        return const EmptyView();
      case LoadStatus.ready:
        return Column(
          children: [
            for (final (i, task) in tasks.indexed)
              TaskLine(
                task: task,
                number: i + 1,
                onToggle: () => _toggle(context, task),
                onVoid: () => _void(context, task),
                onOpen: () => _open(context, task),
              ),
          ],
        );
    }
  }

  Future<void> _toggle(BuildContext context, Task task) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await controller.toggle(task.id)) {
      showReceiptSnack(messenger, "COULDN'T UPDATE ITEM. CHANGE UNDONE.");
    }
  }

  Future<void> _void(BuildContext context, Task task) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await controller.delete(task.id);
    showReceiptSnack(messenger, ok ? 'ITEM VOIDED' : "COULDN'T VOID ITEM");
  }

  void _open(BuildContext context, Task task) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskDetailPage(controller: controller, taskId: task.id),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final faded = Receipt.text(size: 12, color: Receipt.fadedInk, spacing: 1);
    return Column(
      children: [
        Text(
          'FLUTTER TESTING LAB',
          textAlign: TextAlign.center,
          style: Receipt.text(size: 17, weight: FontWeight.w700, spacing: 2.4),
        ),
        const SizedBox(height: 2),
        Text('TASK RECEIPT', style: faded.copyWith(letterSpacing: 3)),
        const SizedBox(height: 14),
        Row(
          children: [
            Text(formatReceiptDate(now), style: faded),
            const Spacer(),
            Text(formatReceiptTime(now), style: faded),
          ],
        ),
      ],
    );
  }
}

class _ColumnLabels extends StatelessWidget {
  const _ColumnLabels();

  @override
  Widget build(BuildContext context) {
    final style = Receipt.text(size: 11, color: Receipt.fadedInk, spacing: 1.6);
    return ExcludeSemantics(
      child: Row(
        children: [
          Text('    NO  ITEM', style: style),
          const Spacer(),
          Text('STATUS     ', style: style),
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.summary});

  final TaskSummary summary;

  @override
  Widget build(BuildContext context) {
    Text value(Key key, String text, {bool bold = false}) => Text(
      text,
      key: key,
      style: Receipt.text(weight: bold ? FontWeight.w700 : FontWeight.w400),
    );

    return Column(
      key: ReceiptKeys.totals,
      children: [
        LabelValueRow(
          label: 'OPEN',
          value: value(ReceiptKeys.totalOpen, formatCount(summary.open)),
        ),
        LabelValueRow(
          label: 'DONE',
          value: value(ReceiptKeys.totalDone, formatCount(summary.done)),
        ),
        LabelValueRow(
          label: 'TOTAL ITEMS',
          bold: true,
          value: value(
            ReceiptKeys.totalItems,
            formatCount(summary.total),
            bold: true,
          ),
        ),
        LabelValueRow(
          label: 'PROGRESS',
          value: value(ReceiptKeys.totalProgress, '${summary.percentDone}%'),
        ),
      ],
    );
  }
}
