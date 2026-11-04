import 'package:flutter/material.dart';

import '../models/task.dart';
import '../state/task_controller.dart';
import 'receipt_format.dart';
import 'receipt_keys.dart';
import 'receipt_theme.dart';
import 'widgets/receipt_parts.dart';

/// A single task, shown as a tear-off stub.
class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({
    super.key,
    required this.controller,
    required this.taskId,
  });

  final TaskController controller;
  final String taskId;

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  /// Kept so the stub doesn't flash "not found" while popping after a void.
  Task? _lastSeen;

  Future<void> _toggle() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await widget.controller.toggle(widget.taskId)) {
      showReceiptSnack(messenger, "COULDN'T UPDATE ITEM. CHANGE UNDONE.");
    }
  }

  Future<void> _void() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (await widget.controller.delete(widget.taskId)) {
      navigator.pop();
      showReceiptSnack(messenger, 'ITEM VOIDED');
    } else {
      showReceiptSnack(messenger, "COULDN'T VOID ITEM");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Receipt.paper,
        title: Text(
          'ITEM DETAIL',
          style: Receipt.text(
            size: 14,
            color: Receipt.paper,
            weight: FontWeight.w700,
            spacing: 2,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final task = widget.controller.taskById(widget.taskId) ?? _lastSeen;
          _lastSeen = task;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: ReceiptPaper(
                  child: task == null ? const _NotFound() : _stub(task),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _stub(Task task) {
    final done = task.isCompleted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ITEM STUB',
          textAlign: TextAlign.center,
          style: Receipt.text(size: 11, color: Receipt.fadedInk, spacing: 3),
        ),
        const SizedBox(height: 14),
        Text(
          task.title,
          key: ReceiptKeys.detailTitle,
          textAlign: TextAlign.center,
          style: Receipt.text(size: 20, weight: FontWeight.w700, spacing: 0.2),
        ),
        const SizedBox(height: 18),
        const DashedRule(),
        const SizedBox(height: 12),
        LabelValueRow(
          label: 'STATUS',
          value: done
              ? const DoneStamp(key: ReceiptKeys.detailStatus)
              : Text(
                  'OPEN',
                  key: ReceiptKeys.detailStatus,
                  style: Receipt.text(weight: FontWeight.w700, spacing: 1.4),
                ),
        ),
        LabelValueRow(
          label: 'PRINTED',
          value: Text(
            '${formatReceiptDate(task.createdAt)}  '
            '${formatReceiptTime(task.createdAt)}',
            style: Receipt.text(),
          ),
        ),
        LabelValueRow(
          label: 'ITEM ID',
          value: Text(task.id.toUpperCase(), style: Receipt.text()),
        ),
        const SizedBox(height: 12),
        const DashedRule(),
        const SizedBox(height: 20),
        ReceiptButton(
          key: ReceiptKeys.detailToggle,
          label: done ? 'REOPEN ITEM' : 'MARK AS DONE',
          onPressed: _toggle,
        ),
        const SizedBox(height: 10),
        ReceiptButton(
          key: ReceiptKeys.detailVoid,
          label: 'VOID ITEM',
          danger: true,
          onPressed: _void,
        ),
      ],
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return Text(
      'ITEM NOT FOUND',
      textAlign: TextAlign.center,
      style: Receipt.text(weight: FontWeight.w700, spacing: 1.6),
    );
  }
}
