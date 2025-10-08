import "package:flutter/material.dart";
import "package:flutter_screenutil/flutter_screenutil.dart";
import "../constants/colors.dart";
import "../constants/styles.dart";
import "../utils/responsive_utils.dart";

class CustomCard extends StatelessWidget {
  const CustomCard({
    required this.child,
    super.key,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.border,
  });
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Border? border;

  @override
  Widget build(final BuildContext context) {
    final BorderRadius responsiveBorderRadius = borderRadius ??
        BorderRadius.circular(
          ResponsiveUtils.getResponsiveBorderRadius(context, 12),
        );
    final double responsiveElevation =
        elevation ?? ResponsiveUtils.getResponsiveSpacing(context, 2);

    final Container card = Container(
      margin: margin ?? ResponsiveUtils.getResponsiveMargin(context),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.cardBackground,
        borderRadius: responsiveBorderRadius,
        border: border,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: responsiveElevation,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: responsiveBorderRadius,
        child: padding != null
            ? Padding(
                padding: padding!,
                child: child,
              )
            : child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: responsiveBorderRadius,
          child: card,
        ),
      );
    }

    return card;
  }
}

class CustomListCard extends StatelessWidget {
  const CustomListCard({
    required this.child,
    super.key,
    this.onTap,
    this.isSelected = false,
    this.padding,
    this.margin,
  });
  final Widget child;
  final VoidCallback? onTap;
  final bool isSelected;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(final BuildContext context) => CustomCard(
        onTap: onTap,
        padding: padding ??
            EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context, 16)),
        margin: margin ??
            EdgeInsets.only(
              bottom: ResponsiveUtils.getResponsiveSpacing(context, 8),
            ),
        backgroundColor: isSelected
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.cardBackground,
        border: isSelected
            ? Border.all(color: AppColors.primary, width: 1.5.w)
            : null,
        child: child,
      );
}

class CustomInfoCard extends StatelessWidget {
  const CustomInfoCard({
    required this.title,
    super.key,
    this.subtitle,
    this.trailing,
    this.icon,
    this.iconColor,
    this.onTap,
  });
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context) {
    final double responsiveIconSize =
        ResponsiveUtils.getResponsiveIconSize(context, 40);
    final double responsiveIconInnerSize =
        ResponsiveUtils.getResponsiveIconSize(context, 20);

    return CustomCard(
      onTap: onTap,
      child: Padding(
        padding:
            EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context, 16)),
        child: Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Container(
                width: responsiveIconSize,
                height: responsiveIconSize,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getResponsiveBorderRadius(context, 8),
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.primary,
                  size: responsiveIconInnerSize,
                ),
              ),
              SizedBox(
                width: ResponsiveUtils.getResponsiveSpacing(context, 16),
              ),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppStyles.bodyMediumResponsive(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  if (subtitle != null) ...<Widget>[
                    SizedBox(
                      height: ResponsiveUtils.getResponsiveSpacing(context, 4),
                    ),
                    Text(
                      subtitle!,
                      style: AppStyles.bodySmallResponsive(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...<Widget>[
              SizedBox(
                width: ResponsiveUtils.getResponsiveSpacing(context, 16),
              ),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class CustomStatCard extends StatelessWidget {
  const CustomStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    super.key,
    this.subtitle,
    this.onTap,
  });
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context) {
    final double responsiveIconSize =
        ResponsiveUtils.getResponsiveIconSize(context, 20);

    return CustomCard(
      onTap: onTap,
      child: Padding(
        padding:
            EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  icon,
                  color: color,
                  size: responsiveIconSize,
                ),
                SizedBox(
                  width: ResponsiveUtils.getResponsiveSpacing(context, 8),
                ),
                Expanded(
                  child: Text(
                    title,
                    style: AppStyles.bodySmallResponsive(context).copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: AppStyles.heading2Responsive(context).copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
              ),
            ),
            if (subtitle != null) ...<Widget>[
              SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(context, 4),
              ),
              Text(
                subtitle!,
                style: AppStyles.bodySmallResponsive(context).copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
