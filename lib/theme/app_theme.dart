import 'package:flutter/material.dart';

class AppTheme {
  static const Color pitchBlack = Color(0xFF101114);
  static const Color charcoal = Color(0xFF191B20);
  static const Color card = Color(0xFF21242B);
  static const Color pintGold = Color(0xFFF4B238);
  static const Color pitchGreen = Color(0xFF2ECC71);
  static const Color cream = Color(0xFFFFFEF4);
  static const Color muted = Color(0xFF97A99D);

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: pitchBlack,
      colorScheme: ColorScheme.fromSeed(
        seedColor: pitchGreen,
        brightness: Brightness.dark,
        primary: pitchGreen,
        secondary: pintGold,
        surface: card,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: 'Roboto',
        bodyColor: cream,
        displayColor: cream,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: charcoal,
        selectedColor: pitchGreen.withOpacity(0.18),
        labelStyle: const TextStyle(color: cream),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: pitchBlack,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: charcoal,
        selectedItemColor: pitchGreen,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
