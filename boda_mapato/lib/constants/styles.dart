import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'colors.dart';
import '../utils/responsive_utils.dart';

class AppStyles {
  // Responsive Text Styles
  static TextStyle heading1(BuildContext context) => TextStyle(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 32),
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  static TextStyle heading2(BuildContext context) => TextStyle(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 24),
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  static TextStyle heading3(BuildContext context) => TextStyle(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  static TextStyle heading4(BuildContext context) => TextStyle(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  static TextStyle bodyLarge(BuildContext context) => TextStyle(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static TextStyle bodyMedium(BuildContext context) => TextStyle(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  static TextStyle bodySmall(BuildContext context) => TextStyle(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  
  static TextStyle caption(BuildContext context) => TextStyle(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 10),
    fontWeight: FontWeight.normal,
    color: AppColors.textHint,
    height: 1.3,
  );
  
  // Responsive Button Styles
  static ButtonStyle primaryButton(BuildContext context) => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(
      horizontal: ResponsiveUtils.getResponsiveSpacing(context, 24),
      vertical: ResponsiveUtils.getResponsiveSpacing(context, 12),
    ),
    textStyle: bodyMedium(context).copyWith(fontWeight: FontWeight.w600),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(
        ResponsiveUtils.getResponsiveBorderRadius(context, 8),
      ),
    ),
    minimumSize: Size(
      ResponsiveUtils.getResponsiveSpacing(context, 120),
      ResponsiveUtils.getResponsiveButtonHeight(context),
    ),
    elevation: elevationM(context),
  );
  
  static ButtonStyle secondaryButton(BuildContext context) => OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: BorderSide(color: AppColors.primary, width: 1.5.w),
    padding: EdgeInsets.symmetric(
      horizontal: ResponsiveUtils.getResponsiveSpacing(context, 24),
      vertical: ResponsiveUtils.getResponsiveSpacing(context, 12),
    ),
    textStyle: bodyMedium(context).copyWith(fontWeight: FontWeight.w600),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(
        ResponsiveUtils.getResponsiveBorderRadius(context, 8),
      ),
    ),
    minimumSize: Size(
      ResponsiveUtils.getResponsiveSpacing(context, 120),
      ResponsiveUtils.getResponsiveButtonHeight(context),
    ),
  );
  
  // Responsive Card Styles
  static BoxDecoration cardDecoration(BuildContext context) => BoxDecoration(
    color: AppColors.cardBackground,
    borderRadius: BorderRadius.all(
      Radius.circular(ResponsiveUtils.getResponsiveBorderRadius(context, 12)),
    ),
    boxShadow: <BoxShadow>[
      BoxShadow(
        color: Colors.black12,
        blurRadius: ResponsiveUtils.getResponsiveSpacing(context, 4),
        offset: Offset(0, 2.h),
      ),
    ],
  );
  
