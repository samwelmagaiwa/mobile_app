import 'package:boda_mapato/modules/inventory/models/inv_depot_models.dart';
import 'package:boda_mapato/modules/inventory/providers/depot_provider.dart';
import 'package:boda_mapato/modules/inventory/providers/inventory_provider.dart';
import 'package:boda_mapato/modules/inventory/screens/alerts/alerts_screen.dart';
import 'package:boda_mapato/modules/inventory/screens/cash/cash_sessions_screen.dart';
import 'package:boda_mapato/modules/inventory/screens/crates/crates_screen.dart';
import 'package:boda_mapato/modules/inventory/screens/credit/credit_screen.dart';
import 'package:boda_mapato/modules/inventory/screens/dispatch/dispatch_screen.dart';
import 'package:boda_mapato/modules/inventory/screens/purchasing/purchasing_screen.dart';
import 'package:boda_mapato/modules/inventory/screens/reports/reports_screen.dart';
import 'package:boda_mapato/modules/inventory/screens/sales/returns_screen.dart';
import 'package:boda_mapato/modules/inventory/screens/settings/depot_settings_screen.dart';
import 'package:boda_mapato/providers/auth_provider.dart';
import 'package:boda_mapato/services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// The empty-state pass lives in inventory_overflow_test.dart. This one fills
/// every screen with rows — including deliberately long names and large
/// numbers, which is where a Row without an Expanded actually breaks — and
/// fails on any layout overflow.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Long enough to blow out any unconstrained text.
  const String longName =
      'Coca-Cola Kwanza Bottlers Limited — Dar es Salaam Regional Depot';
  const String longNote =
      'Delivered late because the access road was flooded and the driver had '
      'to reroute through the industrial area.';

  DepotProvider seededDepot() {
    final DepotProvider depot = DepotProvider();
    depot.seedForTest(
      suppliers: <InvSupplier>[
        const InvSupplier(
          id: 1,
          name: longName,
          phone: '+255 700 000 000',
          contactPerson: 'Emmanuel Mwakalinga Nyerere',
          paymentTermsDays: 30,
          balance: 12500000,
        ),
        const InvSupplier(id: 2, name: 'A', balance: 0),
      ],
      purchaseOrders: <InvPurchaseOrder>[
        const InvPurchaseOrder(
          id: 1,
          number: 'PO-20260902-131415',
          supplierId: 1,
          supplierName: longName,
          status: 'partial',
          total: 98765432,
        ),
      ],
      supplierInvoices: <InvSupplierInvoice>[
        const InvSupplierInvoice(
          id: 1,
          number: 'SUP-INV-2026-000123456',
          supplierId: 1,
          supplierName: longName,
          amount: 98765432,
          paidAmount: 12000,
          status: 'part_paid',
        ),
      ],
      creditCustomers: <InvCreditCustomer>[
        const InvCreditCustomer(
          id: 1,
          name: longName,
          phone: '+255 711 111 111',
          balance: 45000000,
          creditLimit: 30000000,
          isBlocked: true,
          blockReason: longNote,
        ),
        const InvCreditCustomer(
          id: 2,
          name: 'Duka la Mama Anna',
          balance: 0,
          creditLimit: 0,
        ),
      ],
      debtors: <InvDebtorAgeing>[
        const InvDebtorAgeing(
          customerId: 1,
          customerName: longName,
          current: 1000000,
          days31to60: 2000000,
          days61to90: 3000000,
          days90Plus: 39000000,
          total: 45000000,
          oldestDays: 187,
        ),
      ],
      cashSessions: <InvCashSession>[
        const InvCashSession(
          id: 1,
          reference: 'CS-20260902-080000',
          status: 'closed',
          userName: 'Emmanuel Mwakalinga Nyerere',
          businessDate: '2026-09-02',
          openingFloat: 50000,
          expectedCash: 12345678,
          countedCash: 12300000,
          expensesTotal: 45678,
          difference: -45678,
          differenceReason: longNote,
        ),
      ],
      activeSession: const InvCashSession(
        id: 2,
        reference: 'CS-20260902-140000',
        status: 'open',
        userName: 'Grace Shirima',
        businessDate: '2026-09-02',
        openingFloat: 50000,
        expectedCash: 987654,
        countedCash: 0,
        expensesTotal: 12000,
        difference: 0,
        expenses: <InvCashExpense>[
          InvCashExpense(id: 1, description: longNote, amount: 12000),
        ],
      ),
      crateTypes: const <InvCrateType>[
        InvCrateType(id: 1, name: 'Crate', depositValue: 2000),
      ],
      crateBalances: const <InvCrateBalance>[
        InvCrateBalance(
          customerId: 1,
          customerName: longName,
          crateTypeId: 1,
          crateTypeName: 'Returnable glass bottle crate (24)',
          held: 1250,
          depositAtRisk: 2500000,
        ),
      ],
      cratePosition: const <InvCrateBalance>[
        InvCrateBalance(
          crateTypeId: 1,
          crateTypeName: 'Returnable glass bottle crate (24)',
          held: 0,
          issued: 9999,
          returned: 8000,
          broken: 250,
          outWithCustomers: 1749,
          depositAtRisk: 3498000,
        ),
      ],
      parkedSales: <InvParkedSale>[
        InvParkedSale(
          id: 1,
          reference: 'PK-20260902-101112',
          customerName: longName,
          total: 87654321,
          note: longNote,
          parkedByName: 'Grace Shirima',
          createdAt: DateTime(2026, 9, 2),
        ),
      ],
      returns: <InvSaleReturn>[
        InvSaleReturn(
          id: 1,
          reference: 'RET-20260902-101112',
          saleId: 1,
          saleNumber: 'S00042',
          type: 'return',
          amount: 1234567,
          status: 'pending',
          reason: longNote,
          createdAt: DateTime(2026, 9, 2),
        ),
      ],
      dispatches: const <InvDispatch>[
        InvDispatch(
          id: 1,
          reference: 'DSP-20260902-060000',
          status: 'on_route',
          vehicle: 'T 123 ABC / Trailer T 456 DEF',
          agentName: 'Emmanuel Mwakalinga',
          route: 'Kariakoo → Buguruni → Tabata → Segerea → Ukonga',
          dispatchDate: '2026-09-02',
          linesCount: 12,
          totalLoaded: 4800,
          cashExpected: 12345678,
          cashReturned: 12000000,
          lines: <InvDispatchLine>[
            InvDispatchLine(
              id: 1,
              productId: 1,
              loadedQuantity: 4800,
              returnedQuantity: 120,
              soldQuantity: 4680,
              unitPrice: 15000,
              productName:
                  'Coca-Cola 500ml Returnable Glass Bottle Crate of 24',
              productUnit: 'crate',
              batchNumber: 'BATCH-2026-09-0001',
            ),
          ],
        ),
      ],
      reports: const <InvReportMeta>[
        InvReportMeta(key: 'daily_sales', title: 'Daily sales'),
        InvReportMeta(
          key: 'product_profitability',
          title: 'Product profitability by category and brand',
        ),
        InvReportMeta(key: 'stock_valuation', title: 'Stock valuation'),
        InvReportMeta(key: 'debtors_ageing', title: 'Debtors ageing'),
      ],
      alerts: <InvAlert>[
        InvAlert(
          id: 1,
          type: 'over_credit_limit',
          severity: 'critical',
          title: 'Over credit limit: $longName',
          body: longNote,
          status: 'open',
          createdAt: DateTime(2026, 9, 2),
        ),
        InvAlert(
          id: 2,
          type: 'low_stock',
          severity: 'warning',
          title: 'Low stock',
          status: 'open',
          createdAt: DateTime(2026, 9, 2),
        ),
      ],
      auditLog: <InvAuditEntry>[
        InvAuditEntry(
          id: 1,
          entityType: 'customer_credit',
          action: 'updated',
          summary: longName,
          userName: 'Emmanuel Mwakalinga Nyerere',
          createdAt: DateTime(2026, 9, 2, 14, 5),
        ),
      ],
      settings: const <String, String>{
        'depot_name': longName,
        'depot_phone': '+255 700 000 000',
        'depot_address': longNote,
        'invoice_prefix': 'INV',
        'invoice_next_number': '1',
        'tax_percent': '18',
        'max_discount_percent': '10',
        'large_discount_percent': '15',
        'low_stock_threshold': '5',
        'expiry_alert_days': '30',
        'overdue_alert_days': '7',
      },
    );
    return depot;
  }

  final Map<String, Widget Function()> screens = <String, Widget Function()>{
    'purchasing': () => const PurchasingScreen(),
    'credit': () => const CreditScreen(),
    'cash sessions': () => const CashSessionsScreen(),
    'crates': () => const CratesScreen(),
    'dispatch': () => const DispatchScreen(),
    'returns & parked': () => const ReturnsScreen(),
    'reports': () => const ReportsScreen(),
    'alerts': () => const AlertsScreen(),
    'depot settings': () => const DepotSettingsScreen(),
  };

  Widget harness(Widget child, Size size, DepotProvider depot) => MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
          ChangeNotifierProvider<InventoryProvider>(
            create: (_) => InventoryProvider(),
          ),
          ChangeNotifierProvider<DepotProvider>.value(value: depot),
          ChangeNotifierProvider<LocalizationService>.value(
            value: LocalizationService.instance,
          ),
        ],
        child: ScreenUtilInit(
          designSize: size,
          minTextAdapt: true,
          builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
        ),
      );

  const List<Size> viewports = <Size>[
    Size(320, 568),
    Size(360, 640),
    Size(280, 640), // narrower than any real phone
  ];

  for (final Size size in viewports) {
    group('with data at ${size.width.toInt()}x${size.height.toInt()}', () {
      for (final MapEntry<String, Widget Function()> entry in screens.entries) {
        testWidgets('${entry.key} lays out without overflow',
            (WidgetTester tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final DepotProvider depot = seededDepot();
          await tester.pumpWidget(harness(entry.value(), size, depot));
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pump(const Duration(seconds: 2));

          // Guard against a false pass: the screen must actually be drawing
          // rows, not sitting on a spinner or an empty state.
          expect(
            find.byType(CircularProgressIndicator),
            findsNothing,
            reason: '${entry.key} was still loading, so nothing was measured',
          );

          expect(
            tester.takeException(),
            isNull,
            reason: '${entry.key} overflowed at '
                '${size.width.toInt()}x${size.height.toInt()} with data',
          );
        });
      }
    });
  }

  testWidgets('tab bars scroll rather than overflow at 280px',
      (WidgetTester tester) async {
    const Size tiny = Size(280, 640);
    tester.view.physicalSize = tiny;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      harness(const PurchasingScreen(), tiny, seededDepot()),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(TabBar), findsOneWidget);
    // The tab strip must scroll rather than squeeze its labels.
    expect(tester.widget<TabBar>(find.byType(TabBar)).isScrollable, isTrue);
    expect(tester.takeException(), isNull);
  });
}
