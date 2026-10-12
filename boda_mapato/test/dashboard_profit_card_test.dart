import 'package:boda_mapato/models/login_response.dart';
import 'package:boda_mapato/modules/inventory/providers/inventory_provider.dart';
import 'package:boda_mapato/modules/inventory/screens/dashboard/inventory_dashboard_screen.dart';
import 'package:boda_mapato/providers/auth_provider.dart';
import 'package:boda_mapato/services/api_service.dart';
import 'package:boda_mapato/services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _Api extends ApiService {
  _Api(this.count);
  final int count;

  @override
  Future<Map<String, dynamic>?> getOrNull(String endpoint,
      {bool requireAuth = true}) async {
    if (endpoint.startsWith('/inventory/products')) {
      return <String, dynamic>{
        'data': <dynamic>[
          for (int i = 1; i <= count; i++)
            <String, dynamic>{
              'id': i, 'name': 'Product $i', 'sku': 'SKU-$i',
              'cost_price': 100, 'selling_price': 150, 'unit': 'carton',
              'quantity': i, 'min_stock': 1, 'status': 'active',
            },
        ],
        'meta': <String, dynamic>{'current_page': 1, 'last_page': 1, 'per_page': 100, 'total': count},
      };
    }
    // KPI and summary endpoints answer with an object, everything else with a list.
    if (endpoint.contains('kpis') || endpoint.contains('summary') || endpoint.contains('chart')) {
      return <String, dynamic>{'data': <String, dynamic>{}};
    }
    return <String, dynamic>{'data': <dynamic>[]};
  }
}

class _Admin extends AuthProvider {
  @override
  UserData? get user => UserData(
      id: '1', name: 'Admin', email: 'a@a.test', role: 'admin', isActive: true);
}

void _ignoreTestFontOverflow() {
  final void Function(FlutterErrorDetails)? original = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails d) {
    if (d.exceptionAsString().contains('overflowed')) return;
    original?.call(d);
  };
  addTearDown(() => FlutterError.onError = original);
}

Future<void> _pump(WidgetTester t, int count) async {
  _ignoreTestFontOverflow();
  t.view.physicalSize = const Size(1170, 4000);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);

  final InventoryProvider inv = InventoryProvider(api: _Api(count));
  await inv.bootstrap();
  await t.pumpWidget(MultiProvider(
    providers: <ChangeNotifierProvider<ChangeNotifier>>[
      ChangeNotifierProvider<InventoryProvider>.value(value: inv),
      ChangeNotifierProvider<AuthProvider>(create: (_) => _Admin()),
      ChangeNotifierProvider<LocalizationService>.value(value: LocalizationService.instance),
    ],
    child: ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => const MaterialApp(home: Scaffold(body: InventoryDashboardScreen())),
    ),
  ));
  await t.pump(const Duration(seconds: 3)); // the dashboard starts a 300 ms timer and a 2 s animation
  await t.pump(const Duration(seconds: 3));
}

Finder _row(int rank) => find.byKey(ValueKey<String>('profit_row_$rank'));
Finder get _seeAll => find.byKey(const ValueKey<String>('profit_see_all'));

void main() {
  testWidgets('dashboard: 12 products -> 8 rows and an active button that opens the full list',
      (t) async {
    await _pump(t, 12);

    expect(_row(8), findsOneWidget);
    expect(_row(9), findsNothing);
    expect(t.widget<OutlinedButton>(_seeAll).onPressed, isNotNull);

    await t.ensureVisible(_seeAll);
    await t.tap(_seeAll);
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(seconds: 1));

    // The full screen lists all twelve.
    expect(_row(12), findsOneWidget);
    expect(_seeAll, findsNothing);
  });

  testWidgets('dashboard: 5 products -> all 5 rows and a muted button', (t) async {
    await _pump(t, 5);

    expect(_row(5), findsOneWidget);
    expect(t.widget<OutlinedButton>(_seeAll).onPressed, isNull);
  });
}
