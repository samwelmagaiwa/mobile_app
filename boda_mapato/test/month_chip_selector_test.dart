import 'package:boda_mapato/widgets/month_chip_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const List<String> _labels = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// A phone-width screen, so the row of months cannot all fit.
Future<List<int>> _pump(
  WidgetTester t, {
  int selected = 10,
  int? lastMonth = 10,
}) async {
  t.view.physicalSize = const Size(1080, 1920); // 360 x 640 logical at 3x
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);

  final List<int> taps = <int>[];
  await t.pumpWidget(MaterialApp(
    home: Scaffold(
      body: MonthChipSelector(
        selectedMonth: selected,
        lastMonth: lastMonth,
        labels: _labels,
        selectedTextColor: Colors.white,
        unselectedTextColor: Colors.white70,
        onSelected: taps.add,
      ),
    ),
  ));
  await t.pumpAndSettle(); // the opening scroll happens after the first frame
  return taps;
}

bool _onScreen(WidgetTester t, String label) {
  final Rect r = t.getRect(find.text(label));
  return r.left >= 0 && r.right <= 360;
}

Color? _fill(WidgetTester t, int month) {
  final Container box = t.widget<Container>(find.descendant(
    of: find.byKey(ValueKey<String>('month_chip_$month')),
    matching: find.byType(Container),
  ));
  return (box.decoration! as BoxDecoration).color;
}

void main() {
  testWidgets('opens on the current month, visible and highlighted', (t) async {
    await _pump(t);

    expect(_onScreen(t, 'Oct'), isTrue, reason: 'the current month must be in view');
    expect(_onScreen(t, 'Sep'), isTrue);
    expect(_fill(t, 10), isNot(Colors.transparent));
    expect(_fill(t, 9), Colors.transparent);
  });

  testWidgets('earlier months are off to the left until you scroll back',
      (t) async {
    await _pump(t);
    expect(_onScreen(t, 'Jan'), isFalse);

    await t.drag(find.byType(SingleChildScrollView), const Offset(2000, 0));
    await t.pumpAndSettle();

    expect(_onScreen(t, 'Jan'), isTrue);
  });

  testWidgets('months that have not happened yet are not offered', (t) async {
    await _pump(t);
    expect(find.text('Nov'), findsNothing);
    expect(find.text('Dec'), findsNothing);
    expect(find.text('Oct'), findsOneWidget);
  });

  testWidgets('tapping a month reports it', (t) async {
    final List<int> taps = await _pump(t);

    await t.tap(find.byKey(const ValueKey<String>('month_chip_9')));
    await t.pump();

    expect(taps, <int>[9]);
  });

  testWidgets('in January only January is offered', (t) async {
    await _pump(t, selected: 1, lastMonth: 1);
    expect(find.text('Jan'), findsOneWidget);
    expect(find.text('Feb'), findsNothing);
    expect(_onScreen(t, 'Jan'), isTrue);
  });

  testWidgets('with no limit given it stops at the real current month',
      (t) async {
    await _pump(t, selected: DateTime.now().month, lastMonth: null);
    final int now = DateTime.now().month;

    expect(find.byKey(ValueKey<String>('month_chip_$now')), findsOneWidget);
    if (now < 12) {
      expect(find.byKey(ValueKey<String>('month_chip_${now + 1}')), findsNothing);
    }
  });
}
