import 'package:flutter/material.dart';

/// A comprehensive utility class for responsive design using MediaQuery
/// This class provides consistent sizing across all screen sizes and devices
class ResponsiveHelper {
  static late MediaQueryData _mediaQueryData;
  static late double _screenWidth;
  static late double _screenHeight;

  /// Initialize responsive helper with current context
  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    _screenWidth = _mediaQueryData.size.width;
    _screenHeight = _mediaQueryData.size.height;
  }

  // Screen dimensions
  static double get screenWidth => _screenWidth;
  static double get screenHeight => _screenHeight;
  static Orientation get orientation => _mediaQueryData.orientation;
  static bool get isPortrait => orientation == Orientation.portrait;
  static bool get isLandscape => orientation == Orientation.landscape;

  // Device type detection
  static bool get isMobile => _screenWidth < 600;
  static bool get isTablet => _screenWidth >= 600 && _screenWidth < 1024;
  static bool get isDesktop => _screenWidth >= 1024;

  // Responsive width calculations
  /// Returns width as percentage of screen width
  static double wp(double percentage) => _screenWidth * (percentage / 100);

  /// Returns height as percentage of screen height
  static double hp(double percentage) => _screenHeight * (percentage / 100);

  // Responsive text scaling
  /// Responsive font size based on screen width
  static double fontSize(double size) {
    if (isMobile) return size * 0.9;
    if (isTablet) return size * 1.0;
    return size * 1.1; // Desktop
  }

  // Responsive spacing
  /// Small spacing - responsive
  static double get spacingXS => wp(1); // ~4px on mobile
  static double get spacingS => wp(2); // ~8px on mobile
  static double get spacingM => wp(4); // ~16px on mobile
  static double get spacingL => wp(6); // ~24px on mobile
  static double get spacingXL => wp(8); // ~32px on mobile

  // Responsive padding
  /// Default page padding based on device type
  static EdgeInsets get defaultPadding {
    if (isMobile) return EdgeInsets.all(wp(4)); // 16px on mobile
    if (isTablet) return EdgeInsets.all(wp(3)); // ~18px on tablet
    return EdgeInsets.all(wp(2.5)); // ~26px on desktop
  }

  /// Card padding based on device type
  static EdgeInsets get cardPadding {
    if (isMobile) return EdgeInsets.all(wp(3)); // 12px on mobile
    if (isTablet) return EdgeInsets.all(wp(2.5)); // ~15px on tablet
    return EdgeInsets.all(wp(2)); // ~20px on desktop
  }

  // Responsive dimensions for common UI elements
  /// App bar height
  static double get appBarHeight {
    if (isMobile) return hp(7); // ~56px on mobile
    if (isTablet) return hp(6); // ~43px on tablet
    return hp(5.5); // ~40px on desktop
  }

  /// Button height
  static double get buttonHeight {
    if (isMobile) return hp(6); // ~48px on mobile
    if (isTablet) return hp(5.5); // ~40px on tablet
    return hp(5); // ~36px on desktop
  }

  /// Card minimum height
  static double get cardMinHeight {
    if (isMobile) return hp(12); // ~96px on mobile
    if (isTablet) return hp(10); // ~72px on tablet
    return hp(8); // ~58px on desktop
  }

  /// Icon sizes
  static double get iconSizeS => fontSize(16);
  static double get iconSizeM => fontSize(20);
  static double get iconSizeL => fontSize(24);
  static double get iconSizeXL => fontSize(32);

  // Responsive text styles
  /// Heading 1 - largest heading
  static double get h1 => fontSize(32);

  /// Heading 2 - section heading
  static double get h2 => fontSize(24);

  /// Heading 3 - subsection heading
  static double get h3 => fontSize(20);

  /// Heading 4 - small heading
  static double get h4 => fontSize(18);

  /// Body text - large
  static double get bodyL => fontSize(16);

  /// Body text - medium
  static double get bodyM => fontSize(14);

  /// Body text - small
  static double get bodyS => fontSize(12);

  /// Caption text
  static double get caption => fontSize(10);

  // Responsive border radius
  static double get radiusS => wp(1); // ~4px on mobile
  static double get radiusM => wp(2); // ~8px on mobile
  static double get radiusL => wp(3); // ~12px on mobile
  static double get radiusXL => wp(5); // ~20px on mobile

  // Container constraints
  /// Maximum width for cards/content containers
  static double get maxCardWidth {
    if (isMobile) return _screenWidth * 0.95;
    if (isTablet) return _screenWidth * 0.8;
    return _screenWidth * 0.6;
  }

  /// Maximum content width for readable text
  static double get maxContentWidth {
    if (isMobile) return _screenWidth;
    if (isTablet) return _screenWidth * 0.85;
    return _screenWidth * 0.7;
  }

  // Grid and layout helpers
  /// Number of columns for grid layouts
  static int get gridColumns {
    if (isMobile) return 1;
    if (isTablet) return 2;
    return 3;
  }

  /// Number of columns for stat cards
  static int get statCardColumns {
    if (isMobile) return 2;
    if (isTablet) return 3;
    return 4;
  }

  // Safe area helpers
  static EdgeInsets get safeAreaPadding => _mediaQueryData.padding;
  static double get statusBarHeight => _mediaQueryData.padding.top;
  static double get bottomSafeArea => _mediaQueryData.padding.bottom;

  // Keyboard and view insets
  static EdgeInsets get viewInsets => _mediaQueryData.viewInsets;
  static bool get isKeyboardOpen => viewInsets.bottom > 0;

  // Flexible sizing helpers
  /// Flexible height based on content and constraints
  static double flexibleHeight({
    required double minHeight,
    required double maxHeight,
    double percentage = 0.3,
  }) {
    final calculatedHeight = _screenHeight * percentage;
    return calculatedHeight.clamp(minHeight, maxHeight);
  }

  /// Flexible width based on content and constraints
  static double flexibleWidth({
    required double minWidth,
    required double maxWidth,
    double percentage = 0.8,
  }) {
    final calculatedWidth = _screenWidth * percentage;
    return calculatedWidth.clamp(minWidth, maxWidth);
  }

  // Layout breakpoints
  static bool get isSmallScreen => _screenWidth < 360;
  static bool get isMediumScreen => _screenWidth >= 360 && _screenWidth < 600;
  static bool get isLargeScreen => _screenWidth >= 600 && _screenWidth < 900;
  static bool get isXLargeScreen => _screenWidth >= 900;

  // Common responsive widgets
  /// Responsive SizedBox for vertical spacing
  static Widget verticalSpace(double percentage) =>
      SizedBox(height: hp(percentage));

  /// Responsive SizedBox for horizontal spacing
  static Widget horizontalSpace(double percentage) =>
      SizedBox(width: wp(percentage));

  /// Responsive flexible spacer
  static Widget flexibleSpacer({int flex = 1}) =>
      Flexible(flex: flex, child: Container());

  // Helper for responsive constraints
  static BoxConstraints responsiveConstraints({
    double? minWidth,
    double? maxWidth,
    double? minHeight,
    double? maxHeight,
  }) {
    return BoxConstraints(
      minWidth: minWidth ?? 0,
      maxWidth: maxWidth ?? _screenWidth,
      minHeight: minHeight ?? 0,
      maxHeight: maxHeight ?? _screenHeight,
    );
  }

  // Text theme helpers with responsive sizing
  static TextStyle responsiveTextStyle({
    required double baseFontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontSize: fontSize(baseFontSize),
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // Responsive elevation for cards and containers
  static double get elevation {
    if (isMobile) return 2;
    if (isTablet) return 3;
    return 4;
  }
}

/// Extension on BuildContext to easily access responsive helper
extension ResponsiveContext on BuildContext {
  /// Initialize and return responsive helper
  ResponsiveHelper get responsive {
    ResponsiveHelper.init(this);
    return ResponsiveHelper();
  }

  /// Quick access to screen dimensions
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Quick access to responsive measurements
  double wp(double percentage) {
    ResponsiveHelper.init(this);
    return ResponsiveHelper.wp(percentage);
  }

  double hp(double percentage) {
    ResponsiveHelper.init(this);
    return ResponsiveHelper.hp(percentage);
  }
}
