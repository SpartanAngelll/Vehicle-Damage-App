import 'package:flutter/material.dart';
import '../utils/accessibility_utils.dart';

class AccessibilityTheme {
  /// Create an accessible color scheme with proper contrast ratios
  static ColorScheme createAccessibleColorScheme({
    required Color primary,
    required Color surface,
    required Color onSurface,
    bool isDark = false,
  }) {
    // Ensure primary color has good contrast with surface
    final accessiblePrimary = _ensureAccessibleContrast(primary, surface);
    final accessibleOnPrimary = _ensureAccessibleContrast(Colors.white, accessiblePrimary);
    
    // Ensure onSurface has good contrast with surface
    final accessibleOnSurface = _ensureAccessibleContrast(onSurface, surface);
    
    // Create surface variants with proper contrast
    final surfaceContainer = _createSurfaceContainer(surface, isDark);

    return ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: accessiblePrimary,
      onPrimary: accessibleOnPrimary,
      primaryContainer: accessiblePrimary.withValues(alpha: 0.1),
      onPrimaryContainer: accessibleOnPrimary,
      secondary: accessiblePrimary,
      onSecondary: accessibleOnPrimary,
      secondaryContainer: accessiblePrimary.withValues(alpha: 0.1),
      onSecondaryContainer: accessibleOnPrimary,
      tertiary: accessiblePrimary,
      onTertiary: accessibleOnPrimary,
      tertiaryContainer: accessiblePrimary.withValues(alpha: 0.1),
      onTertiaryContainer: accessibleOnPrimary,
      error: Colors.red[600]!,
      onError: Colors.white,
      errorContainer: Colors.red[100]!,
      onErrorContainer: Colors.red[900]!,
      surface: surface,
      onSurface: accessibleOnSurface,
      surfaceContainerHighest: surfaceContainer,
      surfaceContainerHigh: surfaceContainer.withValues(alpha: 0.8),
      surfaceContainer: surfaceContainer.withValues(alpha: 0.6),
      surfaceContainerLow: surfaceContainer.withValues(alpha: 0.4),
      surfaceContainerLowest: surfaceContainer.withValues(alpha: 0.2),
      outline: accessibleOnSurface.withValues(alpha: 0.3),
      outlineVariant: accessibleOnSurface.withValues(alpha: 0.2),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: accessibleOnSurface,
      onInverseSurface: surface,
      inversePrimary: accessiblePrimary,
    );
  }

  /// Ensure a color has good contrast with its background
  static Color _ensureAccessibleContrast(Color foreground, Color background) {
    if (AccessibilityUtils.meetsWCAGAA(foreground, background)) {
      return foreground;
    }

    // Try to find a better color by adjusting lightness
    final hsl = HSLColor.fromColor(foreground);
    
    // Try lighter version
    var adjustedColor = hsl.withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0));
    if (AccessibilityUtils.meetsWCAGAA(adjustedColor.toColor(), background)) {
      return adjustedColor.toColor();
    }

    // Try darker version
    adjustedColor = hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0));
    if (AccessibilityUtils.meetsWCAGAA(adjustedColor.toColor(), background)) {
      return adjustedColor.toColor();
    }

    // Fall back to the most contrasting color
    return AccessibilityUtils.getAccessibleTextColor(background);
  }

  /// Create a surface container color with proper contrast
  static Color _createSurfaceContainer(Color surface, bool isDark) {
    if (isDark) {
      return surface.withValues(alpha: 0.8);
    } else {
      return surface.withValues(alpha: 0.95);
    }
  }

  /// Create accessible text theme with proper contrast
  static TextTheme createAccessibleTextTheme({
    required ColorScheme colorScheme,
    required TextTheme baseTextTheme,
  }) {
    return TextTheme(
      displayLarge: _createAccessibleTextStyle(
        baseTextTheme.displayLarge,
        colorScheme.onSurface,
        colorScheme.surface,
      ),
      displayMedium: _createAccessibleTextStyle(
        baseTextTheme.displayMedium,
        colorScheme.onSurface,
        colorScheme.surface,
      ),
      displaySmall: _createAccessibleTextStyle(
        baseTextTheme.displaySmall,
        colorScheme.onSurface,
        colorScheme.surface,
      ),
      headlineLarge: _createAccessibleTextStyle(
        baseTextTheme.headlineLarge,
        colorScheme.onSurface,
        colorScheme.surface,
      ),
      headlineMedium: _createAccessibleTextStyle(
        baseTextTheme.headlineMedium,
        colorScheme.onSurface,
        colorScheme.surface,
      ),
      headlineSmall: _createAccessibleTextStyle(
        baseTextTheme.headlineSmall,
        colorScheme.onSurface,
        colorScheme.surface,
      ),
      titleLarge: _createAccessibleTextStyle(
        baseTextTheme.titleLarge,
        colorScheme.onSurface,
        colorScheme.surface,
      ),
      titleMedium: _createAccessibleTextStyle(
        baseTextTheme.titleMedium,
        colorScheme.onSurface,
        colorScheme.surface,
      ),
      titleSmall: _createAccessibleTextStyle(
        baseTextTheme.titleSmall,
        colorScheme.onSurface,
        colorScheme.surface,
      ),
      bodyLarge: _createAccessibleTextStyle(
        baseTextTheme.bodyLarge,
        colorScheme.onSurface,
        colorScheme.surface,
      ),
      bodyMedium: _createAccessibleTextStyle(
        baseTextTheme.bodyMedium,
        colorScheme.onSurface,
        colorScheme.surface,
      ),
      bodySmall: _createAccessibleTextStyle(
        baseTextTheme.bodySmall,
        colorScheme.onSurface,
        colorScheme.surface,
      ),
      labelLarge: _createAccessibleTextStyle(
        baseTextTheme.labelLarge,
        colorScheme.onSurface,
        colorScheme.surface,
      ),
      labelMedium: _createAccessibleTextStyle(
        baseTextTheme.labelMedium,
        colorScheme.onSurface,
        colorScheme.surface,
      ),
      labelSmall: _createAccessibleTextStyle(
        baseTextTheme.labelSmall,
        colorScheme.onSurface,
        colorScheme.surface,
      ),
    );
  }

  /// Create accessible text style with proper contrast
  static TextStyle? _createAccessibleTextStyle(
    TextStyle? baseStyle,
    Color foreground,
    Color background,
  ) {
    if (baseStyle == null) return null;

    final accessibleForeground = _ensureAccessibleContrast(foreground, background);
    
    return baseStyle.copyWith(
      color: accessibleForeground,
      // Ensure font size is accessible (minimum 12px for body text)
      fontSize: baseStyle.fontSize != null 
          ? (baseStyle.fontSize! < 12.0 ? 12.0 : baseStyle.fontSize!)
          : null,
    );
  }

  /// Create accessible input decoration theme
  static InputDecorationTheme createAccessibleInputTheme({
    required ColorScheme colorScheme,
    required InputDecorationTheme baseTheme,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: _ensureAccessibleContrast(
            colorScheme.outline,
            colorScheme.surfaceContainerLow,
          ),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: _ensureAccessibleContrast(
            colorScheme.outline,
            colorScheme.surfaceContainerLow,
          ),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: colorScheme.error,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: colorScheme.error,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: baseTheme.labelStyle?.copyWith(
        color: _ensureAccessibleContrast(
          colorScheme.onSurfaceVariant,
          colorScheme.surfaceContainerLow,
        ),
      ),
      hintStyle: baseTheme.hintStyle?.copyWith(
        color: _ensureAccessibleContrast(
          colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          colorScheme.surfaceContainerLow,
        ),
      ),
    );
  }

  /// Create accessible button theme with proper touch targets
  static ElevatedButtonThemeData createAccessibleElevatedButtonTheme({
    required ColorScheme colorScheme,
    required ElevatedButtonThemeData baseTheme,
  }) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        // Ensure minimum touch target size
        minimumSize: const Size(44, 44),
      ),
    );
  }
}
