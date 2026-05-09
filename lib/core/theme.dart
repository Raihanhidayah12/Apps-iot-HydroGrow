// lib/core/theme.dart
import 'package:flutter/material.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary,
    fontFamily: AppFonts.manrope,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.ink),
      titleTextStyle: TextStyle(
        fontFamily: AppFonts.manrope,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.ink,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: AppFonts.spaceGrotesk,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.ink,
      ),
      headlineMedium: TextStyle(
        fontFamily: AppFonts.spaceGrotesk,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.ink,
      ),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      color: AppColors.cardBg,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: Colors.white,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    primaryColor: AppColors.primary,
    fontFamily: AppFonts.manrope,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: AppFonts.spaceGrotesk,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.inkDark,
      ),
      headlineMedium: TextStyle(
        fontFamily: AppFonts.spaceGrotesk,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.inkDark,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.inkDark,
      ),
      bodyLarge: TextStyle(color: AppColors.inkMidDark),
      bodyMedium: TextStyle(color: AppColors.inkMidDark),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      color: AppColors.cardBgDark,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      surface: AppColors.cardBgDark,
      onSurface: AppColors.inkDark,
      // TAMBAHAN: Mempertegas warna saat tanggal dipilih
      primary: AppColors.primary,
      onPrimary: Colors
          .white, // Agar angka di dalam lingkaran hijau tetap putih/terbaca
    ),
    // TAMBAHAN: Memperbaiki UI DatePicker di Dark Mode
    datePickerTheme: DatePickerThemeData(
      backgroundColor:
          AppColors.backgroundDark, // Latar belakang utama pop-up kalender
      headerBackgroundColor:
          AppColors.cardBgDark, // Latar belakang bagian header kalender
      headerForegroundColor:
          AppColors.inkDark, // Warna teks pada header kalender
      surfaceTintColor: Colors
          .transparent, // Mencegah Material 3 menambahkan tint aneh pada background
    ),
  );
}
