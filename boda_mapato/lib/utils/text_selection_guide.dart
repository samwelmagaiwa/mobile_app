/*
 * TEXT SELECTION GUIDE FOR FLUTTER MOBILE APPS
 * ============================================
 * 
 * This guide explains how to fix text selection issues in Flutter mobile apps
 * where users can"t highlight or copy text.
 * 
 * COMMON ISSUES AND SOLUTIONS:
 * 
 * 1. NON-SELECTABLE TEXT WIDGETS
 * ==============================
 * Problem: Regular Text() widgets don"t allow text selection by default
 * 
 * ❌ BAD:
 * Text("Error: Login failed")
 * 
 * ✅ GOOD:
 * SelectableText("Error: Login failed")
 * 
 * Use SelectableText for:
 * - Error messages
 * - Success messages  
 * - Information text
 * - Credentials/codes
 * - URLs/emails
 * - Any text users might want to copy
 * 
 * 2. GESTURE DETECTOR INTERFERENCE
 * ===============================
 * Problem: GestureDetector can block text selection
 * 
 * ❌ BAD:
 * GestureDetector(
 *   onTap: () => doSomething(),
 *   child: Text("Selectable text")
 * )
 * 
 * ✅ GOOD:
 * GestureDetector(
 *   behavior: HitTestBehavior.translucent,
 *   onTap: () => doSomething(),
 *   child: SelectableText("Selectable text")
 * )
 * 
 * Or better yet, avoid wrapping text in GestureDetector unless necessary.
 * 
 * 3. SNACKBAR MESSAGES
 * ===================
 * Problem: SnackBar content is not selectable by default
 * 
 * ❌ BAD:
 * SnackBar(content: Text("Error message"))
 * 
 * ✅ GOOD:
 * SnackBar(content: SelectableText("Error message"))
 * 
 * 4. DIALOG CONTENT
 * ================
 * Problem: AlertDialog content is not selectable
 * 
 * ❌ BAD:
 * AlertDialog(
 *   content: Text("Long error message that users might want to copy")
 * )
 * 
 * ✅ GOOD:
 * AlertDialog(
 *   content: SelectableText("Long error message that users might want to copy")
 * )
 * 
 * 5. CONTAINER/CARD WRAPPED TEXT
 * =============================
 * Problem: Text inside containers might not be selectable
 * 
 * ❌ BAD:
 * Container(
 *   child: Text("Important information")
 * )
 * 
 * ✅ GOOD:
 * Container(
 *   child: SelectableText("Important information")
 * )
 * 
 * 6. LISTVIEW/COLUMN TEXT ITEMS
 * ============================
 * Problem: Text in lists might not be selectable
 * 
 * ❌ BAD:
 * ListView(
 *   children: [
 *     Text("Item 1"),
 *     Text("Item 2"),
 *   ]
 * )
 * 
 * ✅ GOOD:
 * ListView(
 *   children: [
 *     SelectableText("Item 1"),
 *     SelectableText("Item 2"),
 *   ]
 * )
 * 
 * WHEN TO USE SelectableText:
 * ==========================
 * ✅ Error messages
 * ✅ Success messages
 * ✅ Warning messages
 * ✅ Information text
 * ✅ User credentials
 * ✅ API responses
 * ✅ URLs and email addresses
 * ✅ Phone numbers
 * ✅ Codes and IDs
 * ✅ Long descriptions
 * ✅ Technical details
 * 
 * WHEN NOT TO USE SelectableText:
 * ==============================
 * ❌ Button labels
 * ❌ Navigation titles
 * ❌ Short UI labels
 * ❌ Icons with text
 * ❌ Tab labels
 * ❌ App bar titles (usually)
 * 
 * ADDITIONAL PROPERTIES:
 * =====================
 * SelectableText(
 *   "Your text here",
 *   style: TextStyle(...),
 *   textAlign: TextAlign.center,
 *   maxLines: 3,
 *   showCursor: true,
 *   cursorColor: Colors.blue,
 *   selectionControls: MaterialTextSelectionControls(),
 * )
 * 
 * TESTING TEXT SELECTION:
 * ======================
 * 1. Run app on physical device or emulator
 * 2. Long press on text
 * 3. Verify selection handles appear
 * 4. Verify copy option appears in context menu
 * 5. Test copying and pasting in another app
 * 
 * ACCESSIBILITY BENEFITS:
 * ======================
 * - Users can copy error messages to share with support
 * - Better accessibility for screen readers
 * - Improved user experience
 * - Compliance with accessibility guidelines
 */

import "package:flutter/material.dart";
import "package:flutter_screenutil/flutter_screenutil.dart";

/// Example implementations of selectable text widgets
class TextSelectionExamples {
  /// Example of selectable error message
  static Widget selectableErrorMessage(final String error) => Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: Colors.red[50],
          border: Border.all(color: Colors.red[300]!),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.error_outline, color: Colors.red[600], size: 20.r),
            SizedBox(width: 8.w),
            Expanded(
              child: SelectableText(
                error,
                style: TextStyle(color: Colors.red[700], fontSize: 14.sp),
              ),
            ),
          ],
        ),
      );

  /// Example of selectable success message
  static Widget selectableSuccessMessage(final String message) => Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: Colors.green[50],
          border: Border.all(color: Colors.green[300]!),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.check_circle_outline,
              color: Colors.green[600],
              size: 20.r,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: SelectableText(
                message,
                style: TextStyle(color: Colors.green[700], fontSize: 14.sp),
              ),
            ),
          ],
        ),
      );

  /// Example of selectable info card
  static Widget selectableInfoCard(final String title, final String content) =>
      Card(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 8.h),
              SelectableText(
                content,
                style: TextStyle(fontSize: 14.sp),
              ),
            ],
          ),
        ),
      );
}
