import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';

class AppMessenger {
  AppMessenger._();

  static final GlobalKey<ScaffoldMessengerState> key =
      GlobalKey<ScaffoldMessengerState>();

  static void show(String message, {Color? color, bool isSuccess = true}) {
    final BuildContext? ctx = key.currentContext;
    if (ctx == null) return;
    if (isSuccess) {
      ThemeConstants.showSuccessSnackBar(ctx, message);
    } else {
      ThemeConstants.showErrorSnackBar(ctx, message);
    }
  }

  static void showSuccess(String message) {
    show(message, isSuccess: true);
  }

  static void showError(String message) {
    show(message, isSuccess: false);
  }
}
