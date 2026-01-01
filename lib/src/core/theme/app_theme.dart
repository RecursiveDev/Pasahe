import 'package:flutter/material.dart';

import 'transit_colors.dart';

/// Application theme configuration with Archipelago Blue color palette.
/// Deep teal primary paired with energetic orange accents,
/// inspired by the Philippine seas and islands.
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // ============================================
  // LIGHT MODE - Archipelago Blue Theme
  // Optimized for outdoor visibility under strong tropical sunlight
  // ============================================

  // Primary Colors (Deep Teal)
  static const Color _lightPrimary = Color(0xFF006064); // Deep Teal
  static const Color _lightOnPrimary = Color(0xFFFFFFFF);
  static const Color _lightPrimaryContainer = Color(0xFFE0F7FA); // Coastal Foam
  static const Color _lightOnPrimaryContainer = Color(
    0xFF001F23,
  ); // Deepest Teal

  // Secondary Colors (Pacific Blue)
  static const Color _lightSecondary = Color(0xFF0097A7); // Pacific Blue
  static const Color _lightOnSecondary = Color(0xFFFFFFFF);
  static const Color _lightSecondaryContainer = Color(0xFFD6F7FC); // Reef Mist
  static const Color _lightOnSecondaryContainer = Color(
    0xFF001F25,
  ); // Deep Reef

  // Tertiary Colors (Lifevest Orange)
  static const Color _lightTertiary = Color(0xFFFF6F00); // Lifevest Orange
  static const Color _lightOnTertiary = Color(0xFF210A00); // Deep Brown
  static const Color _lightTertiaryContainer = Color(0xFFFFDCC2); // Sunset Glow
  static const Color _lightOnTertiaryContainer = Color(
    0xFF3E1800,
  ); // Burnt Orange

  // Error Colors
  static const Color _lightError = Color(0xFFBA1A1A);
  static const Color _lightOnError = Color(0xFFFFFFFF);

  // Surface & Background Colors
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightOnSurface = Color(0xFF191C1C); // Ink Grey
  static const Color _lightSurfaceVariant = Color(
    0xFFDAE4E5,
  ); // Neutral Variant
  static const Color _lightOnSurfaceVariant = Color(0xFF3F4949); // Text Variant
  static const Color _lightOutline = Color(0xFF6F7979); // Outline Grey
  static const Color _lightBackground = Color(0xFFF5FDFE); // Mist

  // ============================================
  // DARK MODE - Archipelago Blue Theme
  // Optimized for OLED displays and night commuting comfort
  // ============================================

  // Primary Colors (Cyan Aqua - pastel for dark mode)
  static const Color _darkPrimary = Color(0xFF4DD0E1); // Cyan Aqua
  static const Color _darkOnPrimary = Color(0xFF00363A); // Deep Teal
  static const Color _darkPrimaryContainer = Color(0xFF004F52); // Teal Depth
  static const Color _darkOnPrimaryContainer = Color(0xFFE0F7FA); // Cyan Light

  // Secondary Colors (Reef Blue)
  static const Color _darkSecondary = Color(0xFF80DEEA); // Reef Blue
  static const Color _darkOnSecondary = Color(0xFF00363D); // Deep Reef
  static const Color _darkSecondaryContainer = Color(
    0xFF004F58,
  ); // Pacific Depth
  static const Color _darkOnSecondaryContainer = Color(0xFFD6F7FC); // Reef Mist

  // Tertiary Colors (Coral)
  static const Color _darkTertiary = Color(0xFFFFB74D); // Coral
  static const Color _darkOnTertiary = Color(0xFF452300); // Deep Brown
  static const Color _darkTertiaryContainer = Color(0xFF633300); // Orange Depth
  static const Color _darkOnTertiaryContainer = Color(0xFFFFDCC2); // Peach

  // Error Colors
  static const Color _darkError = Color(0xFFFFB4AB); // Soft Error
  static const Color _darkOnError = Color(0xFF690005); // Dark Red

  // Surface & Background Colors - 2025 Material Design 3 Standards
  // Moved from Abyss/Deep Sea to recommended dark grey tones for better comfort
  static const Color _darkSurface = Color(0xFF121212); // Primary Surface
  static const Color _darkOnSurface = Color(0xFFE0E3E3); // Soft White
  static const Color _darkSurfaceVariant = Color(0xFF2C2C2C); // Container Highest
  static const Color _darkOnSurfaceVariant = Color(0xFFBEC8C9); // Metal Text
  static const Color _darkOutline = Color(0xFF899393); // Soft Outline
  static const Color _darkBackground = Color(0xFF121212); // Baseline Background

  // Surface Container Roles (M3 2025)
  static const Color _darkSurfaceContainerLow = Color(0xFF161616);
  static const Color _darkSurfaceContainer = Color(0xFF1A1A1A);
  static const Color _darkSurfaceContainerHigh = Color(0xFF232323);
  static const Color _darkSurfaceBright = Color(0xFF3A3A3A);

  /// Light theme for the application.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: _lightPrimary,
        onPrimary: _lightOnPrimary,
        primaryContainer: _lightPrimaryContainer,
        onPrimaryContainer: _lightOnPrimaryContainer,
        secondary: _lightSecondary,
        onSecondary: _lightOnSecondary,
        secondaryContainer: _lightSecondaryContainer,
        onSecondaryContainer: _lightOnSecondaryContainer,
        tertiary: _lightTertiary,
        onTertiary: _lightOnTertiary,
        tertiaryContainer: _lightTertiaryContainer,
        onTertiaryContainer: _lightOnTertiaryContainer,
        error: _lightError,
        onError: _lightOnError,
        surface: _lightSurface,
        onSurface: _lightOnSurface,
        surfaceContainerLowest: _lightBackground, // App background
        surfaceContainerHighest: _lightSurfaceVariant,
        onSurfaceVariant: _lightOnSurfaceVariant,
        outline: _lightOutline,
        outlineVariant: _lightSurfaceVariant,
      ),

      // Typography
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),

      // Component Themes
      cardTheme: CardThemeData(
        elevation:
            0, // Flat by default for modern look, outline handles separation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _lightSurfaceVariant, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF2F2F2),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightError, width: 1),
        ),
        labelStyle: const TextStyle(color: Color(0xFF757575)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightPrimary,
          foregroundColor: _lightOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _lightPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
          side: const BorderSide(color: _lightPrimary),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _lightOnSurface,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: _lightOnSurface),
      ),

      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: _lightPrimaryContainer,
        indicatorColor: _lightPrimary.withValues(alpha: 0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _lightPrimary);
          }
          return const IconThemeData(color: Color(0xFF757575));
        }),
      ),

      // Theme Extensions
      extensions: const <ThemeExtension<dynamic>>[TransitColors.light],
    );
  }

  /// Dark theme for the application.
  /// Optimized for OLED displays and night commuting comfort.
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: _darkPrimary,
        onPrimary: _darkOnPrimary,
        primaryContainer: _darkPrimaryContainer,
        onPrimaryContainer: _darkOnPrimaryContainer,
        secondary: _darkSecondary,
        onSecondary: _darkOnSecondary,
        secondaryContainer: _darkSecondaryContainer,
        onSecondaryContainer: _darkOnSecondaryContainer,
        tertiary: _darkTertiary,
        onTertiary: _darkOnTertiary,
        tertiaryContainer: _darkTertiaryContainer,
        onTertiaryContainer: _darkOnTertiaryContainer,
        error: _darkError,
        onError: _darkOnError,
        surface: _darkSurface,
        onSurface: _darkOnSurface,
        surfaceContainerLowest: _darkBackground,
        surfaceContainerLow: _darkSurfaceContainerLow,
        surfaceContainer: _darkSurfaceContainer,
        surfaceContainerHigh: _darkSurfaceContainerHigh,
        surfaceContainerHighest: _darkSurfaceVariant,
        surfaceBright: _darkSurfaceBright,
        onSurfaceVariant: _darkOnSurfaceVariant,
        outline: _darkOutline,
        outlineVariant: _darkSurfaceVariant,
      ),

      // Typography - MUST match light theme for consistent layout
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),

      // Card theme - MUST match light theme structure for consistent layout
      cardTheme: CardThemeData(
        elevation: 0, // Same as light theme
        color: _darkSurfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _darkSurfaceVariant, width: 1),
        ),
        margin: EdgeInsets.zero, // Same as light theme
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkPrimary, width: 2),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimary,
          foregroundColor: _darkOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      // Outlined button theme - MUST match light theme for consistent layout
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
          side: const BorderSide(color: _darkPrimary),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      // AppBar theme - MUST match light theme for consistent layout
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _darkOnSurface,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: _darkOnSurface),
      ),

      navigationBarTheme: NavigationBarThemeData(
        elevation: 0, // Same as light theme
        backgroundColor: _darkSurfaceContainer,
        indicatorColor: _darkPrimary.withValues(alpha: 0.2),
        labelBehavior: NavigationDestinationLabelBehavior
            .alwaysShow, // Same as light theme
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _darkPrimary);
          }
          return const IconThemeData(color: _darkOnSurfaceVariant);
        }),
      ),

      // Theme Extensions
      extensions: const <ThemeExtension<dynamic>>[TransitColors.dark],
    );
  }
}
