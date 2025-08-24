import 'package:flutter/material.dart';

class AppTheme {
  // Color palette
  static const Color _primaryBlue = Color(0xFF2196F3);
  static const Color _primaryBlueDark = Color(0xFF1976D2);
  static const Color _primaryBlueLight = Color(0xFFBBDEFB);
  
  static const Color _secondaryGreen = Color(0xFF4CAF50);
  static const Color _secondaryGreenDark = Color(0xFF388E3C);
  static const Color _secondaryGreenLight = Color(0xFFC8E6C9);
  
  static const Color _accentOrange = Color(0xFFFF9800);
  static const Color _accentOrangeDark = Color(0xFFF57C00);
  static const Color _accentOrangeLight = Color(0xFFFFE0B2);
  
  static const Color _errorRed = Color(0xFFF44336);
  static const Color _errorRedDark = Color(0xFFD32F2F);
  static const Color _errorRedLight = Color(0xFFFFCDD2);
  


  // Color scheme for light theme
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: _primaryBlue,
    onPrimary: Colors.white,
    secondary: _secondaryGreen,
    onSecondary: Colors.white,
    tertiary: _accentOrange,
    onTertiary: Colors.white,
    error: _errorRed,
    onError: Colors.white,
    background: Colors.white,
    onBackground: Color(0xFF1C1B1F),
    surface: Colors.white,
    onSurface: Color(0xFF1C1B1F),
    surfaceContainer: Color(0xFFFEFEFE),
    surfaceContainerHigh: Color(0xFFF8F9FA),
    surfaceContainerLow: Color(0xFFFCFCFC),
    surfaceContainerLowest: Colors.white,
    outline: Color(0xFF79747E),
    outlineVariant: Color(0xFFCAC4D0),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF313033),
    onInverseSurface: Color(0xFFF4EFF4),
    inversePrimary: _primaryBlueLight,
    surfaceTint: _primaryBlue,
  );

  // Dark theme colors
  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: _primaryBlueLight,
    onPrimary: _primaryBlueDark,
    primaryContainer: _primaryBlueDark,
    onPrimaryContainer: _primaryBlueLight,
    secondary: _secondaryGreenLight,
    onSecondary: _secondaryGreenDark,
    secondaryContainer: _secondaryGreenDark,
    onSecondaryContainer: _secondaryGreenLight,
    tertiary: _accentOrangeLight,
    onTertiary: _accentOrangeDark,
    tertiaryContainer: _accentOrangeDark,
    onTertiaryContainer: _accentOrangeLight,
    error: _errorRedLight,
    onError: _errorRedDark,
    errorContainer: _errorRedDark,
    onErrorContainer: _errorRedLight,
    surface: Color(0xFF1C1B1F),
    onSurface: Color(0xFFE6E1E5),
    surfaceContainerHighest: Color(0xFF2D2D30),
    surfaceContainerHigh: Color(0xFF2A2A2D),
    surfaceContainer: Color(0xFF252528),
    surfaceContainerLow: Color(0xFF202023),
    surfaceContainerLowest: Color(0xFF1C1B1F),
    outline: Color(0xFF938F99),
    outlineVariant: Color(0xFF49454F),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE6E1E5),
    onInverseSurface: Color(0xFF313033),
    inversePrimary: _primaryBlueDark,
  );

  // Typography
  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      height: 1.12,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.16,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.22,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.25,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.29,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.33,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.27,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      height: 1.5,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.43,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.33,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.33,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.45,
    ),
  );

  // Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: _lightColorScheme,
      textTheme: _textTheme,
      
      // App bar theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _lightColorScheme.surface,
        foregroundColor: _lightColorScheme.onSurface,
        titleTextStyle: _textTheme.titleLarge?.copyWith(
          color: _lightColorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          color: _lightColorScheme.onSurface,
          size: 24,
        ),
      ),

      // Card theme
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: _lightColorScheme.shadow.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: _lightColorScheme.surface,
        surfaceTintColor: _lightColorScheme.primary.withValues(alpha: 0.05),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shadowColor: _lightColorScheme.shadow.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightColorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _lightColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _lightColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _lightColorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _lightColorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _lightColorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: _textTheme.bodyMedium?.copyWith(
          color: _lightColorScheme.onSurfaceVariant,
        ),
        hintStyle: _textTheme.bodyMedium?.copyWith(
          color: _lightColorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),

      // Icon theme
      iconTheme: IconThemeData(
        color: _lightColorScheme.onSurfaceVariant,
        size: 24,
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: _lightColorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: _lightColorScheme.surfaceContainerLow,
        selectedColor: _lightColorScheme.primaryContainer,
        disabledColor: _lightColorScheme.surfaceContainerLow.withValues(alpha: 0.38),
        labelStyle: _textTheme.bodyMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _lightColorScheme.primary,
        foregroundColor: _lightColorScheme.onPrimary,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _lightColorScheme.surface,
        selectedItemColor: _lightColorScheme.primary,
        unselectedItemColor: _lightColorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Progress indicator theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: _lightColorScheme.primary,
        linearTrackColor: _lightColorScheme.surfaceContainerLow,
        circularTrackColor: _lightColorScheme.surfaceContainerLow,
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _lightColorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _darkColorScheme,
      textTheme: _textTheme,
      
      // App bar theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _darkColorScheme.surface,
        foregroundColor: _darkColorScheme.onSurface,
        titleTextStyle: _textTheme.titleLarge?.copyWith(
          color: _darkColorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          color: _darkColorScheme.onSurface,
          size: 24,
        ),
      ),

      // Card theme
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: _darkColorScheme.shadow.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: _darkColorScheme.surface,
        surfaceTintColor: _darkColorScheme.primary.withValues(alpha: 0.05),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shadowColor: _darkColorScheme.shadow.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkColorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _darkColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _darkColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _darkColorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _darkColorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _darkColorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: _textTheme.bodyMedium?.copyWith(
          color: _darkColorScheme.onSurfaceVariant,
        ),
        hintStyle: _textTheme.bodyMedium?.copyWith(
          color: _darkColorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),

      // Icon theme
      iconTheme: IconThemeData(
        color: _darkColorScheme.onSurfaceVariant,
        size: 24,
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: _darkColorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: _darkColorScheme.surfaceContainerLow,
        selectedColor: _darkColorScheme.primaryContainer,
        disabledColor: _darkColorScheme.surfaceContainerLow.withValues(alpha: 0.38),
        labelStyle: _textTheme.bodyMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _darkColorScheme.primary,
        foregroundColor: _darkColorScheme.onPrimary,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _darkColorScheme.surface,
        selectedItemColor: _darkColorScheme.primary,
        unselectedItemColor: _darkColorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Progress indicator theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: _darkColorScheme.primary,
        linearTrackColor: _darkColorScheme.surfaceContainerLow,
        circularTrackColor: _darkColorScheme.surfaceContainerLow,
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkColorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Get theme based on brightness
  static ThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkTheme : lightTheme;
  }
}
