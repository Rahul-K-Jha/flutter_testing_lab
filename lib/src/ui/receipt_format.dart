const _months = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

String _two(int n) => n.toString().padLeft(2, '0');

/// `04 NOV 2026`
String formatReceiptDate(DateTime d) =>
    '${_two(d.day)} ${_months[d.month - 1]} ${d.year}';

/// `09:05`, 24-hour.
String formatReceiptTime(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

/// Line numbers and counts are printed with at least two digits: `07`, `12`.
String formatCount(int n) => _two(n);
