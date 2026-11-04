import 'package:flutter/material.dart';

import 'src/data/in_memory_task_repository.dart';
import 'src/data/task_repository.dart';
import 'src/state/task_controller.dart';
import 'src/ui/receipt_page.dart';
import 'src/ui/receipt_theme.dart';

/// Root widget. The repository and clock are injected so tests can run the
/// real app against fakes.
class TestingLabApp extends StatefulWidget {
  const TestingLabApp({
    super.key,
    required this.repository,
    this.clock = DateTime.now,
  });

  final TaskRepository repository;
  final Clock clock;

  @override
  State<TestingLabApp> createState() => _TestingLabAppState();
}

class _TestingLabAppState extends State<TestingLabApp> {
  late final _controller = TaskController(widget.repository)..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Testing Lab',
      debugShowCheckedModeBanner: false,
      theme: Receipt.theme(),
      home: ReceiptPage(controller: _controller, clock: widget.clock),
    );
  }
}
