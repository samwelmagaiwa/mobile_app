import 'package:flutter/material.dart';

class AppMessenger {
  AppMessenger._();

  static final GlobalKey<ScaffoldMessengerState> key =
      GlobalKey<ScaffoldMessengerState>();

  static void show(String message, {Color? color, bool isSuccess = true}) {
    final state = key.currentState;
    if (state == null) return;
    state
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          backgroundColor: color ?? (isSuccess ? Colors.green.shade600 : Colors.red.shade400),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(
            top: 50, // Position at top
            left: 16,
            right: 16,
            bottom: 16,
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  static void showSuccess(String message) {
    show(message, color: Colors.green.shade600);
  }

  static void showError(String message) {
    show(message, color: Colors.red.shade400, isSuccess: false);
  }
}
