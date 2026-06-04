import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PirateTheme {
  // Warm brown/gold/dark red pirate colors
  static const Color scaffoldBackground = Color(0xFF1A0F0A);
  static const Color cardBackground = Color(0xFF2D1B12);
  static const Color accentPrimary = Color(0xFFD4A843); // gold
  static const Color profitGreen = Color(0xFF5B8C3E);
  static const Color lossRed = Color(0xFFC0392B);
  static const Color textWhite = Color(0xFFF5E6D3); // parchment white
  static const Color textGray = Color(0xFF9E8B78);
  static const Color textGrayLight = Color(0xFFC4A882);
  static const Color dividerColor = Color(0xFF4A2E1C);
  static const Color inputBackground = Color(0xFF1E120A);
  static const Color warningAmber = Color(0xFFFFC107);
  static const Color surfaceDark = Color(0xFF120A06);

  static final _monoFont = GoogleFonts.crimsonText();
  static final _sansFont = GoogleFonts.crimsonPro();
  static final _sansBold = GoogleFonts.crimsonPro(fontWeight: FontWeight.w700);
  static final _sansSemi = GoogleFonts.crimsonPro(fontWeight: FontWeight.w600);
  static final _sansMed = GoogleFonts.crimsonPro(fontWeight: FontWeight.w500);

  static TextStyle get monoNumber => _monoFont.copyWith(
        color: textWhite,
        fontSize: 14,
        letterSpacing: 0.5,
      );

  static TextStyle get monoNumberLarge => _monoFont.copyWith(
        color: textWhite,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      );

  static TextStyle get monoNumberSmall => _monoFont.copyWith(
        color: textGrayLight,
        fontSize: 12,
        letterSpacing: 0.3,
      );

  static TextStyle get labelLarge => _sansBold.copyWith(
        color: textWhite,
        fontSize: 16,
      );

  static TextStyle get labelMedium => _sansSemi.copyWith(
        color: textWhite,
        fontSize: 14,
      );

  static TextStyle get labelSmall => _sansMed.copyWith(
        color: textGrayLight,
        fontSize: 12,
      );

  static TextStyle get bodyText => _sansFont.copyWith(
        color: textGrayLight,
        fontSize: 14,
      );

  static TextStyle get bodyTextSmall => _sansFont.copyWith(
        color: textGray,
        fontSize: 12,
      );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldBackground,
      colorScheme: const ColorScheme.dark(
        primary: accentPrimary,
        secondary: profitGreen,
        error: lossRed,
        surface: cardBackground,
        onPrimary: textWhite,
        onSecondary: textWhite,
        onError: textWhite,
        onSurface: textWhite,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _sansSemi.copyWith(
          color: textWhite,
          fontSize: 18,
        ),
        iconTheme: const IconThemeData(color: textWhite),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: dividerColor, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accentPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: lossRed),
        ),
        hintStyle: _sansFont.copyWith(color: textGray, fontSize: 14),
        labelStyle: _sansMed.copyWith(color: textGrayLight, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPrimary,
          foregroundColor: const Color(0xFF1A0F0A),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: _sansSemi.copyWith(fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentPrimary,
          textStyle: _sansMed.copyWith(fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentPrimary,
          side: const BorderSide(color: accentPrimary),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: _sansSemi.copyWith(fontSize: 15),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: accentPrimary,
        unselectedItemColor: textGray,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardBackground,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: inputBackground,
        selectedColor: accentPrimary.withValues(alpha: 0.2),
        labelStyle: _sansMed.copyWith(color: textWhite, fontSize: 13),
        side: const BorderSide(color: dividerColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentPrimary,
        foregroundColor: Color(0xFF1A0F0A),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: _sansBold.copyWith(
          color: textWhite,
          fontSize: 18,
        ),
        contentTextStyle: _sansFont.copyWith(
          color: textGrayLight,
          fontSize: 14,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: accentPrimary,
        unselectedLabelColor: textGray,
        indicatorColor: accentPrimary,
        dividerColor: Colors.transparent,
      ),
    );
  }
}
