import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../receipt_format.dart';
import '../receipt_keys.dart';
import '../receipt_theme.dart';
import 'receipt_parts.dart';

/// One printed line: `[x] 03  Title ........ DONE  ×`
class TaskLine extends StatelessWidget {
  TaskLine({
    required this.task,
    required this.number,
    required this.onToggle,
    required this.onVoid,
    required this.onOpen,
  }) : super(key: ReceiptKeys.line(task.id));

  final Task task;
  final int number;
  final VoidCallback onToggle;
  final VoidCallback onVoid;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final done = task.isCompleted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Semantics(
            container: true,
            checked: done,
            label: done ? 'Reopen ${task.title}' : 'Mark ${task.title} as done',
            onTap: onToggle,
            excludeSemantics: true,
            child: InkWell(
              key: ReceiptKeys.lineToggle,
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                child: Text(
                  done ? '[x]' : '[ ]',
                  style: Receipt.text(weight: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            formatCount(number),
            style: Receipt.text(size: 11, color: Receipt.fadedInk),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Receipt.text(
                    color: done ? Receipt.fadedInk : Receipt.ink,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (done)
            const DoneStamp(key: ReceiptKeys.lineStamp)
          else
            Text(
              'OPEN',
              style: Receipt.text(
                size: 11,
                color: Receipt.fadedInk,
                spacing: 1.4,
              ),
            ),
          IconButton(
            key: ReceiptKeys.lineVoid,
            tooltip: 'Void ${task.title}',
            onPressed: onVoid,
            icon: const Icon(Icons.close, size: 16),
            color: Receipt.fadedInk,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
