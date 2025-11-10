import 'package:flutter/foundation.dart';

@immutable
class InvCategory {
  const InvCategory({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.parentId,
    required this.imagePath,
    required this.status,
    required this.totalProducts,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });
  final int id;
  final String name;
  final String code;
  final String description;
  final int? parentId; // nullable for root categories
  final String? imagePath; // local path or URL
  final String status; // 'active' | 'inactive' (stored lower-case for consistency)
  final int totalProducts; // computed in provider
  final int createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  InvCategory copyWith({
    int? id,
    String? name,
    String? code,
    String? description,
    int? parentId,
    String? imagePath,
    String? status,
    int? totalProducts,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      InvCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        code: code ?? this.code,
        description: description ?? this.description,
        parentId: parentId ?? this.parentId,
        imagePath: imagePath ?? this.imagePath,
        status: status ?? this.status,
        totalProducts: totalProducts ?? this.totalProducts,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'InvCategory(id: $id, name: $name, code: $code)';
}
