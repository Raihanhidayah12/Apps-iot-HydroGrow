// lib/core/constants.dart
import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFFF8FAFC);
  static const Color backgroundLight = Color(0xFFF0FDF4); // Very light emerald
  
  // Dark Backgrounds
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color cardBgDark = Color(0xFF1E293B); // Slate 800
  
  // Brand Colors
  static const Color primary = Color(0xFF10B981); // Emerald
  static const Color primaryDark = Color(0xFF059669);
  static const Color primaryDim = primaryDark;
  static const Color primaryLight = Color(0xFFD1FAE5);
  static const Color primaryGlow = Color(0x1A10B981);
  
  static const Color secondary = Color(0xFF3B82F6); // Blue
  static const Color accent = Color(0xFF8B5CF6); // Purple
  
  // Neutral Colors
  static const Color ink = Color(0xFF0F172A); // Slate 900
  static const Color inkMid = Color(0xFF334155); // Slate 700
  static const Color inkSoft = Color(0xFF64748B); // Slate 500
  static const Color inkLighter = Color(0xFF94A3B8); // Slate 400
  
  // Dark Neutral Colors
  static const Color inkDark = Color(0xFFF8FAFC);
  static const Color inkMidDark = Color(0xFFE2E8F0);
  static const Color inkSoftDark = Color(0xFF94A3B8);
  
  static const Color stroke = Color(0xFFE2E8F0); // Slate 200
  static const Color strokeDark = Color(0xFF334155);
  
  static const Color cardBg = Colors.white;
  
  // Status Colors
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldDim = Color(0xFFD1FAE5);
  static const Color orange = Color(0xFFF59E0B);
  static const Color red = Color(0xFFEF4444);
  static const Color info = Color(0xFF0EA5E9);
}

class AppFonts {
  static const String spaceGrotesk = 'Space Grotesk';
  static const String manrope = 'Manrope';
}

class AppConstants {
  static const String appName = "HydroGrow";
  static const String telegramBotToken =
      "8689463097:AAEe4cQ8zDFytP6wqT3Kgq6zNDo18RWa7dU";
  static const String telegramChatId = "6346972285";
}
