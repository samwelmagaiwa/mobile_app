import 'dart:async';

import 'package:boda_mapato/screens/auth/force_password_change_screen.dart';
import 'package:boda_mapato/services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// Default app language is Swahili, so these are the Swahili labels.
const String _save = 'Hifadhi';
const String _mismatch = 'Nywila hazilingani';

Widget _host(ForcePasswordChangeScreen screen) =>
    ChangeNotifierProvider<LocalizationService>.value(
      value: LocalizationService.instance,
      child: MaterialApp(home: screen),
    );

Future<void> _fill(WidgetTester t, {String confirm = 'MyOwnPass99'}) async {
  final Finder fields = find.byType(TextFormField);
  await t.enterText(fields.at(0), 'STAFFNEW');
  await t.enterText(fields.at(1), 'MyOwnPass99');
  await t.enterText(fields.at(2), confirm);
}

void main() {
  testWidgets('does not submit when the confirmation differs', (t) async {
    int calls = 0;
    await t.pumpWidget(_host(ForcePasswordChangeScreen(
      changePassword: (_, __, ___) async => calls++,
      onChanged: () async {},
    )));

    await _fill(t, confirm: 'different');
    await t.tap(find.text(_save));
    await t.pump();

    expect(find.text(_mismatch), findsOneWidget);
    expect(calls, 0);
  });

  testWidgets('sends the three values, then hands over to onChanged', (t) async {
    final List<String> sent = <String>[];
    int changed = 0;
    await t.pumpWidget(_host(ForcePasswordChangeScreen(
      changePassword: (c, n, f) async => sent.addAll(<String>[c, n, f]),
      onChanged: () async => changed++,
    )));

    await _fill(t);
    await t.tap(find.text(_save));
    await t.pump(); // request completes
    await t.pump(const Duration(milliseconds: 50));

    expect(sent, <String>['STAFFNEW', 'MyOwnPass99', 'MyOwnPass99']);
    expect(changed, 1);
  });

  testWidgets('stays on the form and keeps the input when the change fails',
      (t) async {
    int changed = 0;
    await t.pumpWidget(_host(ForcePasswordChangeScreen(
      changePassword: (_, __, ___) async => throw Exception('wrong password'),
      onChanged: () async => changed++,
    )));

    await _fill(t);
    await t.tap(find.text(_save));
    await t.pumpAndSettle();

    expect(changed, 0);
    expect(find.text(_save), findsOneWidget); // button is usable again
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      _Fields(t).controllerTexts(), // what the user typed is still there
      <String>['STAFFNEW', 'MyOwnPass99', 'MyOwnPass99'],
    );

    // Let the error banner's auto-dismiss timer run out before the test ends.
    await t.pump(const Duration(seconds: 10));
    await t.pumpAndSettle();
  });

  testWidgets('disables the button and stays mounted while the request runs',
      (t) async {
    final Completer<void> gate = Completer<void>();
    await t.pumpWidget(_host(ForcePasswordChangeScreen(
      changePassword: (_, __, ___) => gate.future,
      onChanged: () async {},
    )));

    await _fill(t);
    await t.tap(find.text(_save));
    await t.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(ForcePasswordChangeScreen), findsOneWidget);

    gate.complete();
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
  });
}

class _Fields {
  _Fields(this.t);
  final WidgetTester t;

  List<String> controllerTexts() => t
      .widgetList<TextFormField>(find.byType(TextFormField))
      .map((TextFormField f) => f.controller!.text)
      .toList();
}
