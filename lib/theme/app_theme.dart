import 'package:flutter/material.dart';

class AppTheme {
  static const Color pitchBlack = Color(0xFF101114);
  static const Color charcoal = Color(0xFF191B20);
  static const Color card = Color(0xFF21242B);
  static const Color pintGold = Color(0xFFF4B238);
  static const Color pitchGreen = Color(0xFF14F1B2);
  static const Color calmBlue = Color(0xFF7DB7FF);
  static const Color cream = Color(0xFFFFFEF4);
  static const Color muted = Color(0xFF9BA9BC);

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: pitchGreen,
      brightness: Brightness.dark,
      primary: pitchGreen,
      secondary: pintGold,
      surface: card,
      onSurface: cream,
    );
    return _withSharedStyling(base, scheme, pitchBlack, charcoal, card, muted);
  }

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF057A60),
      brightness: Brightness.light,
      primary: const Color(0xFF057A60),
      secondary: const Color(0xFF96660A),
      surface: const Color(0xFFFFFFFF),
      onSurface: const Color(0xFF12151B),
    );
    return _withSharedStyling(base, scheme, const Color(0xFFF3F6FA), const Color(0xFFE7ECF3), Colors.white, const Color(0xFF5D6B7A));
  }

  static ThemeData _withSharedStyling(
    ThemeData base,
    ColorScheme scheme,
    Color scaffold,
    Color nav,
    Color cardColor,
    Color mutedText,
  ) {
    return base.copyWith(
      scaffoldBackgroundColor: scaffold,
      colorScheme: scheme,
      textTheme: base.textTheme.apply(
        fontFamily: 'Roboto',
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: nav,
        selectedColor: scheme.primary.withOpacity(0.18),
        labelStyle: TextStyle(color: scheme.onSurface),
        side: BorderSide(color: scheme.outline.withOpacity(0.24)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        surfaceTintColor: scaffold,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: scheme.onSurface, fontSize: 22, fontWeight: FontWeight.w700),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: nav,
        selectedItemColor: scheme.primary,
        unselectedItemColor: mutedText,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: nav,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        prefixIconColor: mutedText,
        hintStyle: TextStyle(color: mutedText),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }

  static Color subtleText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? muted : const Color(0xFF5D6B7A);
  }

  static Color softSurface(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? charcoal : const Color(0xFFE7ECF3);
  }

  static Color logoSurface(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? card : Colors.white;
  }
}
