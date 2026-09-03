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
    this.description,
    this.categoryId,
    this.brandId,
    this.categoryName,
    this.brandName,
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
  final int createdBy;
  String? description;
  int? categoryId;
  int? brandId;
  String? categoryName;
  String? brandName;

  double get totalCostPrice => costPrice * quantity;
  double get totalSellingPrice => sellingPrice * quantity;
  double get totalExpectedProfit => (sellingPrice - costPrice) * quantity;
}
