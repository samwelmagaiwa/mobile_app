import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

class ThemeConstants {
  // Modern theme colors - matching admin dashboard
  static const Color primaryBlue =
      Color(0xFF1E40AF); // Deep blue from admin dashboard image
  static const Color primaryGradientStart = Color(0xFF667eea);
  static const Color primaryGradientEnd = Color(0xFF764ba2);
  static const Color cardColor = Color(0x1AFFFFFF);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color primaryOrange = Color(0xFFF97316);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);

  // Glass card decoration
  static BoxDecoration glassCardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withOpacity(0.2)),
    boxShadow: <BoxShadow>[
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );

  // Standard app bar theme
  static AppBar buildAppBar(String title, {List<Widget>? actions}) => AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryBlue,
        foregroundColor: textPrimary,
        elevation: 0,
        actions: actions,
        iconTheme: const IconThemeData(color: textPrimary),
      );

  // Glass card widget - Fixed for proper touch events
  static Widget buildGlassCard({
    required Widget child,
    VoidCallback? onTap,
  }) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: DecoratedBox(
            decoration: glassCardDecoration,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: child,
              ),
            ),
          ),
        ),
      );

  // Glass card widget without touch handling (for display-only cards)
  static Widget buildGlassCardStatic({required Widget child}) => DecoratedBox(
        decoration: glassCardDecoration,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: child,
          ),
        ),
      );

  // Standard scaffold with blue background
  static Widget buildScaffold({
    required String title,
    required Widget body,
    List<Widget>? actions,
    Widget? floatingActionButton,
    Widget? drawer,
  }) =>
      Scaffold(
        backgroundColor: primaryBlue,
        appBar: buildAppBar(title, actions: actions),
        body: DecoratedBox(
          decoration: const BoxDecoration(color: primaryBlue),
          child: SafeArea(child: body),
        ),
        floatingActionButton: floatingActionButton,
        drawer: drawer,
      );

  // Loading widget
  static Widget buildLoadingWidget() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 24),
            Text(
              "Inapakia...",
              style: TextStyle(
                color: textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  // Text styles
  static const TextStyle headingStyle = TextStyle(
    color: textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subHeadingStyle = TextStyle(
    color: textSecondary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyStyle = TextStyle(
    color: textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle captionStyle = TextStyle(
    color: textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );

  // Top snackbar utility methods - truly positions at TOP of screen
  static void _showTopSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration? duration,
    IconData? icon,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: backgroundColor ?? successGreen,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    
    // Auto-remove after duration
    Future.delayed(duration ?? const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    _showTopSnackBar(
      context, 
      message,
      backgroundColor: successGreen,
      icon: Icons.check_circle,
    );
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    _showTopSnackBar(
      context, 
      message,
      backgroundColor: errorRed,
      icon: Icons.error,
    );
  }

  static void showWarningSnackBar(BuildContext context, String message) {
    _showTopSnackBar(
      context, 
      message,
      backgroundColor: warningAmber,
      icon: Icons.warning,
    );
  }

  // Responsive helper methods
  /// Get responsive glass card decoration with MediaQuery-based sizing
  static BoxDecoration responsiveGlassCardDecoration(BuildContext context) {
    ResponsiveHelper.init(context);
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(ResponsiveHelper.radiusL),
      border: Border.all(color: Colors.white.withOpacity(0.2)),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: ResponsiveHelper.elevation * 5,
          offset: Offset(0, ResponsiveHelper.elevation * 2.5),
        ),
      ],
    );
  }

  /// Get responsive app bar with MediaQuery-based sizing
  static AppBar buildResponsiveAppBar(BuildContext context, String title,
      {List<Widget>? actions}) {
    ResponsiveHelper.init(context);
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: textPrimary,
          fontSize: ResponsiveHelper.h3,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: primaryBlue,
      foregroundColor: textPrimary,
      elevation: 0,
      actions: actions,
      iconTheme: IconThemeData(
        color: textPrimary,
        size: ResponsiveHelper.iconSizeL,
      ),
      toolbarHeight: ResponsiveHelper.appBarHeight,
    );
  }

  /// Responsive glass card widget with MediaQuery-based sizing
  static Widget buildResponsiveGlassCard(
    BuildContext context, {
    required Widget child,
    VoidCallback? onTap,
  }) {
    ResponsiveHelper.init(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ResponsiveHelper.radiusL),
        child: Container(
          constraints: BoxConstraints(
            minHeight: ResponsiveHelper.cardMinHeight,
            maxWidth: ResponsiveHelper.maxCardWidth,
          ),
          decoration: responsiveGlassCardDecoration(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ResponsiveHelper.radiusL),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: ResponsiveHelper.isMobile ? 8 : 10,
                sigmaY: ResponsiveHelper.isMobile ? 8 : 10,
              ),
              child: Padding(
                padding: ResponsiveHelper.cardPadding,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Responsive glass card widget without touch handling (for display-only cards)
  static Widget buildResponsiveGlassCardStatic(BuildContext context,
      {required Widget child}) {
    ResponsiveHelper.init(context);
    return Container(
      constraints: BoxConstraints(
        minHeight: ResponsiveHelper.cardMinHeight,
        maxWidth: ResponsiveHelper.maxCardWidth,
      ),
      decoration: responsiveGlassCardDecoration(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ResponsiveHelper.radiusL),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: ResponsiveHelper.isMobile ? 8 : 10,
            sigmaY: ResponsiveHelper.isMobile ? 8 : 10,
          ),
          child: Padding(
            padding: ResponsiveHelper.cardPadding,
            child: child,
          ),
        ),
      ),
    );
  }

  /// Responsive scaffold with MediaQuery-based sizing
  static Widget buildResponsiveScaffold(
    BuildContext context, {
    required String title,
    required Widget body,
    List<Widget>? actions,
    Widget? floatingActionButton,
    Widget? drawer,
  }) {
    ResponsiveHelper.init(context);
    return Scaffold(
      backgroundColor: primaryBlue,
      appBar: buildResponsiveAppBar(context, title, actions: actions),
      body: DecoratedBox(
        decoration: const BoxDecoration(color: primaryBlue),
        child: SafeArea(
          child: Padding(
            padding: ResponsiveHelper.defaultPadding,
            child: body,
          ),
        ),
      ),
      floatingActionButton: floatingActionButton,
      drawer: drawer,
    );
  }

  /// Responsive loading widget with MediaQuery-based sizing
  static Widget buildResponsiveLoadingWidget(BuildContext context) {
    ResponsiveHelper.init(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: ResponsiveHelper.wp(10),
            height: ResponsiveHelper.wp(10),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          ResponsiveHelper.verticalSpace(3),
          Text(
            "Inapakia...",
            style: TextStyle(
              color: textSecondary,
              fontSize: ResponsiveHelper.bodyL,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Responsive text styles
  /// Responsive heading style
  static TextStyle responsiveHeadingStyle(BuildContext context) {
    ResponsiveHelper.init(context);
    return TextStyle(
      color: textPrimary,
      fontSize: ResponsiveHelper.h4,
      fontWeight: FontWeight.bold,
    );
  }

  /// Responsive subheading style
  static TextStyle responsiveSubHeadingStyle(BuildContext context) {
    ResponsiveHelper.init(context);
    return TextStyle(
      color: textSecondary,
      fontSize: ResponsiveHelper.bodyL,
      fontWeight: FontWeight.w600,
    );
  }

  /// Responsive body style
  static TextStyle responsiveBodyStyle(BuildContext context) {
    ResponsiveHelper.init(context);
    return TextStyle(
      color: textPrimary,
      fontSize: ResponsiveHelper.bodyM,
      fontWeight: FontWeight.normal,
    );
  }

  /// Responsive caption style
  static TextStyle responsiveCaptionStyle(BuildContext context) {
    ResponsiveHelper.init(context);
    return TextStyle(
      color: textSecondary,
      fontSize: ResponsiveHelper.bodyS,
      fontWeight: FontWeight.normal,
    );
  }

  // Responsive button styles
  /// Responsive elevated button style
  static ButtonStyle responsiveElevatedButtonStyle(BuildContext context) {
    ResponsiveHelper.init(context);
    return ElevatedButton.styleFrom(
      backgroundColor: primaryOrange,
      foregroundColor: textPrimary,
      elevation: ResponsiveHelper.elevation,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.spacingL,
        vertical: ResponsiveHelper.spacingM,
      ),
      minimumSize: Size(
        ResponsiveHelper.wp(20),
        ResponsiveHelper.buttonHeight,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveHelper.radiusM),
      ),
      textStyle: TextStyle(
        fontSize: ResponsiveHelper.bodyL,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Responsive outlined button style
  static ButtonStyle responsiveOutlinedButtonStyle(BuildContext context) {
    ResponsiveHelper.init(context);
    return OutlinedButton.styleFrom(
      foregroundColor: textPrimary,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.spacingL,
        vertical: ResponsiveHelper.spacingM,
      ),
      minimumSize: Size(
        ResponsiveHelper.wp(20),
        ResponsiveHelper.buttonHeight,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveHelper.radiusM),
      ),
      side: const BorderSide(color: textPrimary, width: 1.5),
      textStyle: TextStyle(
        fontSize: ResponsiveHelper.bodyL,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
