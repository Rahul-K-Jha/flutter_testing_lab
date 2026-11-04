import 'package:flutter/material.dart';

import 'app.dart';
import 'src/data/demo_tasks.dart';
import 'src/data/in_memory_task_repository.dart';

void main() {
  runApp(
    TestingLabApp(
      repository: InMemoryTaskRepository(
        seed: demoTasks(DateTime.now()),
        // Long enough to see the "printing" state on launch.
        latency: const Duration(milliseconds: 700),
      ),
    ),
  );
}
