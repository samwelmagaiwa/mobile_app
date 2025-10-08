import "package:flutter/material.dart";
import "../utils/responsive_utils.dart";

/// A wrapper widget that provides responsive layout capabilities
class ResponsiveWrapper extends StatelessWidget {
  const ResponsiveWrapper({
    required this.child,
    super.key,
    this.padding,
    this.margin,
    this.maxWidth,
    this.alignment = Alignment.center,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? maxWidth;
  final AlignmentGeometry alignment;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: backgroundColor,
        padding: margin,
        child: Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  maxWidth ?? ResponsiveUtils.getResponsiveMaxWidth(context),
            ),
            child: Container(
              padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
              child: child,
            ),
          ),
        ),
      );
}

/// A responsive scaffold that automatically handles safe areas and responsive padding
class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    required this.body,
    super.key,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.padding,
    this.maxWidth,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: appBar,
        drawer: drawer,
        endDrawer: endDrawer,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        bottomNavigationBar: bottomNavigationBar,
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        extendBody: extendBody,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        body: ResponsiveWrapper(
          padding: padding,
          maxWidth: maxWidth,
          child: body,
        ),
      );
}

/// A responsive column that automatically adjusts spacing based on screen size
class ResponsiveColumn extends StatelessWidget {
  const ResponsiveColumn({
    required this.children,
    super.key,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.spacing,
    this.padding,
  });

  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double? spacing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final double responsiveSpacing =
        spacing ?? ResponsiveUtils.getResponsiveSpacing(context, 16);

    final List<Widget> spacedChildren = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(SizedBox(height: responsiveSpacing));
      }
    }

    Widget column = Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: spacedChildren,
    );

    if (padding != null) {
      column = Padding(
        padding: padding!,
        child: column,
      );
    }

    return column;
  }
}

/// A responsive row that automatically adjusts spacing based on screen size
class ResponsiveRow extends StatelessWidget {
  const ResponsiveRow({
    required this.children,
    super.key,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.spacing,
    this.padding,
  });

  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double? spacing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final double responsiveSpacing =
        spacing ?? ResponsiveUtils.getResponsiveSpacing(context, 16);

    final List<Widget> spacedChildren = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(SizedBox(width: responsiveSpacing));
      }
    }

    Widget row = Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: spacedChildren,
    );

    if (padding != null) {
      row = Padding(
        padding: padding!,
        child: row,
      );
    }

    return row;
  }
}

/// A responsive grid view that automatically adjusts columns based on screen size
class ResponsiveGridView extends StatelessWidget {
  const ResponsiveGridView({
    required this.children,
    super.key,
    this.crossAxisCount,
    this.childAspectRatio,
    this.spacing,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  final List<Widget> children;
  final int? crossAxisCount;
  final double? childAspectRatio;
  final double? spacing;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    final double responsiveSpacing =
        spacing ?? ResponsiveUtils.getResponsiveSpacing(context, 8);

    return GridView.count(
      crossAxisCount: crossAxisCount ??
          ResponsiveUtils.getResponsiveCrossAxisCount(context),
      childAspectRatio:
          childAspectRatio ?? ResponsiveUtils.getResponsiveAspectRatio(context),
      crossAxisSpacing: responsiveSpacing,
      mainAxisSpacing: responsiveSpacing,
      padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
      shrinkWrap: shrinkWrap,
      physics: physics,
      children: children,
    );
  }
}

/// A responsive list view with automatic spacing
class ResponsiveListView extends StatelessWidget {
  const ResponsiveListView({
    required this.children,
    super.key,
    this.spacing,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.scrollDirection = Axis.vertical,
  });

  final List<Widget> children;
  final double? spacing;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Axis scrollDirection;

  @override
  Widget build(BuildContext context) {
    final double responsiveSpacing =
        spacing ?? ResponsiveUtils.getResponsiveSpacing(context, 8);

    final List<Widget> spacedChildren = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        if (scrollDirection == Axis.vertical) {
          spacedChildren.add(SizedBox(height: responsiveSpacing));
        } else {
          spacedChildren.add(SizedBox(width: responsiveSpacing));
        }
      }
    }

    return ListView(
      scrollDirection: scrollDirection,
      padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
      shrinkWrap: shrinkWrap,
      physics: physics,
      children: spacedChildren,
    );
  }
}

/// A responsive container that automatically adjusts its properties based on screen size
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.decoration,
    this.color,
    this.borderRadius,
    this.constraints,
  });

  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;
  final Color? color;
  final double? borderRadius;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        padding: padding ?? ResponsiveUtils.getResponsiveCardPadding(context),
        margin: margin ?? ResponsiveUtils.getResponsiveMargin(context),
        constraints: constraints,
        decoration: decoration ??
            (color != null || borderRadius != null
                ? BoxDecoration(
                    color: color,
                    borderRadius: borderRadius != null
                        ? BorderRadius.circular(
                            ResponsiveUtils.getResponsiveBorderRadius(
                              context,
                              borderRadius!,
                            ),
                          )
                        : null,
                  )
                : null),
        child: child,
      );
}

/// A responsive text widget that automatically adjusts font size
class ResponsiveText extends StatelessWidget {
  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.textScaleFactor,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool? softWrap;
  final double? textScaleFactor;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: style,
        textAlign: textAlign,
        overflow: overflow,
        maxLines: maxLines,
        softWrap: softWrap,
        textScaleFactor: textScaleFactor ??
            ResponsiveUtils.getResponsiveTextScaleFactor(context),
      );
}

/// A responsive icon that automatically adjusts size
class ResponsiveIcon extends StatelessWidget {
  const ResponsiveIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
    this.textDirection,
  });

  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) => Icon(
        icon,
        size: size != null
            ? ResponsiveUtils.getResponsiveIconSize(context, size!)
            : ResponsiveUtils.getResponsiveIconSize(context, 24),
        color: color,
        semanticLabel: semanticLabel,
        textDirection: textDirection,
      );
}

/// A responsive sized box that automatically adjusts dimensions
class ResponsiveSizedBox extends StatelessWidget {
  const ResponsiveSizedBox({
    super.key,
    this.width,
    this.height,
    this.child,
  });

  const ResponsiveSizedBox.width(double width, {super.key, this.child})
      : width = width,
        height = null;

  const ResponsiveSizedBox.height(double height, {super.key, this.child})
      : width = null,
        height = height;

  const ResponsiveSizedBox.square(double dimension, {super.key, this.child})
      : width = dimension,
        height = dimension;

  final double? width;
  final double? height;
  final Widget? child;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width != null
            ? ResponsiveUtils.getResponsiveSpacing(context, width!)
            : null,
        height: height != null
            ? ResponsiveUtils.getResponsiveSpacing(context, height!)
            : null,
        child: child,
      );
}
