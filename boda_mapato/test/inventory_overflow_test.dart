import 'package:boda_mapato/modules/inventory/models/inv_product.dart';
import 'package:boda_mapato/modules/inventory/providers/depot_provider.dart';
import 'package:boda_mapato/modules/inventory/providers/inventory_provider.dart';
import 'package:boda_mapato/modules/inventory/screens/alerts/alerts_screen.dart';
import 'package:boda_mapato/modules/inventory/screens/cash/cash_sessions_screen.dart';
import 'package:boda_mapato/modules/inventory/screens/crates/crates_screen.dart';
import 'package:boda_mapato/modules/inventory/screens/credit/credit_screen.dart';
import 'package:boda_mapato/modules/inventory/screens/dashboard/inventory_dashboard_screen.dart';
import 'package:boda_mapato/modules/inventory/screens/dispatch/dispatch_screen.dart';
import 'package:boda_mapato/modules/inventory/screens/products/product_units_screen.dart';
import 'package:boda_mapato/modules/inventory/screens/reminders/inventory_reminders_screen.dart';
import 'package:boda_mapato/modules/inventory/screens/purchasing/purchasing_screen.dart';
import 'package:boda_mapato/modules/inventory/screens/reports/reports_screen.dart';
import 'package:boda_mapato/modules/inventory/screens/sales/returns_screen.dart';
import 'package:boda_mapato/modules/inventory/screens/settings/depot_settings_screen.dart';
import 'package:boda_mapato/modules/inventory/screens/stock/batches_screen.dart';
import 'package:boda_mapato/modules/inventory/screens/stock/stock_levels_screen.dart';
import 'package:boda_mapato/modules/inventory/screens/stock/stock_ops_screen.dart';
import 'package:boda_mapato/modules/inventory/screens/stock/stock_counts_screen.dart';
import 'package:boda_mapato/modules/inventory/screens/stock/write_offs_screen.dart';
import 'package:boda_mapato/providers/auth_provider.dart';
import 'package:boda_mapato/services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Renders every inventory screen at the smallest phone sizes we support and
/// fails if Flutter reports a layout overflow.
///
/// A RenderFlex overflow surfaces as a FlutterError during paint, which the
/// test framework hands back through `tester.takeException()`. Any non-null
/// exception here means a real, user-visible "yellow stripes" bug.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Small, common Android sizes plus a very narrow one to squeeze layouts.
  const List<Size> viewports = <Size>[
    Size(320, 568), // smallest phone still in use
    Size(360, 640), // the most common Android size
    Size(411, 731), // Pixel-class
  ];

  final Map<String, Widget Function()> screens = <String, Widget Function()>{
    'inventory dashboard': () => const InventoryDashboardScreen(),
    'stock levels': () => const StockLevelsScreen(),
    'stock ops': () => const StockOpsScreen(),
    'reminders': () => const InventoryRemindersScreen(),
    'batches & expiry': () => const BatchesScreen(),
    'stock counts': () => const StockCountsScreen(),
    'write-offs': () => const WriteOffsScreen(),
    'purchasing': () => const PurchasingScreen(),
    'credit': () => const CreditScreen(),
    'cash sessions': () => const CashSessionsScreen(),
    'crates': () => const CratesScreen(),
    'dispatch': () => const DispatchScreen(),
    'returns & parked': () => const ReturnsScreen(),
    'reports': () => const ReportsScreen(),
    'alerts': () => const AlertsScreen(),
    'depot settings': () => const DepotSettingsScreen(),
    'product units & pricing': () => ProductUnitsScreen(
          product: InvProduct(
            id: 1,
            // Deliberately long, to prove the header truncates rather than
            // overflowing.
            name: 'Coca-Cola 500ml Returnable Glass Bottle Crate of 24',
            sku: 'CC-500-RGB-24',
            category: 'Soft drinks',
            costPrice: 12000,
            sellingPrice: 15000,
            unit: 'bottle',
            quantity: 480,
            minStock: 50,
            status: 'active',
            barcode: '5449000000996',
            createdBy: 1,
          ),
        ),
  };

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
          builder: (_, __) => MaterialApp(
            home: Scaffold(body: child),
          ),
        ),
      );

  for (final Size size in viewports) {
    group('${size.width.toInt()}x${size.height.toInt()}', () {
      for (final MapEntry<String, Widget Function()> entry in screens.entries) {
        testWidgets('${entry.key} lays out without overflow',
            (WidgetTester tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(harness(entry.value(), size));
          // Let post-frame loads, animations and the empty states settle.
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pump(const Duration(seconds: 2));

          expect(
            tester.takeException(),
            isNull,
            reason: '${entry.key} overflowed at '
                '${size.width.toInt()}x${size.height.toInt()}',
          );
        });
      }
    });
  }

  group('extreme narrow width', () {
    // 280 logical pixels is narrower than any phone we target; if a layout
    // survives this, it survives a large system font on a real device.
    const Size tiny = Size(280, 640);

    for (final MapEntry<String, Widget Function()> entry in screens.entries) {
      testWidgets('${entry.key} survives 280px', (WidgetTester tester) async {
        tester.view.physicalSize = tiny;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(harness(entry.value(), tiny));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(seconds: 2));

        expect(
          tester.takeException(),
          isNull,
          reason: '${entry.key} overflowed at 280px wide',
        );
      });
    }
  });
}
