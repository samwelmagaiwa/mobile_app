import 'package:flutter/foundation.dart';

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
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: (json['name'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        status: (json['status'] ?? 'active').toString(),
        totalProducts: (json['products_count'] as num?)?.toInt() ?? 0,
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
