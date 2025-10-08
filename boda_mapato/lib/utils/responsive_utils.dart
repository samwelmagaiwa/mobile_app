import "package:flutter/material.dart";
import "package:flutter_screenutil/flutter_screenutil.dart";

class ResponsiveUtils {
  // Screen size breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Check device type
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  // Get responsive value based on screen size
  static T getResponsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }

  // Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) =>
      EdgeInsets.symmetric(
        horizontal: getResponsiveValue(
          context,
          mobile: 16.w,
          tablet: 24.w,
          desktop: 32.w,
        ),
        vertical: getResponsiveValue(
          context,
          mobile: 16.h,
          tablet: 20.h,
          desktop: 24.h,
        ),
      );

  // Get responsive margin
  static EdgeInsets getResponsiveMargin(BuildContext context) =>
      EdgeInsets.symmetric(
        horizontal: getResponsiveValue(
          context,
          mobile: 8.w,
          tablet: 12.w,
          desktop: 16.w,
        ),
        vertical: getResponsiveValue(
          context,
          mobile: 8.h,
          tablet: 10.h,
          desktop: 12.h,
        ),
      );

  // Get responsive font size
  static double getResponsiveFontSize(
    BuildContext context,
    double baseFontSize,
  ) =>
      getResponsiveValue(
        context,
        mobile: baseFontSize.sp,
        tablet: (baseFontSize * 1.1).sp,
        desktop: (baseFontSize * 1.2).sp,
      );

  // Get responsive icon size
  static double getResponsiveIconSize(
    BuildContext context,
    double baseIconSize,
  ) =>
      getResponsiveValue(
        context,
        mobile: baseIconSize.w,
        tablet: (baseIconSize * 1.1).w,
        desktop: (baseIconSize * 1.2).w,
      );

  // Get responsive button height
  static double getResponsiveButtonHeight(BuildContext context) =>
      getResponsiveValue(
        context,
        mobile: 48.h,
        tablet: 52.h,
        desktop: 56.h,
      );

  // Get responsive card padding
  static EdgeInsets getResponsiveCardPadding(BuildContext context) =>
      EdgeInsets.all(
        getResponsiveValue(
          context,
          mobile: 16.w,
          tablet: 20.w,
          desktop: 24.w,
        ),
      );

  // Get responsive spacing
  static double getResponsiveSpacing(
    BuildContext context,
    double baseSpacing,
  ) =>
      getResponsiveValue(
        context,
        mobile: baseSpacing.w,
        tablet: (baseSpacing * 1.2).w,
        desktop: (baseSpacing * 1.4).w,
      );

  // Get responsive border radius
  static double getResponsiveBorderRadius(
    BuildContext context,
    double baseRadius,
  ) =>
      getResponsiveValue(
        context,
        mobile: baseRadius.r,
        tablet: (baseRadius * 1.1).r,
        desktop: (baseRadius * 1.2).r,
      );

  // Get responsive grid columns
  static int getResponsiveGridColumns(BuildContext context) =>
      getResponsiveValue(
        context,
        mobile: 1,
        tablet: 2,
        desktop: 3,
      );

  // Get responsive cross axis count for grid
  static int getResponsiveCrossAxisCount(
    BuildContext context, {
    int? mobile,
    int? tablet,
    int? desktop,
  }) =>
      getResponsiveValue(
        context,
        mobile: mobile ?? 2,
        tablet: tablet ?? 3,
        desktop: desktop ?? 4,
      );

  // Get responsive aspect ratio
  static double getResponsiveAspectRatio(BuildContext context) =>
      getResponsiveValue(
        context,
        mobile: 1.2,
        tablet: 1.3,
        desktop: 1.4,
      );

  // Get responsive max width for content
  static double getResponsiveMaxWidth(BuildContext context) =>
      getResponsiveValue(
        context,
        mobile: double.infinity,
        tablet: 600.w,
        desktop: 800.w,
      );

  // Get responsive container height
  static double getResponsiveContainerHeight(
    BuildContext context,
    double baseHeight,
  ) =>
      getResponsiveValue(
        context,
        mobile: baseHeight.h,
        tablet: (baseHeight * 1.1).h,
        desktop: (baseHeight * 1.2).h,
      );

  // Get responsive list tile height
  static double getResponsiveListTileHeight(BuildContext context) =>
      getResponsiveValue(
        context,
        mobile: 72.h,
        tablet: 80.h,
        desktop: 88.h,
      );

  // Get responsive app bar height
  static double getResponsiveAppBarHeight(BuildContext context) =>
      getResponsiveValue(
        context,
        mobile: 56.h,
        tablet: 64.h,
        desktop: 72.h,
      );

  // Get responsive bottom navigation height
  static double getResponsiveBottomNavHeight(BuildContext context) =>
      getResponsiveValue(
        context,
        mobile: 60.h,
        tablet: 70.h,
        desktop: 80.h,
      );

  // Get responsive dialog width
  static double getResponsiveDialogWidth(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return getResponsiveValue(
      context,
      mobile: screenWidth * 0.9,
      tablet: 400.w,
      desktop: 500.w,
    );
  }

  // Get responsive image size
  static Size getResponsiveImageSize(BuildContext context, double baseSize) {
    final double size = getResponsiveValue(
      context,
      mobile: baseSize.w,
      tablet: (baseSize * 1.2).w,
      desktop: (baseSize * 1.4).w,
    );
    return Size(size, size);
  }

  // Check if screen is in landscape mode
  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  // Check if screen is in portrait mode
  static bool isPortrait(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  // Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) =>
      MediaQuery.of(context).padding;

  // Get keyboard height
  static double getKeyboardHeight(BuildContext context) =>
      MediaQuery.of(context).viewInsets.bottom;

  // Get responsive text scale factor
  static double getResponsiveTextScaleFactor(BuildContext context) =>
      getResponsiveValue(
        context,
        mobile: 1,
        tablet: 1.1,
        desktop: 1.2,
      );
}

// Extension for easier access to responsive values
extension ResponsiveExtension on BuildContext {
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);
  bool get isLandscape => ResponsiveUtils.isLandscape(this);
  bool get isPortrait => ResponsiveUtils.isPortrait(this);

  EdgeInsets get responsivePadding =>
      ResponsiveUtils.getResponsivePadding(this);
  EdgeInsets get responsiveMargin => ResponsiveUtils.getResponsiveMargin(this);
  EdgeInsets get responsiveCardPadding =>
      ResponsiveUtils.getResponsiveCardPadding(this);

  double get responsiveButtonHeight =>
      ResponsiveUtils.getResponsiveButtonHeight(this);
  double get responsiveAppBarHeight =>
      ResponsiveUtils.getResponsiveAppBarHeight(this);
  double get responsiveBottomNavHeight =>
      ResponsiveUtils.getResponsiveBottomNavHeight(this);
  double get responsiveDialogWidth =>
      ResponsiveUtils.getResponsiveDialogWidth(this);
  double get responsiveMaxWidth => ResponsiveUtils.getResponsiveMaxWidth(this);

  int get responsiveGridColumns =>
      ResponsiveUtils.getResponsiveGridColumns(this);
  double get responsiveAspectRatio =>
      ResponsiveUtils.getResponsiveAspectRatio(this);
  double get responsiveTextScaleFactor =>
      ResponsiveUtils.getResponsiveTextScaleFactor(this);

  EdgeInsets get safeAreaPadding => ResponsiveUtils.getSafeAreaPadding(this);
  double get keyboardHeight => ResponsiveUtils.getKeyboardHeight(this);
}
