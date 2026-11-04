import 'package:flutter/material.dart';

import '../receipt_theme.dart';

/// Thermal paper with torn zig-zag edges top and bottom.
class ReceiptPaper extends StatelessWidget {
  const ReceiptPaper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PhysicalShape(
      clipper: const _TornEdges(),
      color: Receipt.paper,
      elevation: 12,
      shadowColor: Colors.black,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 34, 22, 34),
        child: child,
      ),
    );
  }
}

class _TornEdges extends CustomClipper<Path> {
  const _TornEdges();

  static const _toothWidth = 11.0;
  static const _depth = 5.0;

  @override
  Path getClip(Size size) {
    final teeth = (size.width / _toothWidth).ceil();
    final w = size.width / teeth;
    final bottom = size.height;
    final path = Path()..moveTo(0, _depth);
    for (var i = 0; i < teeth; i++) {
      path
        ..lineTo((i + 0.5) * w, 0)
        ..lineTo((i + 1) * w, _depth);
    }
    path.lineTo(size.width, bottom - _depth);
    for (var i = teeth - 1; i >= 0; i--) {
      path
        ..lineTo((i + 0.5) * w, bottom)
        ..lineTo(i * w, bottom - _depth);
    }
    return path..close();
  }

  @override
  bool shouldReclip(_TornEdges oldClipper) => false;
}

/// `- - - - - -` separator.
class DashedRule extends StatelessWidget {
  const DashedRule({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashPainter()),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Receipt.fadedInk
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, 0.5), Offset(x + 3.5, 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => false;
}

/// `=======` separator above the add bar.
class DoubleRule extends StatelessWidget {
  const DoubleRule({super.key});

  @override
  Widget build(BuildContext context) {
    const line = ColoredBox(color: Receipt.ink, child: SizedBox(height: 1));
    return const Column(children: [line, SizedBox(height: 2.5), line]);
  }
}

/// A rubber "DONE" stamp, slightly crooked like a real one.
class DoneStamp extends StatelessWidget {
  const DoneStamp({super.key, this.label = 'DONE'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.09,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          border: Border.all(color: Receipt.stamp, width: 1.5),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          label,
          style: Receipt.text(
            size: 11,
            color: Receipt.stamp,
            weight: FontWeight.w700,
            spacing: 1.6,
          ),
        ),
      ),
    );
  }
}

/// A boxed, all-caps receipt button.
class ReceiptButton extends StatelessWidget {
  const ReceiptButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? Receipt.stamp : Receipt.ink;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        disabledForegroundColor: Receipt.fadedInk,
        side: BorderSide(
          color: onPressed == null ? Receipt.fadedInk : color,
          width: 1.5,
        ),
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: Receipt.text(weight: FontWeight.w700, spacing: 1.6),
      ),
      child: Text(label),
    );
  }
}

/// `LABEL ............ VALUE` row used in the totals and on the item stub.
class LabelValueRow extends StatelessWidget {
  const LabelValueRow({
    super.key,
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final Widget value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: Receipt.text(
              weight: bold ? FontWeight.w700 : FontWeight.w400,
              spacing: 1.2,
            ),
          ),
          const Spacer(),
          value,
        ],
      ),
    );
  }
}

/// Decorative barcode. Bars are derived from [seed], so the code changes as
/// the receipt does. Hidden from screen readers.
class Barcode extends StatelessWidget {
  const Barcode({super.key, required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: 46,
        width: double.infinity,
        child: CustomPaint(painter: _BarcodePainter(seed)),
      ),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  _BarcodePainter(this.seed);

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Receipt.ink;
    var state = seed & 0x7fffffff;
    int next() => state = (state * 1103515245 + 12345) & 0x7fffffff;

    final inset = size.width * 0.12;
    var x = inset;
    while (x < size.width - inset) {
      final bar = 1.0 + next() % 3;
      final gap = 1.0 + next() % 3;
      canvas.drawRect(Rect.fromLTWH(x, 0, bar, size.height), paint);
      x += bar + gap;
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter oldDelegate) => oldDelegate.seed != seed;
}

void showReceiptSnack(ScaffoldMessengerState messenger, String message) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
