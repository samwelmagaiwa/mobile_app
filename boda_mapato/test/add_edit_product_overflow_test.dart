import 'package:boda_mapato/modules/inventory/providers/depot_provider.dart';
import 'package:boda_mapato/modules/inventory/providers/inventory_provider.dart';
import 'package:boda_mapato/modules/inventory/screens/products/add_edit_product_screen.dart';
import 'package:boda_mapato/providers/auth_provider.dart';
import 'package:boda_mapato/services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Reproduces overflow bugs on the Add Product page.
/// Ran across the small phone widths we support, both empty and after the
/// user has typed values into every cost/price/qty box (that unlocks the
/// live valuation summary, which is where several of the tight rows live).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget harness(Widget child, Size size) => MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
          ChangeNotifierProvider<InventoryProvider>(
            create: (_) => InventoryProvider(),
          ),
          ChangeNotifierProvider<DepotProvider>(create: (_) => DepotProvider()),
          ChangeNotifierProvider<LocalizationService>.value(
            value: LocalizationService.instance,
          ),
        ],
        child: ScreenUtilInit(
          designSize: size,
          minTextAdapt: true,
          builder: (_, __) => MaterialApp(home: child),
        ),
      );

  const List<Size> viewports = <Size>[
    Size(280, 640),
    Size(320, 568),
    Size(360, 640),
  ];

  for (final Size size in viewports) {
    testWidgets('add product page — empty ${size.width.toInt()}px',
        (WidgetTester tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(harness(const AddEditProductScreen(), size));
      await tester.pump(const Duration(seconds: 2));

      expect(
        tester.takeException(),
        isNull,
        reason: 'Add product page overflowed empty at '
            '${size.width.toInt()}x${size.height.toInt()}',
      );
    });

    testWidgets('add product page — with values ${size.width.toInt()}px',
        (WidgetTester tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(harness(const AddEditProductScreen(), size));
      await tester.pump(const Duration(seconds: 2));

      // Type into name, cost, price, quantity so the valuation summary
      // renders. That's where the long "Muhtasari wa Mzigo Wote" title and
      // profit-row live — the tightest rows on the page.
      final Finder textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        // name field (first)
        await tester.enterText(textFields.at(0), 'Coca-Cola 350ml');
        await tester.pump();
      }
      // Cost / Selling / Qty fields sit further down; the exact indices
      // shift when variants collapse, so tap on labels instead of by index.
      Future<void> typeIntoLabel(String hintFragment, String value) async {
        final Finder field = find.byWidgetPredicate((Widget w) {
          if (w is! TextField) return false;
          final String? h = w.decoration?.hintText;
          return h != null && h.contains(hintFragment);
        });
        if (field.evaluate().isNotEmpty) {
          await tester.enterText(field.first, value);
          await tester.pump();
        }
      }

      await typeIntoLabel('Kununua', '20,000');
      await typeIntoLabel('Kuuza', '25,000');
      await typeIntoLabel('e.g. 100', '150');

      await tester.pump(const Duration(milliseconds: 200));

      expect(
        tester.takeException(),
        isNull,
        reason: 'Add product page overflowed with values at '
            '${size.width.toInt()}x${size.height.toInt()}',
      );
    });
  }
}