  // Responsive Input Decoration
  static InputDecoration inputDecoration(BuildContext context) => InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        ResponsiveUtils.getResponsiveBorderRadius(context, 8),
      ),
      borderSide: BorderSide(color: AppColors.textHint, width: 1.w),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        ResponsiveUtils.getResponsiveBorderRadius(context, 8),
      ),
      borderSide: BorderSide(color: AppColors.primary, width: 2.w),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        ResponsiveUtils.getResponsiveBorderRadius(context, 8),
      ),
      borderSide: BorderSide(color: AppColors.error, width: 1.w),
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: ResponsiveUtils.getResponsiveSpacing(context, 16),
      vertical: ResponsiveUtils.getResponsiveSpacing(context, 12),
    ),
    filled: true,
    fillColor: AppColors.surface,
  );
  
  // Responsive Input Decoration Theme
  static InputDecorationTheme inputDecorationTheme(BuildContext context) => InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        ResponsiveUtils.getResponsiveBorderRadius(context, 8),
      ),
      borderSide: BorderSide(color: AppColors.textHint, width: 1.w),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        ResponsiveUtils.getResponsiveBorderRadius(context, 8),
      ),
      borderSide: BorderSide(color: AppColors.primary, width: 2.w),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        ResponsiveUtils.getResponsiveBorderRadius(context, 8),
      ),
      borderSide: BorderSide(color: AppColors.error, width: 1.w),
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: ResponsiveUtils.getResponsiveSpacing(context, 16),
      vertical: ResponsiveUtils.getResponsiveSpacing(context, 12),
    ),
    filled: true,
    fillColor: AppColors.surface,
  );
  
  // Responsive Spacing
  static double spacingXS(BuildContext context) => ResponsiveUtils.getResponsiveSpacing(context, 4);
  static double spacingS(BuildContext context) => ResponsiveUtils.getResponsiveSpacing(context, 8);
  static double spacingM(BuildContext context) => ResponsiveUtils.getResponsiveSpacing(context, 16);
  static double spacingL(BuildContext context) => ResponsiveUtils.getResponsiveSpacing(context, 24);
  static double spacingXL(BuildContext context) => ResponsiveUtils.getResponsiveSpacing(context, 32);
  
  // Responsive Border Radius
  static double radiusS(BuildContext context) => ResponsiveUtils.getResponsiveBorderRadius(context, 4);
  static double radiusM(BuildContext context) => ResponsiveUtils.getResponsiveBorderRadius(context, 8);
  static double radiusL(BuildContext context) => ResponsiveUtils.getResponsiveBorderRadius(context, 12);
  static double radiusXL(BuildContext context) => ResponsiveUtils.getResponsiveBorderRadius(context, 16);
  
  // Responsive Elevation
  static double elevationS(BuildContext context) => ResponsiveUtils.getResponsiveSpacing(context, 2);
  static double elevationM(BuildContext context) => ResponsiveUtils.getResponsiveSpacing(context, 4);
  static double elevationL(BuildContext context) => ResponsiveUtils.getResponsiveSpacing(context, 8);
  
  // Responsive Icon Sizes
  static double iconSizeSmall(BuildContext context) => ResponsiveUtils.getResponsiveIconSize(context, 16);
  static double iconSizeMedium(BuildContext context) => ResponsiveUtils.getResponsiveIconSize(context, 24);
  static double iconSizeLarge(BuildContext context) => ResponsiveUtils.getResponsiveIconSize(context, 32);
  static double iconSizeXLarge(BuildContext context) => ResponsiveUtils.getResponsiveIconSize(context, 48);
  
  // Responsive Container Heights
  static double containerHeightSmall(BuildContext context) => ResponsiveUtils.getResponsiveContainerHeight(context, 40);
  static double containerHeightMedium(BuildContext context) => ResponsiveUtils.getResponsiveContainerHeight(context, 60);
  static double containerHeightLarge(BuildContext context) => ResponsiveUtils.getResponsiveContainerHeight(context, 80);
  
  // Responsive List Item Heights
  static double listItemHeight(BuildContext context) => ResponsiveUtils.getResponsiveListTileHeight(context);
  
  // Responsive Dialog Constraints
  static BoxConstraints dialogConstraints(BuildContext context) => BoxConstraints(
    maxWidth: ResponsiveUtils.getResponsiveDialogWidth(context),
    maxHeight: MediaQuery.of(context).size.height * 0.8,
  );
  
  // Responsive Grid Delegate
  static SliverGridDelegate responsiveGridDelegate(BuildContext context, {
    int? crossAxisCount,
    double? childAspectRatio,
  }) => SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: crossAxisCount ?? ResponsiveUtils.getResponsiveCrossAxisCount(context),
    childAspectRatio: childAspectRatio ?? ResponsiveUtils.getResponsiveAspectRatio(context),
    crossAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, 8),
    mainAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, 8),
  );
    
  // Responsive App Bar Theme
  static AppBarTheme appBarTheme(BuildContext context) => AppBarTheme(
    toolbarHeight: ResponsiveUtils.getResponsiveAppBarHeight(context),
    titleTextStyle: heading3(context).copyWith(color: Colors.white),
    iconTheme: IconThemeData(
      size: ResponsiveUtils.getResponsiveIconSize(context, 24),
      color: Colors.white,
    ),
  );
  
  // Responsive Bottom Navigation Bar Theme
  static BottomNavigationBarThemeData bottomNavTheme(BuildContext context) => BottomNavigationBarThemeData(
    selectedLabelStyle: bodySmall(context).copyWith(fontWeight: FontWeight.w600),
    unselectedLabelStyle: bodySmall(context),
    selectedIconTheme: IconThemeData(
      size: ResponsiveUtils.getResponsiveIconSize(context, 24),
    ),
    unselectedIconTheme: IconThemeData(
      size: ResponsiveUtils.getResponsiveIconSize(context, 20),
    ),
  );
  
  // Responsive Card Theme
  static CardTheme cardTheme(BuildContext context) => CardTheme(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(
        ResponsiveUtils.getResponsiveBorderRadius(context, 12),
      ),
    ),
    elevation: ResponsiveUtils.getResponsiveSpacing(context, 2),
    margin: ResponsiveUtils.getResponsiveMargin(context),
  );
  
  // Responsive Floating Action Button Theme
  static FloatingActionButtonThemeData fabTheme(BuildContext context) => FloatingActionButtonThemeData(
    iconSize: ResponsiveUtils.getResponsiveIconSize(context, 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(
        ResponsiveUtils.getResponsiveBorderRadius(context, 16),
      ),
    ),
  );
}