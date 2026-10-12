import 'package:boda_mapato/models/user_permissions.dart';
import 'package:boda_mapato/modules/inventory/models/inv_product.dart';
import 'package:boda_mapato/modules/inventory/providers/inventory_provider.dart';
import 'package:boda_mapato/modules/inventory/screens/dashboard/product_profit_screen.dart';
import 'package:boda_mapato/modules/inventory/screens/inventory_home.dart';
import 'package:boda_mapato/modules/inventory/screens/widgets/product_profit_table.dart';
import 'package:boda_mapato/services/api_service.dart';
import 'package:boda_mapato/services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

InvProduct _product(int n, {int? quantity, String unit = 'carton'}) => InvProduct(
      id: n,
      name: 'Product $n',
      sku: 'SKU-$n',
      category: 'Soda',
      costPrice: 100,
      sellingPrice: 150,
      unit: unit,
      quantity: quantity ?? n,
      minStock: 1,
      status: 'active',
      barcode: '',
      createdBy: 1,
    );

List<InvProduct> _products(int count) =>
    <InvProduct>[for (int i = 1; i <= count; i++) _product(i)];

/// Flutter's test font draws every letter as a wide square, so rows that fit on a phone
/// "overflow" here. Those warnings say nothing about the real app; anything else still fails.
void _ignoreTestFontOverflow() {
  final void Function(FlutterErrorDetails)? original = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails d) {
    if (d.exceptionAsString().contains('overflowed')) return;
    original?.call(d);
  };
  addTearDown(() => FlutterError.onError = original);
}

Future<void> _pumpTable(
  WidgetTester t,
  List<InvProduct> products, {
  int? maxRows,
  VoidCallback? onSeeAll,
}) async {
  _ignoreTestFontOverflow();
  t.view.physicalSize = const Size(1170, 2532);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: ProductProfitTable(
            products: products, maxRows: maxRows, onSeeAll: onSeeAll),
      ),
    ),
  ));
}

Finder _row(int rank) => find.byKey(ValueKey<String>('profit_row_$rank'));
Finder get _seeAll => find.byKey(const ValueKey<String>('profit_see_all'));
OutlinedButton _button(WidgetTester t) => t.widget<OutlinedButton>(_seeAll);

/// Canned catalogue served in pages of up to 100, like the real server.
class _CatalogueApi extends ApiService {
  _CatalogueApi(this.count);
  final int count;
  final List<String> requests = <String>[];

  @override
  Future<Map<String, dynamic>?> getOrNull(String endpoint,
      {bool requireAuth = true}) async {
    if (endpoint.startsWith('/inventory/products')) {
      requests.add(endpoint);
      final Uri uri = Uri.parse(endpoint);
      final int page = int.parse(uri.queryParameters['page'] ?? '1');
      final int per = int.parse(uri.queryParameters['per_page'] ?? '20');
      final int from = (page - 1) * per;
      final int to = (from + per).clamp(0, count);
      return <String, dynamic>{
        'data': <dynamic>[
          for (int i = from; i < to; i++)
            <String, dynamic>{
              'id': i + 1, 'name': 'Product ${i + 1}', 'sku': 'SKU-${i + 1}',
              'cost_price': 100, 'selling_price': 150, 'unit': 'carton',
              'quantity': i + 1, 'min_stock': 1, 'status': 'active',
            },
        ],
        'meta': <String, dynamic>{
          'current_page': page,
          'last_page': (count / per).ceil(),
          'per_page': per,
          'total': count,
        },
      };
    }
    return <String, dynamic>{'data': <dynamic>[]};
  }
}

