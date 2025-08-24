import 'package:flutter/material.dart';
import 'dart:math';

class AccessibilityUtils {
  /// Calculate relative luminance for color contrast checking
  static double _getRelativeLuminance(Color color) {
    double rsRGB = color.r / 255.0;
    double gsRGB = color.g / 255.0;
    double bsRGB = color.b / 255.0;

    double r = rsRGB <= 0.03928 ? rsRGB / 12.92 : pow((rsRGB + 0.055) / 1.055, 2.4).toDouble();
    double g = gsRGB <= 0.03928 ? gsRGB / 12.92 : pow((gsRGB + 0.055) / 1.055, 2.4).toDouble();
    double b = bsRGB <= 0.03928 ? bsRGB / 12.92 : pow((bsRGB + 0.055) / 1.055, 2.4).toDouble();

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Calculate contrast ratio between two colors
  static double getContrastRatio(Color color1, Color color2) {
    double luminance1 = _getRelativeLuminance(color1);
    double luminance2 = _getRelativeLuminance(color2);

    double lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    double darker = luminance1 > luminance2 ? luminance2 : luminance1;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check if contrast ratio meets WCAG AA standards
  static bool meetsWCAGAA(Color foreground, Color background, {bool isLargeText = false}) {
    double contrastRatio = getContrastRatio(foreground, background);
    double requiredRatio = isLargeText ? 3.0 : 4.5;
    return contrastRatio >= requiredRatio;
  }

  /// Check if contrast ratio meets WCAG AAA standards
  static bool meetsWCAGAAA(Color foreground, Color background, {bool isLargeText = false}) {
    double contrastRatio = getContrastRatio(foreground, background);
    double requiredRatio = isLargeText ? 4.5 : 7.0;
    return contrastRatio >= requiredRatio;
  }

  /// Get accessible text color based on background
  static Color getAccessibleTextColor(Color background, {Color? lightText, Color? darkText}) {
    lightText ??= Colors.white;
    darkText ??= Colors.black;

    double contrastWithLight = getContrastRatio(lightText, background);
    double contrastWithDark = getContrastRatio(darkText, background);

    return contrastWithLight > contrastWithDark ? lightText : darkText;
  }

  /// Get scalable font size based on system text scale factor
  static double getScalableFontSize(BuildContext context, double baseSize) {
    final textScaler = MediaQuery.of(context).textScaler;
    return textScaler.scale(baseSize);
  }

  /// Get minimum touch target size (44x44 logical pixels)
  static double getMinTouchTargetSize(BuildContext context) {
    return 44.0 * MediaQuery.of(context).devicePixelRatio;
  }

  /// Check if text should be considered large for accessibility
  static bool isLargeText(double fontSize, {bool isBold = false}) {
    if (isBold) {
      return fontSize >= 14.0;
    }
    return fontSize >= 18.0;
  }

  /// Get accessible button size based on platform
  static Size getAccessibleButtonSize(BuildContext context, {double? minWidth, double? minHeight}) {
    final minTouchSize = getMinTouchTargetSize(context);
    return Size(
      minWidth ?? minTouchSize,
      minHeight ?? minTouchSize,
    );
  }

  /// Create accessible text style with proper contrast
  static TextStyle createAccessibleTextStyle({
    required BuildContext context,
    required Color backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    Color? textColor,
    bool isLargeText = false,
  }) {
    final effectiveFontSize = fontSize ?? Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14.0;
    final effectiveTextColor = textColor ?? getAccessibleTextColor(backgroundColor);
    
    // Ensure contrast meets WCAG standards
    if (!meetsWCAGAA(effectiveTextColor, backgroundColor, isLargeText: isLargeText)) {
      // Try to find a better color
      final accessibleColor = getAccessibleTextColor(backgroundColor);
      if (meetsWCAGAA(accessibleColor, backgroundColor, isLargeText: isLargeText)) {
        return TextStyle(
          fontSize: getScalableFontSize(context, effectiveFontSize),
          fontWeight: fontWeight,
          color: accessibleColor,
        );
      }
    }

    return TextStyle(
      fontSize: getScalableFontSize(context, effectiveFontSize),
      fontWeight: fontWeight,
      color: effectiveTextColor,
    );
  }
}

/// Extension to add accessibility methods to Color
extension ColorAccessibility on Color {
  /// Get accessible text color for this background color
  Color get accessibleTextColor => AccessibilityUtils.getAccessibleTextColor(this);

  /// Check if this color provides good contrast with another color
  bool hasGoodContrastWith(Color other, {bool isLargeText = false}) {
    return AccessibilityUtils.meetsWCAGAA(this, other, isLargeText: isLargeText);
  }

  /// Get contrast ratio with another color
  double contrastRatioWith(Color other) {
    return AccessibilityUtils.getContrastRatio(this, other);
  }
}
