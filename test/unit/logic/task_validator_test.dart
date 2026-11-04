import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_lab/src/logic/task_validator.dart';

import '../../helpers/test_tasks.dart';

void main() {
  group('TaskValidator.normalize', () {
    test('trims and collapses whitespace', () {
      expect(
        TaskValidator.normalize('  Write   unit\ttests \n'),
        'Write unit tests',
      );
    });

    test('keeps the original casing', () {
      expect(TaskValidator.normalize('Run CI'), 'Run CI');
    });
  });

  group('TaskValidator.validate', () {
    test('accepts a normal title', () {
      expect(TaskValidator.validate('Write unit tests'), isNull);
    });

    test('rejects empty and whitespace-only titles', () {
      for (final raw in ['', ' ', '\t\n  ']) {
        expect(
          TaskValidator.validate(raw),
          TaskValidationError.empty,
          reason: 'input: "$raw"',
        );
      }
    });

    group('length limit', () {
      final atLimit = 'a' * TaskValidator.maxLength;

      test('accepts exactly maxLength characters', () {
        expect(TaskValidator.validate(atLimit), isNull);
      });

      test('rejects one character over maxLength', () {
        expect(
          TaskValidator.validate('${atLimit}a'),
          TaskValidationError.tooLong,
        );
      });

      test('measures the normalized title, not the raw input', () {
        expect(TaskValidator.validate('   $atLimit   '), isNull);
      });
    });

    group('duplicates', () {
      final existing = [
        buildTask(id: '1', title: 'Write unit tests'),
        buildTask(id: '2', title: 'Set up CI', done: true),
      ];

      test('rejects a title matching an open task', () {
        expect(
          TaskValidator.validate('Write unit tests', existing: existing),
          TaskValidationError.duplicate,
        );
      });

      test('ignores case and extra whitespace when comparing', () {
        expect(
          TaskValidator.validate('  WRITE  unit tests ', existing: existing),
          TaskValidationError.duplicate,
        );
      });

      test('allows re-adding a title whose task is already done', () {
        expect(TaskValidator.validate('Set up CI', existing: existing), isNull);
      });
    });

    test('reports the empty rule before any other', () {
      expect(
        TaskValidator.validate('   ', existing: [buildTask(title: '')]),
        TaskValidationError.empty,
      );
    });
  });

  test('every error has a user-facing message', () {
    for (final error in TaskValidationError.values) {
      expect(error.message, isNotEmpty);
    }
    expect(
      TaskValidationError.tooLong.message,
      contains('${TaskValidator.maxLength}'),
    );
  });
}
