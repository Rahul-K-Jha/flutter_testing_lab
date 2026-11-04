import 'package:flutter/material.dart';

abstract final class Receipt {
  /// The dark counter the receipt lies on.
  static const counter = Color(0xFF1D1C1A);
  static const paper = Color(0xFFF6F2E8);
  static const ink = Color(0xFF26231F);
  static const fadedInk = Color(0xFF8A857B);
  static const stamp = Color(0xFFC23F2B);

  static const font = 'RobotoMono';

  static TextStyle text({
    double size = 13,
    Color color = ink,
    FontWeight weight = FontWeight.w400,
    double spacing = 0.4,
    TextDecoration? decoration,
  }) => TextStyle(
    fontFamily: font,
    fontSize: size,
    color: color,
    fontWeight: weight,
    letterSpacing: spacing,
    height: 1.35,
    decoration: decoration,
    decorationColor: color,
    decorationThickness: 1.6,
  );

  static ThemeData theme() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: font,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ink,
        surface: paper,
        primary: ink,
        error: stamp,
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: counter,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: ink,
        selectionColor: Color(0x3326231F),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: paper,
        contentTextStyle: text(weight: FontWeight.w700, spacing: 1.2),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(),
        elevation: 6,
      ),
    );
  }
}
