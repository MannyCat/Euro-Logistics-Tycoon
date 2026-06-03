import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color scaffoldBackground = Color(0xFF0B1426);
  static const Color cardBackground = Color(0xFF14213D);
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color profitGreen = Color(0xFF4CAF50);
  static const Color lossRed = Color(0xFFF44336);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGray = Color(0xFF9E9E9E);
  static const Color textGrayLight = Color(0xFFBDBDBD);
  static const Color dividerColor = Color(0xFF1E3A5F);
  static const Color inputBackground = Color(0xFF0D1B30);
  static const Color warningAmber = Color(0xFFFFC107);
  static const Color surfaceDark = Color(0xFF091020);

  static final _monoFont = GoogleFonts.robotoMono();
  static final _sansFont = GoogleFonts.inter();
  static final _sansBold = GoogleFonts.inter(fontWeight: FontWeight.w700);
  static final _sansSemi = GoogleFonts.inter(fontWeight: FontWeight.w600);
  static final _sansMed = GoogleFonts.inter(fontWeight: FontWeight.w500);

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
        primary: accentBlue,
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
          borderSide: const BorderSide(color: accentBlue, width: 2),
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
          backgroundColor: accentBlue,
          foregroundColor: textWhite,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: _sansSemi.copyWith(fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentBlue,
          textStyle: _sansMed.copyWith(fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentBlue,
          side: const BorderSide(color: accentBlue),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: _sansSemi.copyWith(fontSize: 15),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: accentBlue,
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
        selectedColor: accentBlue.withValues(alpha: 0.2),
        labelStyle: _sansMed.copyWith(color: textWhite, fontSize: 13),
        side: const BorderSide(color: dividerColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentBlue,
        foregroundColor: textWhite,
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
        labelColor: accentBlue,
        unselectedLabelColor: textGray,
        indicatorColor: accentBlue,
        dividerColor: Colors.transparent,
      ),
    );
  }
}
