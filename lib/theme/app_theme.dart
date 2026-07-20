import 'package:flutter/material.dart';

// Dark, vibrant dashboard aesthetic — deep navy/charcoal base with saturated
// gradient accent colors per stat/category, matching modern SaaS dashboard
// conventions rather than a flat corporate light theme.
class AppTheme {
  static const bgDark = Color(0xFF0F1117);
  static const surfaceDark = Color(0xFF1A1D2B);
  static const surfaceDark2 = Color(0xFF23273B);
  static const textPrimary = Color(0xFFF2F3F8);
  static const textSecondary = Color(0xFF9A9DB5);
  static const secondary = Color(0xFF6C5CE7);

  // Gradient pairs used for stat cards / category accents — cycle through
  // these for each card so the dashboard reads as colorful and alive rather
  // than monochrome, matching the reference dashboards.
  static const gradients = [
    [Color(0xFF6C5CE7), Color(0xFF00CEC9)], // purple -> teal
    [Color(0xFFFF7675), Color(0xFFFDCB6E)], // coral -> amber
    [Color(0xFF00B894), Color(0xFF55EFC4)], // green -> mint
    [Color(0xFF0984E3), Color(0xFF74B9FF)], // blue -> sky
    [Color(0xFFE84393), Color(0xFFFD79A8)], // pink -> rose
    [Color(0xFFFDCB6E), Color(0xFFE17055)], // amber -> burnt orange
  ];

  static const success = Color(0xFF00B894);
  static const warning = Color(0xFFFDCB6E);
  static const danger = Color(0xFFFF7675);
  static const primary = secondary;

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: secondary,
      brightness: Brightness.dark,
      surface: surfaceDark,
      primary: secondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgDark,

      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5, color: textPrimary),
        headlineSmall: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.3, color: textPrimary),
        titleLarge: TextStyle(fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: TextStyle(height: 1.4, color: textPrimary),
        bodyMedium: TextStyle(height: 1.4, color: textSecondary),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        foregroundColor: textPrimary,
        elevation: 0,
        surfaceTintColor: bgDark,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.3),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceDark,
        surfaceTintColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.transparent,
        textColor: textPrimary,
        iconColor: textSecondary,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: secondary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: danger, width: 1.2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceDark2,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textPrimary),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surfaceDark,
        indicatorColor: secondary.withValues(alpha: 0.25),
        selectedIconTheme: const IconThemeData(color: secondary),
        unselectedIconTheme: const IconThemeData(color: textSecondary),
        selectedLabelTextStyle: const TextStyle(color: secondary, fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelTextStyle: const TextStyle(color: textSecondary, fontSize: 12),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceDark,
        indicatorColor: secondary.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? secondary : textSecondary,
          );
        }),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        surfaceTintColor: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: textPrimary),
      ),

      dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: 0.06), thickness: 1),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceDark2,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
