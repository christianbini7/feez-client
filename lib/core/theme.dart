import 'package:flutter/material.dart';

// ── Couleurs Feez ─────────────────────────────────────────────────
class FeezColors {
  static const red       = Color(0xFFE8192C);   // Feez Market
  static const redDark   = Color(0xFFC01020);
  static const redSoft   = Color(0xFFFFE6E9);
  static const food      = Color(0xFFFF6B00);   // Feez Food
  static const foodDark  = Color(0xFFCC5500);
  static const foodSoft  = Color(0xFFFFF0E6);
  static const green     = Color(0xFF00C47A);   // Livreur
  static const ink       = Color(0xFF0D0D0D);
  static const mid       = Color(0xFF555555);
  static const low       = Color(0xFF999999);
  static const line      = Color(0xFFEBEBEB);
  static const white     = Color(0xFFFFFFFF);
  static const off       = Color(0xFFF5F5F5);
}

// ── Typographie Feez ──────────────────────────────────────────────
class FeezText {
  static const display = TextStyle(
    fontFamily: 'BarlowCondensed',
    fontWeight: FontWeight.w900,
    letterSpacing: -0.02,
  );

  static const body = TextStyle(
    fontFamily: 'DMSans',
    fontWeight: FontWeight.w400,
  );

  static TextStyle displaySize(double size, {Color? color, bool italic = false}) =>
    display.copyWith(fontSize: size, color: color, fontStyle: italic ? FontStyle.italic : FontStyle.normal);

  static TextStyle bodySize(double size, {Color? color, FontWeight? weight}) =>
    body.copyWith(fontSize: size, color: color, fontWeight: weight);
}

// ── Thème global ──────────────────────────────────────────────────
ThemeData feezTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'DMSans',
    colorScheme: ColorScheme.fromSeed(
      seedColor: FeezColors.red,
      primary: FeezColors.red,
    ),
    scaffoldBackgroundColor: FeezColors.off,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: FeezColors.ink,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: FeezColors.red,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'BarlowCondensed',
          fontSize: 17,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.03,
        ),
      ),
    ),
  );
}
