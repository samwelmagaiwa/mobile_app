// This is a basic Flutter widget test for the Boda Mapato app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "package:boda_mapato/main.dart";

void main() {
  testWidgets("Boda Mapato app smoke test", (final WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BodaMapatoApp());

    // Verify that the app loads and shows the login screen initially
    // Since the app uses AuthWrapper, it should show loading or login screen
    expect(find.byType(MaterialApp), findsOneWidget);

    // Wait for any async operations to complete
    await tester.pumpAndSettle();

    // The app should either show loading indicator or login screen
    // depending on authentication state
    expect(
      find.byType(CircularProgressIndicator).or(find.text("Ingia")),
      findsOneWidget,
    );
  });

  testWidgets("Login screen displays correctly",
      (final WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BodaMapatoApp());

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Check if we can find login-related elements
    // The app should show either loading or login elements
    hasLoginElements = tester.any(find.text("Boda Mapato")) ||
        tester.any(find.text("Ingia")) ||
        tester.any(find.byType(CircularProgressIndicator));

    expect(hasLoginElements, isTrue);
  });

  testWidgets("App title is correct", (final WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BodaMapatoApp());

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Find the MaterialApp widget and verify its title
    materialApp = tester.widget(find.byType(MaterialApp));
    expect(materialApp.title, equals("Boda Mapato"));
  });
}
