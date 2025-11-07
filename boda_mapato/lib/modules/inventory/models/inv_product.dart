class InvProduct {
  InvProduct({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.costPrice,
    required this.sellingPrice,
    required this.unit,
    required this.quantity,
    required this.minStock,
    required this.status,
    required this.barcode,
    required this.createdBy,
  });

  final int id;
  String name;
  String sku;
  String category;
  double costPrice;
  double sellingPrice;
  String unit;
  int quantity;
  int minStock;
  String status; // active/inactive
  String barcode;
  int createdBy;
}
