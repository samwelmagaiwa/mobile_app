import 'package:flutter/foundation.dart';

import 'inv_depot_models.dart';

/// What one customer owes in crates, worked out from the per-customer crate
/// balances (the same figures as the Crates & empties "customers" tab).
///
/// A positive balance means the customer holds the depot's crates and must return
/// them; a negative one means the depot holds the customer's.
@immutable
class CratesOwed {
  const CratesOwed({
    this.held = const <InvCrateBalance>[],
    this.owedToCustomer = const <InvCrateBalance>[],
  });

  factory CratesOwed.forCustomer(
      Iterable<InvCrateBalance> balances, int customerId) {
    final List<InvCrateBalance> mine = balances
        .where((InvCrateBalance b) => b.customerId == customerId)
        .toList();
    return CratesOwed(
      held: mine.where((InvCrateBalance b) => b.held > 0).toList(),
      owedToCustomer: mine.where((InvCrateBalance b) => b.held < 0).toList(),
    );
  }

  /// Crates the customer must return, one entry per crate type.
  final List<InvCrateBalance> held;

  /// Crates the depot owes the customer (rare), one entry per crate type.
  final List<InvCrateBalance> owedToCustomer;

  bool get isNone => held.isEmpty && owedToCustomer.isEmpty;

  /// Total crates the customer must return.
  int get total => held.fold<int>(0, (int s, InvCrateBalance b) => s + b.held);

  /// Security deposit tied up in those crates.
  double get depositAtRisk => held.fold<double>(
      0, (double s, InvCrateBalance b) => s + b.depositAtRisk);

  /// e.g. `10 × Crate, 24 × Empty bottle`.
  String get heldSummary => held
      .map((InvCrateBalance b) => '${b.held} × ${b.crateTypeName}')
      .join(', ');

  /// e.g. `3 × Crate`.
  String get owedToCustomerSummary => owedToCustomer
      .map((InvCrateBalance b) => '${-b.held} × ${b.crateTypeName}')
      .join(', ');
}
