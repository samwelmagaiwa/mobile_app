import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../utils/responsive_utils.dart';

class CustomButton extends StatelessWidget {

  const CustomButton({
    required this.text, super.key,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.isLoading = false,
    this.icon,
    this.isOutlined = false,
  });
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final bool isLoading;
  final IconData? icon;
  final bool isOutlined;

  @override
  Widget build(final BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? AppColors.primary;
    final effectiveTextColor = textColor ?? Colors.white;
    final responsiveHeight = height ?? ResponsiveUtils.getResponsiveButtonHeight(context);
    final responsiveIconSize = ResponsiveUtils.getResponsiveIconSize(context, 18);
    final responsiveProgressSize = ResponsiveUtils.getResponsiveIconSize(context, 16);

    if (isOutlined) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: ResponsiveUtils.getResponsiveSpacing(context, 120),
          maxWidth: width ?? double.infinity,
        ),
        child: SizedBox(
          width: width,
          height: responsiveHeight,
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: effectiveBackgroundColor,
              side: BorderSide(
                color: effectiveBackgroundColor,
                width: 1.5.w,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getResponsiveBorderRadius(context, 8),
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getResponsiveSpacing(context, 16),
                vertical: ResponsiveUtils.getResponsiveSpacing(context, 8),
              ),
            ),
            icon: isLoading
                ? SizedBox(
                    width: responsiveProgressSize,
                    height: responsiveProgressSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.w,
                      valueColor: AlwaysStoppedAnimation<Color>(effectiveBackgroundColor),
                    ),
                  )
                : icon != null
                    ? Icon(icon, size: responsiveIconSize)
                    : const SizedBox.shrink(),
            label: Text(
              text,
              style: AppStyles.bodyMedium(context).copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: ResponsiveUtils.getResponsiveSpacing(context, 120),
        maxWidth: width ?? double.infinity,
      ),
      child: SizedBox(
        width: width,
        height: responsiveHeight,
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: effectiveBackgroundColor,
            foregroundColor: effectiveTextColor,
            disabledBackgroundColor: effectiveBackgroundColor.withOpacity(0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context, 8),
              ),
            ),
            elevation: ResponsiveUtils.getResponsiveSpacing(context, 2),
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getResponsiveSpacing(context, 16),
              vertical: ResponsiveUtils.getResponsiveSpacing(context, 8),
            ),
          ),
          icon: isLoading
              ? SizedBox(
                  width: responsiveProgressSize,
                  height: responsiveProgressSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.w,
                    valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
                  ),
                )
              : icon != null
                  ? Icon(icon, size: responsiveIconSize)
                  : const SizedBox.shrink(),
          label: Text(
            text,
            style: AppStyles.bodyMedium(context).copyWith(
              color: effectiveTextColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

class CustomIconButton extends StatelessWidget {

  const CustomIconButton({
    required this.icon, super.key,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 48,
    this.tooltip,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final String? tooltip;

  @override
  Widget build(final BuildContext context) {
    final responsiveSize = ResponsiveUtils.getResponsiveIconSize(context, size);
    final responsiveIconSize = responsiveSize * 0.5;
    final responsiveBlurRadius = ResponsiveUtils.getResponsiveSpacing(context, 4);
    
    final button = Container(
      width: responsiveSize,
      height: responsiveSize,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primary,
        borderRadius: BorderRadius.circular(responsiveSize / 2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black12,
            blurRadius: responsiveBlurRadius,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(responsiveSize / 2),
          child: Center(
            child: Icon(
              icon,
              color: iconColor ?? Colors.white,
              size: responsiveIconSize,
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        child: button,
      );
    }

    return button;
  }
}

class CustomTextButton extends StatelessWidget {

  const CustomTextButton({
    required this.text, super.key,
    this.onPressed,
    this.textColor,
    this.fontWeight,
  });
  final String text;
  final VoidCallback? onPressed;
  final Color? textColor;
  final FontWeight? fontWeight;

  @override
  Widget build(final BuildContext context) => TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getResponsiveSpacing(context, 16),
          vertical: ResponsiveUtils.getResponsiveSpacing(context, 8),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, 4),
          ),
        ),
      ),
      child: Text(
        text,
        style: AppStyles.bodyMedium(context).copyWith(
          color: textColor ?? AppColors.primary,
          fontWeight: fontWeight ?? FontWeight.w600,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
}