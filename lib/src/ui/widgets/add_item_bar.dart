import 'package:flutter/material.dart';

import '../../state/task_controller.dart';
import '../receipt_keys.dart';
import '../receipt_theme.dart';
import 'receipt_parts.dart';

/// Text field and PRINT button for adding a task, with inline validation.
class AddItemBar extends StatefulWidget {
  const AddItemBar({
    super.key,
    required this.controller,
    required this.enabled,
  });

  final TaskController controller;

  /// False while the receipt is loading or jammed.
  final bool enabled;

  @override
  State<AddItemBar> createState() => _AddItemBarState();
}

class _AddItemBarState extends State<AddItemBar> {
  final _text = TextEditingController();
  String? _error;

  bool get _canSubmit => widget.enabled && !widget.controller.isAdding;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final result = await widget.controller.addTask(_text.text);
    if (!mounted) return;
    setState(() {
      switch (result) {
        case TaskAdded():
          _text.clear();
          _error = null;
        case TaskRejected(:final error):
          _error = error.message;
        case TaskAddFailed(:final message):
          _error = 'Printer offline. $message';
      }
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = widget.controller.isAdding;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ADD ITEM',
          style: Receipt.text(size: 11, color: Receipt.fadedInk, spacing: 1.6),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                key: ReceiptKeys.titleField,
                controller: _text,
                enabled: widget.enabled,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                style: Receipt.text(size: 14),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'e.g. Write a golden test',
                  hintStyle: Receipt.text(size: 14, color: Receipt.fadedInk),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Receipt.fadedInk),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Receipt.ink, width: 1.5),
                  ),
                  disabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0x338A857B)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ReceiptButton(
              key: ReceiptKeys.printButton,
              label: busy ? 'PRINTING…' : 'PRINT',
              onPressed: _canSubmit ? _submit : null,
            ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              '! $_error',
              key: ReceiptKeys.validationMessage,
              style: Receipt.text(size: 12, color: Receipt.stamp),
            ),
          ),
      ],
    );
  }
}
