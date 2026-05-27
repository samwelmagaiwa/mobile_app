import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme_constants.dart';
import '../providers/rental_provider.dart';

class RentalFlowValidator {
  static Future<void> validateStep({
    required BuildContext context,
    required Future<void> Function(RentalProvider) fetchData,
    required bool Function(RentalProvider) condition,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) async {
    final provider = context.read<RentalProvider>();
    
    // Fetch necessary data
    await fetchData(provider);

    if (!context.mounted) return;

    // Check condition
    if (!condition(provider)) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: ThemeConstants.bgMid,
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // Go back from current screen
              },
              child: const Text('Go Back', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // Pop current screen
                onAction();
              },
              style: ElevatedButton.styleFrom(backgroundColor: ThemeConstants.primaryOrange),
              child: Text(actionLabel, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  static bool hasHouses(RentalProvider provider) {
    for (var prop in provider.properties) {
      if ((prop['houses'] as List?)?.isNotEmpty ?? false) {
        return true;
      }
    }
    return false;
  }
}
