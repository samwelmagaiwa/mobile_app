// Compatibility shim: re-export the correct implementation per platform.
// On web, uses web_keyboard_fix_web.dart; on other platforms, uses stub.
export 'web_keyboard_fix_stub.dart' if (dart.library.html) 'web_keyboard_fix_web.dart';
