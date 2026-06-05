import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Colors
  static const Color bg = Color(0xFF0B1426);
  static const Color surface = Color(0xFF111D35);
  static const Color card = Color(0xFF162240);
  static const Color accent = Color(0xFF2196F3);
  static const Color accentLight = Color(0xFF64B5F6);
  static const Color green = Color(0xFF4CAF50);
  static const Color red = Color(0xFFEF5350);
  static const Color amber = Color(0xFFFFC107);
  static const Color text = Color(0xFFFFFFFF);
  static const Color textDim = Color(0xFF90A4AE);
  static const Color textMuted = Color(0xFF607D8B);
  static const Color divider = Color(0xFF1E3050);
  static const Color input = Color(0xFF0D1B30);
  static const Color mapOcean = Color(0xFF0A1628);

  static final _mono = GoogleFonts.robotoMono();
  static final _sans = GoogleFonts.inter();
  static final _sansBold = GoogleFonts.inter(fontWeight: FontWeight.w700);
  static final _sansSemi = GoogleFonts.inter(fontWeight: FontWeight.w600);

  static TextStyle get mono => _mono.copyWith(color: text, fontSize: 14, letterSpacing: 0.5);
  static TextStyle get monoSm => _mono.copyWith(color: textDim, fontSize: 12, letterSpacing: 0.3);
  static TextStyle get h1 => _sansBold.copyWith(color: text, fontSize: 22);
  static TextStyle get h2 => _sansBold.copyWith(color: text, fontSize: 16);
  static TextStyle get body => _sans.copyWith(color: textDim, fontSize: 14);
  static TextStyle get bodySm => _sans.copyWith(color: textMuted, fontSize: 12);
  static TextStyle get label => _sansSemi.copyWith(color: text, fontSize: 14);
  static TextStyle get labelSm => _sansSemi.copyWith(color: textDim, fontSize: 12);

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      secondary: green,
      error: red,
      surface: card,
      onPrimary: text,
      onSurface: text,
    ),
    fontFamily: _sans.fontFamily,
    appBarTheme: AppBarTheme(backgroundColor: surface, elevation: 0, centerTitle: true,
      titleTextStyle: _sansSemi.copyWith(color: text, fontSize: 18)),
    cardTheme: CardThemeData(color: card, elevation: 0, margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: divider))),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: input,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: divider)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: divider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: accent, width: 2))),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: text,
      minimumSize: const Size(double.infinity, 44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: _sansSemi.copyWith(fontSize: 14))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: accent,
      side: const BorderSide(color: accent), minimumSize: const Size(double.infinity, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))),
    dividerTheme: const DividerThemeData(color: divider, thickness: 1),
    chipTheme: ChipThemeData(backgroundColor: input, selectedColor: accent.withOpacity(0.2),
      labelStyle: _sansSemi.copyWith(color: text, fontSize: 13), side: const BorderSide(color: divider),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
  );
}
