import 'package:flutter/material.dart';

/// A utility class for creating SnackBars with selectable text content
class SelectableSnackBar {
  /// Shows a SnackBar with selectable text content
  static void show(
    final BuildContext context, {
    required final String message,
    final Color? backgroundColor,
    final Duration duration = const Duration(seconds: 4),
    final SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SelectableText(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: backgroundColor ?? Colors.black87,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: action,
      ),
    );
  }

  /// Shows an error SnackBar with selectable text
  static void showError(
    final BuildContext context, {
    required final String message,
    final Duration duration = const Duration(seconds: 6),
  }) {
    show(
      context,
      message: message,
      backgroundColor: Colors.red[600],
      duration: duration,
    );
  }

  /// Shows a success SnackBar with selectable text
  static void showSuccess(
    final BuildContext context, {
    required final String message,
    final Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      backgroundColor: Colors.green[600],
      duration: duration,
    );
  }

  /// Shows an info SnackBar with selectable text
  static void showInfo(
    final BuildContext context, {
    required final String message,
    final Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      backgroundColor: Colors.blue[600],
      duration: duration,
    );
  }

  /// Shows a warning SnackBar with selectable text
  static void showWarning(
    final BuildContext context, {
    required final String message,
    final Duration duration = const Duration(seconds: 5),
  }) {
    show(
      context,
      message: message,
      backgroundColor: Colors.orange[600],
      duration: duration,
    );
  }
}

/// A widget that displays selectable text in dialogs
class SelectableDialogContent extends StatelessWidget {

  const SelectableDialogContent({
    required this.text, super.key,
    this.style,
    this.textAlign,
  });
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(final BuildContext context) => SelectableText(
      text,
      style: style,
      textAlign: textAlign,
    );
}

/// A widget for displaying selectable error messages
class SelectableErrorText extends StatelessWidget {

  const SelectableErrorText({
    required this.error, super.key,
    this.style,
  });
  final String error;
  final TextStyle? style;

  @override
  Widget build(final BuildContext context) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.error_outline,
            color: Colors.red[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              error,
              style: style ??
                  TextStyle(
                    color: Colors.red[700],
                    fontSize: 14,
                  ),
            ),
          ),
        ],
      ),
    );
}

/// A widget for displaying selectable information text
class SelectableInfoText extends StatelessWidget {

  const SelectableInfoText({
    required this.text, super.key,
    this.style,
    this.icon,
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
  });
  final String text;
  final TextStyle? style;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;

  @override
  Widget build(final BuildContext context) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.blue[50],
        border: Border.all(color: borderColor ?? Colors.blue[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(
              icon,
              color: iconColor ?? Colors.blue[600],
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: SelectableText(
              text,
              style: style ??
                  TextStyle(
                    color: Colors.blue[700],
                    fontSize: 14,
                  ),
            ),
          ),
        ],
      ),
    );
}