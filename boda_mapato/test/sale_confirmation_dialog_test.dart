import 'package:boda_mapato/modules/inventory/models/inv_sale.dart';
import 'package:boda_mapato/modules/inventory/screens/sales/sale_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

InvSaleItem _item(String name, int qty, double price) => InvSaleItem(
      productId: 1,
      name: name,
      qty: qty,
      unitPrice: price,
      unitCostSnapshot: 0,
    );

/// Opens the dialog from a button and reports what the user answered.
Future<bool?> _open(WidgetTester t, SaleConfirmation sale,
    {bool swahili = false,
    Size logicalSize = const Size(390, 844),
    required Future<void> Function() answer}) async {
  // A real phone screen (390x844 logical), not the 800x600 default test surface.
  t.view.physicalSize = logicalSize * 3;
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);

  bool? result;
  await t.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async => result =
                    await showSaleConfirmation(context, sale, swahili: swahili),
                child: const Text('checkout'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await t.tap(find.text('checkout'));
  await t.pumpAndSettle();
  await answer();
  await t.pumpAndSettle();
  return result;
}

void main() {
  final SaleConfirmation cash = SaleConfirmation(
    items: <InvSaleItem>[_item('Pepsi 300ml', 10, 11200), _item('Soda crate', 1, 5000)],
    subtotal: 117000,
    discount: 5000,
    total: 112000,
    paymentMode: 'cash',
  );

  testWidgets('shows each product, the subtotal and the total being sold',
      (t) async {
    await _open(t, cash, answer: () async {
      expect(find.text('Confirm sale'), findsOneWidget);
      expect(find.text('10 × Pepsi 300ml'), findsOneWidget);
      expect(find.text('TZS 112000'), findsWidgets); // line total + grand total
      expect(find.text('TZS 117000'), findsOneWidget); // subtotal
      expect(find.text('- TZS 5000'), findsOneWidget); // discount
      expect(find.byKey(const ValueKey<String>('sale_confirm_total')),
          findsOneWidget);
      expect(
          t.widget<Text>(find.byKey(const ValueKey<String>('sale_confirm_total'))).data,
          'TZS 112000');
      await t.tap(find.byKey(const ValueKey<String>('sale_confirm_no')));
    });
  });

  testWidgets('No closes the card and answers false', (t) async {
    final bool? r = await _open(t, cash, answer: () async {
      await t.tap(find.byKey(const ValueKey<String>('sale_confirm_no')));
    });
    expect(r, isFalse);
    expect(find.text('Confirm sale'), findsNothing);
  });

  testWidgets('Yes answers true', (t) async {
    final bool? r = await _open(t, cash, answer: () async {
      await t.tap(find.byKey(const ValueKey<String>('sale_confirm_yes')));
    });
    expect(r, isTrue);
  });

  testWidgets('a debt sale shows the customer, the balance and crates owed',
      (t) async {
    final SaleConfirmation debt = SaleConfirmation(
      items: <InvSaleItem>[_item('Pepsi 300ml', 10, 11200)],
      subtotal: 112000,
      discount: 0,
      total: 112000,
      paymentMode: 'debt',
      customerName: 'mama anna',
      crateTypeName: 'Crate',
      crateQty: 10,
    );
    await _open(t, debt, answer: () async {
      expect(find.text('On debt'), findsOneWidget);
      expect(find.text('mama anna'), findsOneWidget);
      expect(find.text('Balance owed'), findsOneWidget);
      expect(find.text('10 × Crate'), findsOneWidget);
      expect(find.text('Discount'), findsNothing); // none given: row hidden
      await t.tap(find.byKey(const ValueKey<String>('sale_confirm_no')));
    });
  });

  testWidgets('a part payment shows what was paid and what remains', (t) async {
    final SaleConfirmation part = SaleConfirmation(
      items: <InvSaleItem>[_item('Pepsi 300ml', 10, 11200)],
      subtotal: 112000,
      discount: 0,
      total: 112000,
      paymentMode: 'partial',
      customerName: 'mama anna',
      paidNow: 40000,
    );
    await _open(t, part, answer: () async {
      expect(find.text('TZS 40000'), findsOneWidget);
      expect(find.text('TZS 72000'), findsOneWidget); // balance
      await t.tap(find.byKey(const ValueKey<String>('sale_confirm_no')));
    });
  });

  testWidgets('Swahili labels', (t) async {
    await _open(t, cash, swahili: true, answer: () async {
      expect(find.text('Thibitisha mauzo'), findsOneWidget);
      expect(find.text('Hapana'), findsOneWidget);
      expect(find.text('Ndiyo, uza'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey<String>('sale_confirm_no')));
    });
  });

  testWidgets('a huge total, a long cart and a small phone do not overflow',
      (t) async {
    final SaleConfirmation big = SaleConfirmation(
      items: List<InvSaleItem>.generate(
          40, (int i) => _item('Very long product name number $i 500ml x 24', 3, 1234567)),
      subtotal: 987654321098,
      discount: 0,
      total: 987654321098,
      paymentMode: 'partial',
      customerName: 'A customer with a rather long name indeed',
      paidNow: 123456789,
      crateTypeName: 'Crate',
      crateQty: 250,
    );
    await _open(t, big, logicalSize: const Size(320, 568), answer: () async {
      expect(t.takeException(), isNull);
      expect(find.byKey(const ValueKey<String>('sale_confirm_yes')), findsOneWidget);
      await t.tap(find.byKey(const ValueKey<String>('sale_confirm_no')));
    });
  });
}
