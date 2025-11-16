import 'package:flutter/material.dart';

class ResponsiveUtils {
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 900;
  static const double _desktopBreakpoint = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < _mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= _mobileBreakpoint &&
      MediaQuery.of(context).size.width < _tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= _desktopBreakpoint;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  static bool isPortrait(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  static double getScreenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double getScreenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static double getResponsiveFontSize(BuildContext context, {
    double mobile = 16.0,
    double tablet = 18.0,
    double desktop = 20.0,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static double getResponsivePadding(BuildContext context, {
    double mobile = 16.0,
    double tablet = 24.0,
    double desktop = 32.0,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static double getResponsiveIconSize(BuildContext context, {
    double mobile = 24.0,
    double tablet = 32.0,
    double desktop = 40.0,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static EdgeInsets getResponsiveEdgeInsets(BuildContext context, {
    EdgeInsets? mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    if (isMobile(context)) {
      return mobile ?? EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return tablet ?? EdgeInsets.all(24.0);
    } else {
      return desktop ?? EdgeInsets.all(32.0);
    }
  }

  static double getResponsiveButtonHeight(BuildContext context, {
    double mobile = 50.0,
    double tablet = 60.0,
    double desktop = 70.0,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static double getResponsiveButtonWidth(BuildContext context, {
    double mobile = 220.0,
    double tablet = 280.0,
    double desktop = 320.0,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static double getResponsiveWidth(BuildContext context, {
    double mobile = 400.0,
    double tablet = 500.0,
    double desktop = 600.0,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  /// Get maximum content width for web layouts based on screen size
  static double getWebMaxWidth(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    if (screenWidth > 1920) {
      return 1600; // Ultra-wide screens
    } else if (screenWidth > 1600) {
      return 1400; // Large desktop
    } else if (screenWidth > 1280) {
      return 1200; // Standard desktop
    } else if (screenWidth > 1024) {
      return 1000; // Small desktop/large tablet
    } else {
      return screenWidth; // Tablet and below - use full width
    }
  }

  /// Get responsive padding for web content areas
  static EdgeInsets getWebContentPadding(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    if (screenWidth > 1600) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    } else if (screenWidth > 1280) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    } else {
      return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
    }
  }
}
