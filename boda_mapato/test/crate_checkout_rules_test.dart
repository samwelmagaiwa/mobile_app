import 'package:boda_mapato/modules/inventory/screens/sales/crate_checkout_rules.dart';
import 'package:flutter_test/flutter_test.dart';

CrateCheckoutProblem? _check({
  bool brought = false,
  bool hasTypes = true,
  int? type = 1,
  String qty = '10',
}) =>
    crateCheckoutProblem(
      customerBroughtCrates: brought,
      hasCrateTypes: hasTypes,
      crateTypeId: type,
      quantityText: qty,
    );

void main() {
  group('crateCheckoutProblem', () {
    test('a customer who brought their crates needs nothing recorded', () {
      expect(_check(brought: true, hasTypes: false, type: null, qty: ''), isNull);
    });

    test('crates owed with a type and a quantity is fine', () {
      expect(_check(), isNull);
      expect(_check(qty: ' 10 '), isNull);
    });

    test('owing crates with no crate types set up is blocked, not skipped', () {
      expect(_check(hasTypes: false, type: null),
          CrateCheckoutProblem.noCrateTypes);
    });

    test('owing crates without choosing the type is blocked', () {
      expect(_check(type: null), CrateCheckoutProblem.chooseType);
    });

    test('owing crates without a sensible quantity is blocked', () {
      for (final String bad in <String>['', ' ', '0', '-3', 'abc', '1.5']) {
        expect(_check(qty: bad), CrateCheckoutProblem.enterQuantity,
            reason: '"$bad" must not pass');
      }
    });
  });

  test('every problem has a message in both languages', () {
    for (final CrateCheckoutProblem p in CrateCheckoutProblem.values) {
      expect(crateCheckoutMessage(p, swahili: false), isNotEmpty);
      expect(crateCheckoutMessage(p, swahili: true), isNotEmpty);
    }
  });
}
