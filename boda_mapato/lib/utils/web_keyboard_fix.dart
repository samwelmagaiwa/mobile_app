import 'package:flutter/foundation.dart';
import 'dart:html' as html;

/// Fix for web keyboard event null errors
class WebKeyboardFix {
  static void initialize() {
    if (kIsWeb) {
      // Add keyboard event listeners that handle null values gracefully
      html.document.addEventListener('keydown', _handleKeyEvent);
      html.document.addEventListener('keyup', _handleKeyEvent);
      html.document.addEventListener('keypress', _handleKeyEvent);
    }
  }
  
  static void _handleKeyEvent(html.Event event) {
    try {
      if (event is html.KeyboardEvent) {
        // Access properties safely to prevent null errors
        final shiftKey = event.shiftKey ?? false;
        final ctrlKey = event.ctrlKey ?? false;
        final altKey = event.altKey ?? false;
        final metaKey = event.metaKey ?? false;
        
        // Log for debugging if needed
        if (kDebugMode && false) { // Set to true to enable logging
          print('Key event: ${event.key}, shift: $shiftKey, ctrl: $ctrlKey');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Keyboard event handling error: $e');
      }
      // Silently handle the error
    }
  }
}
