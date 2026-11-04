import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'flows/task_flow.dart';

/// Runs on a real device or desktop:
///
///     flutter test integration_test -d linux     # or an Android/iOS device
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('add, view, complete and void tasks end to end', runFullTaskFlow);
}
