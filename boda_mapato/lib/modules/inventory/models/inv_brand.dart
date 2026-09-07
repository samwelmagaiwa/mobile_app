import 'package:flutter/foundation.dart';

// MySQL can return numeric columns as strings through PDO, so `as num?`
// throws instead of falling through to `??`. Check the runtime type instead.
int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

/// A product brand (Area 2 — products, units & pricing).
@immutable
class InvBrand {
  const InvBrand({
    required this.id,
    required this.name,
    this.description = '',
    this.status = 'active',
    this.totalProducts = 0,
  });

  factory InvBrand.fromJson(Map<String, dynamic> json) => InvBrand(
        id: _toInt(json['id']),
        name: (json['name'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        status: (json['status'] ?? 'active').toString(),
        totalProducts: _toInt(json['products_count']),
      );

  final int id;
  final String name;
  final String description;
  final String status;
  final int totalProducts;

  bool get isActive => status == 'active';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvBrand && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
