// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color background    = Color(0xFFF4F1EC);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color divider       = Color(0xFFEAE5DC);
  static const Color primary       = Color(0xFF5B7FFF);
  static const Color primaryDark   = Color(0xFF3D5FE0);
  static const Color income        = Color(0xFF22C55E);
  static const Color expense       = Color(0xFFEF4444);
  static const Color warning       = Color(0xFFF59E0B);
  static const Color textPrimary   = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted     = Color(0xFF9CA3AF);

  // Category icon backgrounds (soft pastel circles)
  static const Map<String, Color> catBg = {
    'home':                   Color(0xFFE8F0FF),
    'restaurant':             Color(0xFFFFF3E0),
    'directions_car':         Color(0xFFE8F5E9),
    'shopping_bag':           Color(0xFFFCE4EC),
    'favorite':               Color(0xFFFFEBEE),
    'sports_esports':         Color(0xFFEDE7F6),
    'school':                 Color(0xFFE3F2FD),
    'bolt':                   Color(0xFFF5F5F5),
    'account_balance_wallet': Color(0xFFE8F5E9),
    'more_horiz':             Color(0xFFF5F5F5),
  };
  static const Map<String, Color> catFg = {
    'home':                   Color(0xFF5B7FFF),
    'restaurant':             Color(0xFFFF9800),
    'directions_car':         Color(0xFF4CAF50),
    'shopping_bag':           Color(0xFFE91E63),
    'favorite':               Color(0xFFF44336),
    'sports_esports':         Color(0xFF9C27B0),
    'school':                 Color(0xFF2196F3),
    'bolt':                   Color(0xFF9E9E9E),
    'account_balance_wallet': Color(0xFF4CAF50),
    'more_horiz':             Color(0xFF757575),
  };

  static const List<Color> chart = [
    Color(0xFF5B7FFF), Color(0xFF3B82F6), Color(0xFF22C55E),
    Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFF8B5CF6),
    Color(0xFF06B6D4), Color(0xFF9CA3AF),
  ];
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.income,
      surface: AppColors.surface,
      error: AppColors.expense,
    ),
    textTheme: const TextTheme(
      displayLarge:   TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5),
      displayMedium:  TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.3),
      headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      titleLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      bodyLarge:      TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
      bodyMedium:     TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
      labelSmall:     TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface, elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        elevation: 0, minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.expense, minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: const BorderSide(color: AppColors.expense),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: AppColors.surface,
      border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.expense)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.expense, width: 1.5)),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle:  const TextStyle(color: AppColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
