import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_lab/src/ui/receipt_format.dart';

void main() {
  test('formatReceiptDate prints a zero-padded day and short month', () {
    expect(formatReceiptDate(DateTime(2026, 11, 4)), '04 NOV 2026');
    expect(formatReceiptDate(DateTime(2027, 1, 31)), '31 JAN 2027');
  });

  test('formatReceiptTime uses a zero-padded 24-hour clock', () {
    expect(formatReceiptTime(DateTime(2026, 1, 1, 9, 5)), '09:05');
    expect(formatReceiptTime(DateTime(2026, 1, 1, 23, 59)), '23:59');
  });

  test('formatCount pads to two digits but never truncates', () {
    expect(formatCount(0), '00');
    expect(formatCount(7), '07');
    expect(formatCount(123), '123');
  });
}