void main() {
  group('ProductProfitTable.ranked', () {
    test('puts the product with the most units first', () {
      final List<InvProduct> ranked = ProductProfitTable.ranked(<InvProduct>[
        _product(1, quantity: 5),
        _product(2, quantity: 900),
        _product(3, quantity: 40),
      ]);
      expect(ranked.map((InvProduct p) => p.id), <int>[2, 3, 1]);
    });

    test('does not reorder the list it was given', () {
      final List<InvProduct> input = _products(3);
      ProductProfitTable.ranked(input);
      expect(input.map((InvProduct p) => p.id), <int>[1, 2, 3]);
    });
  });

  group('dashboard card (capped at 8 rows)', () {
    testWidgets('fewer than 8 products: all shown, the button is muted',
        (t) async {
      int taps = 0;
      await _pumpTable(t, _products(5), maxRows: 8, onSeeAll: () => taps++);

      for (int i = 1; i <= 5; i++) {
        expect(_row(i), findsOneWidget);
      }
      expect(_row(6), findsNothing);
      expect(_button(t).onPressed, isNull, reason: 'nothing more to see');

      await t.tap(_seeAll, warnIfMissed: false);
      expect(taps, 0);
    });

    testWidgets('exactly 8 products: still muted (nothing hidden)', (t) async {
      await _pumpTable(t, _products(8), maxRows: 8, onSeeAll: () {});
      expect(_row(8), findsOneWidget);
      expect(_button(t).onPressed, isNull);
    });

    testWidgets('9 or more: only 8 rows, and the button becomes active',
        (t) async {
      int taps = 0;
      await _pumpTable(t, _products(9), maxRows: 8, onSeeAll: () => taps++);

      expect(_row(8), findsOneWidget);
      expect(_row(9), findsNothing, reason: 'the 9th lives on the full screen');
      expect(_button(t).onPressed, isNotNull);
      expect(find.textContaining('(9)'), findsOneWidget);

      await t.tap(_seeAll);
      expect(taps, 1);
    });

    testWidgets('shows the eight BIGGEST products, not the first eight given',
        (t) async {
      // Product n has n units, so the biggest are 20..13.
      await _pumpTable(t, _products(20), maxRows: 8, onSeeAll: () {});

      expect(find.text('Product 20'), findsOneWidget);
      expect(find.text('Product 13'), findsOneWidget);
      expect(find.text('Product 12'), findsNothing);
      expect(find.text('Product 1'), findsNothing);
    });
  });

  group('full list (no cap)', () {
    testWidgets('shows every product and no see-all button', (t) async {
      await _pumpTable(t, _products(12));

      expect(_row(12), findsOneWidget);
      expect(_seeAll, findsNothing);
    });

    testWidgets('each row has name, unit, units, cost and profit', (t) async {
      await _pumpTable(t, <InvProduct>[_product(1, quantity: 1000, unit: 'crate')]);

      expect(find.text('Product 1'), findsOneWidget);
      expect(find.text('CRATE'), findsOneWidget);
      expect(find.text('1000'), findsOneWidget); // units
      expect(find.text('100,000'), findsOneWidget); // cost: 100 x 1000
      expect(find.text('50,000'), findsOneWidget); // profit: (150 - 100) x 1000
    });

    testWidgets('title and sub-title are the ones on the dashboard', (t) async {
      await _pumpTable(t, _products(2));
      final LocalizationService loc = LocalizationService.instance;

      expect(find.text(loc.translate('profit_margins_title')), findsOneWidget);
      expect(find.text(loc.translate('top_products_sorted')), findsOneWidget);
    });
  });

  group('full screen', () {
    Future<_CatalogueApi> pumpScreen(WidgetTester t, int count) async {
      _ignoreTestFontOverflow();
      t.view.physicalSize = const Size(1170, 2532);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);

      final _CatalogueApi api = _CatalogueApi(count);
      await t.pumpWidget(MultiProvider(
        providers: <ChangeNotifierProvider<ChangeNotifier>>[
          ChangeNotifierProvider<InventoryProvider>(
              create: (_) => InventoryProvider(api: api)),
          ChangeNotifierProvider<LocalizationService>.value(
              value: LocalizationService.instance),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) =>
              const MaterialApp(home: Scaffold(body: ProductProfitScreen())),
        ),
      ));
      await t.pumpAndSettle();
      return api;
    }

    testWidgets('shows a catalogue that spans several server pages',
        (t) async {
      final _CatalogueApi api = await pumpScreen(t, 130);

      // 130 products = two pages of up to 100, and every one is on screen.
      expect(api.requests.where((String r) => r.contains('per_page=100')).length, 2);
      expect(_row(130), findsOneWidget);
      expect(find.text('Product 130'), findsOneWidget);
      expect(find.text('Product 1'), findsOneWidget); // the smallest line still appears
      expect(_seeAll, findsNothing);
    });

    testWidgets('an empty catalogue shows the empty message, not a blank table',
        (t) async {
      await pumpScreen(t, 0);
      expect(_row(1), findsNothing);
      expect(find.text(LocalizationService.instance.translate('no_data')),
          findsOneWidget);
    });
  });

  group('menu', () {
    final LocalizationService loc = LocalizationService.instance;

    test('"Profit by product" is offered to anyone who can see reports', () {
      final List<String> keys =
          inventoryMenuKeys(UserPermissions.fromRole('admin'), loc);
      expect(keys, contains('product_profit'));
    });

    test('and hidden from someone who cannot', () {
      final List<String> keys =
          inventoryMenuKeys(UserPermissions.fromRole('sales_officer'), loc);
      expect(keys, isNot(contains('product_profit')));
    });

    test('it is the LAST page, so no existing menu number moves', () {
      final List<String> keys =
          inventoryMenuKeys(UserPermissions.fromRole('admin'), loc);
      expect(keys.last, 'product_profit');
      // The pages that were there before keep their order.
      expect(
        keys.take(keys.length - 1).toList(),
        <String>[
          'dashboard', 'products_hub', 'stock_hub', 'sales_hub',
          'supply_chain_hub', 'finance_hub', 'credit', 'settings',
        ],
      );
    });
  });
}
