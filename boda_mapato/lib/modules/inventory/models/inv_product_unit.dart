import 'package:flutter/foundation.dart';

/// Price tiers a selling unit can carry (Area 2).
enum InvPriceTier { retail, wholesale, special }

extension InvPriceTierX on InvPriceTier {
  String get wire => name;

  static InvPriceTier parse(String value) => InvPriceTier.values.firstWhere(
        (InvPriceTier t) => t.name == value,
        orElse: () => InvPriceTier.retail,
      );
}

/// One tier's current price for one selling unit.
@immutable
class InvProductPrice {
  const InvProductPrice({
    required this.id,
    required this.productUnitId,
    required this.tier,
    required this.price,
    this.customerId,
    this.effectiveFrom,
  });

  factory InvProductPrice.fromJson(Map<String, dynamic> json) =>
      InvProductPrice(
        id: _toInt(json['id']),
        productUnitId: _toInt(json['product_unit_id']),
        tier: InvPriceTierX.parse((json['tier'] ?? 'retail').toString()),
        price: _toDouble(json['price']),
        customerId: json['customer_id'] == null ? null : _toInt(json['customer_id']),
        effectiveFrom: DateTime.tryParse('${json['effective_from']}'),
      );

  static int _toInt(dynamic v) =>
      v is num ? v.toInt() : int.tryParse('$v') ?? 0;

  static double _toDouble(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0;

  final int id;
  final int productUnitId;
  final InvPriceTier tier;
  final double price;
  final int? customerId;
  final DateTime? effectiveFrom;
}

/// A way a product is sold: bottle, pack or crate. `factor` is how many base
/// units this one contains, so stock stays measured in a single base unit.
@immutable
class InvProductUnit {
  const InvProductUnit({
    required this.id,
    required this.productId,
    required this.name,
    required this.factor,
    required this.isBase,
    this.barcode = '',
    this.status = 'active',
    this.prices = const <InvProductPrice>[],
  });

  factory InvProductUnit.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawPrices =
        (json['prices'] is List) ? json['prices'] as List<dynamic> : const [];

    return InvProductUnit(
      id: InvProductPrice._toInt(json['id']),
      productId: InvProductPrice._toInt(json['product_id']),
      name: (json['name'] ?? '').toString(),
      factor: InvProductPrice._toInt(json['factor'] == null ? 1 : json['factor']),
      isBase: json['is_base'] == true || json['is_base'] == 1,
      barcode: (json['barcode'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      prices: rawPrices
          .map((p) => InvProductPrice.fromJson(p as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final int id;
  final int productId;
  final String name;
  final int factor;
  final bool isBase;
  final String barcode;
  final String status;
  final List<InvProductPrice> prices;

  bool get isActive => status == 'active';

  /// Current price for a tier, optionally for one customer (special tier).
  double? priceFor(InvPriceTier tier, {int? customerId}) {
    for (final InvProductPrice p in prices) {
      if (p.tier != tier) {
        continue;
      }
      if (tier == InvPriceTier.special && p.customerId != customerId) {
        continue;
      }
      return p.price;
    }
    return null;
  }

  double? get retailPrice => priceFor(InvPriceTier.retail);
  double? get wholesalePrice => priceFor(InvPriceTier.wholesale);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvProductUnit &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// One entry in the immutable price-change log.
@immutable
class InvPriceChange {
  const InvPriceChange({
    required this.id,
    required this.tier,
    required this.newPrice,
    required this.createdAt,
    this.oldPrice,
    this.reason = '',
    this.changedByName = '',
  });

  factory InvPriceChange.fromJson(Map<String, dynamic> json) => InvPriceChange(
        id: (json['id'] as num?)?.toInt() ?? 0,
        tier: InvPriceTierX.parse((json['tier'] ?? 'retail').toString()),
        oldPrice: (json['old_price'] as num?)?.toDouble() ??
            double.tryParse('${json['old_price']}'),
        newPrice: (json['new_price'] as num?)?.toDouble() ??
            double.tryParse('${json['new_price']}') ??
            0,
        reason: (json['reason'] ?? '').toString(),
        changedByName: (json['changed_by_name'] ?? '').toString(),
        createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
      );

  final int id;
  final InvPriceTier tier;
  final double? oldPrice;
  final double newPrice;
  final String reason;
  final String changedByName;
  final DateTime createdAt;

  /// Percentage move from the previous price, null on the first ever price.
  double? get changePercent {
    final double? previous = oldPrice;
    if (previous == null || previous == 0) {
      return null;
    }
    return ((newPrice - previous) / previous) * 100;
  }
}
