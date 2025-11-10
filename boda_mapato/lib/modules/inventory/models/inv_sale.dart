class InvSaleItem {
  InvSaleItem({
    required this.productId,
    required this.name,
    required this.qty,
    required this.unitPrice,
    required this.unitCostSnapshot,
  });
  final int productId;
  final String name;
  int qty;
  double unitPrice;
  double unitCostSnapshot;

  double get total => qty * unitPrice;
  double get profit => qty * (unitPrice - unitCostSnapshot);
}

class InvPayment {
  InvPayment({
    required this.amount,
    required this.method, // cash / mobile / bank (for MVP we use cash)
    required this.paidAt,
    this.reference = '',
  });
  final double amount;
  final String method;
  final DateTime paidAt;
  final String reference;
}

class InvSale {
  InvSale({
    required this.id,
    required this.number,
    required this.paymentStatus, // paid / debt / partial
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paidTotal,
    required this.createdBy,
    required this.createdAt,
    this.customerId,
    this.dueDate,
    this.payments = const [],
  });

  final int id;
  final String number;
  final int? customerId;
  String paymentStatus;
  final List<InvSaleItem> items;
  double subtotal;
  double discount;
  double tax;
  double total;
  double paidTotal;
  DateTime? dueDate;
  int createdBy;
  DateTime createdAt;
  List<InvPayment> payments;

  double get profit => items.fold(0, (sum, it) => sum + it.profit);
  int get totalItems => items.fold(0, (sum, it) => sum + it.qty);
}
