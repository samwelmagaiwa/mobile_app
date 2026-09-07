import 'package:flutter/foundation.dart';

// MySQL DECIMAL columns come back through PDO as strings (e.g. "15000.00"),
// so `as num?` throws instead of falling through to `??` — the cast itself
// fails before the fallback ever runs. Check the runtime type instead.
int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

/// A received lot of one product, with its own expiry date and buying cost.
/// Stock is issued first-expiring-first, so [expiryDate] drives allocation.
@immutable
class InvBatch {
  const InvBatch({
    required this.id,
    required this.productId,
    required this.batchNumber,
    required this.quantity,
    required this.costPrice,
    this.expiryDate,
    this.receivedAt,
    this.status = 'active',
    this.reference = '',
    this.productName = '',
    this.productSku = '',
    this.productUnit = '',
  });

  factory InvBatch.fromJson(Map<String, dynamic> json) => InvBatch(
        id: _toInt(json['id']),
        productId: _toInt(json['product_id']),
        batchNumber: (json['batch_number'] ?? '').toString(),
        quantity: _toInt(json['quantity']),
        costPrice: _toDouble(json['cost_price']),
        expiryDate: DateTime.tryParse('${json['expiry_date']}'),
        receivedAt: DateTime.tryParse('${json['received_at']}'),
        status: (json['status'] ?? 'active').toString(),
        reference: (json['reference'] ?? '').toString(),
        productName: (json['product_name'] ?? '').toString(),
        productSku: (json['product_sku'] ?? '').toString(),
        productUnit: (json['product_unit'] ?? '').toString(),
      );

  final int id;
  final int productId;
  final String batchNumber;
  final int quantity;
  final double costPrice;
  final DateTime? expiryDate;
  final DateTime? receivedAt;
  final String status;
  final String reference;
  final String productName;
  final String productSku;
  final String productUnit;

  double get stockValue => quantity * costPrice;

  /// Days until expiry; negative once expired, null when the batch has no date.
  int? get daysToExpiry {
    final DateTime? expiry = expiryDate;
    if (expiry == null) {
      return null;
    }
    final DateTime today = DateTime.now();
    return DateTime(expiry.year, expiry.month, expiry.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
  }

  bool get isExpired => (daysToExpiry ?? 1) < 0;

  bool expiresWithin(int days) {
    final int? d = daysToExpiry;
    return d != null && d >= 0 && d <= days;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvBatch && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// A damage / breakage / expiry write-off awaiting or carrying a decision.
@immutable
class InvWriteOff {
  const InvWriteOff({
    required this.id,
    required this.reference,
    required this.productId,
    required this.reason,
    required this.quantity,
    required this.costValue,
    required this.status,
    required this.createdAt,
    this.batchId,
    this.batchNumber = '',
    this.note = '',
    this.productName = '',
    this.requestedByName = '',
    this.approvedByName = '',
    this.decisionNote = '',
  });

  factory InvWriteOff.fromJson(Map<String, dynamic> json) => InvWriteOff(
        id: _toInt(json['id']),
        reference: (json['reference'] ?? '').toString(),
        productId: _toInt(json['product_id']),
        batchId: json['batch_id'] == null ? null : _toInt(json['batch_id']),
        batchNumber: (json['batch_number'] ?? '').toString(),
        reason: (json['reason'] ?? 'other').toString(),
        quantity: _toInt(json['quantity']),
        costValue: _toDouble(json['cost_value']),
        status: (json['status'] ?? 'pending').toString(),
        note: (json['note'] ?? '').toString(),
        productName: (json['product_name'] ?? '').toString(),
        requestedByName: (json['requested_by_name'] ?? '').toString(),
        approvedByName: (json['approved_by_name'] ?? '').toString(),
        decisionNote: (json['decision_note'] ?? '').toString(),
        createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
      );

  final int id;
  final String reference;
  final int productId;
  final int? batchId;
  final String batchNumber;
  final String reason;
  final int quantity;
  final double costValue;
  final String status;
  final String note;
  final String productName;
  final String requestedByName;
  final String approvedByName;
  final String decisionNote;
  final DateTime createdAt;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
}

/// A physical stock count. Nothing moves until it is posted.
@immutable
class InvStockCount {
  const InvStockCount({
    required this.id,
    required this.reference,
    required this.status,
    required this.createdAt,
    this.note = '',
    this.countedByName = '',
    this.linesCount = 0,
    this.totalVariance = 0,
    this.lines = const <InvStockCountLine>[],
  });

  factory InvStockCount.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawLines =
        (json['lines'] is List) ? json['lines'] as List<dynamic> : const [];

    return InvStockCount(
      id: _toInt(json['id']),
      reference: (json['reference'] ?? '').toString(),
      status: (json['status'] ?? 'draft').toString(),
      note: (json['note'] ?? '').toString(),
      countedByName: (json['counted_by_name'] ?? '').toString(),
      linesCount:
          json['lines_count'] == null ? rawLines.length : _toInt(json['lines_count']),
      totalVariance: _toInt(json['total_variance']),
      createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
      lines: rawLines
          .map((l) => InvStockCountLine.fromJson(l as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final int id;
  final String reference;
  final String status;
  final String note;
  final String countedByName;
  final int linesCount;
  final int totalVariance;
  final DateTime createdAt;
  final List<InvStockCountLine> lines;

  bool get isDraft => status == 'draft';
}

@immutable
class InvStockCountLine {
  const InvStockCountLine({
    required this.id,
    required this.productId,
    required this.systemQuantity,
    required this.countedQuantity,
    required this.variance,
    this.batchId,
    this.batchNumber = '',
    this.productName = '',
    this.productSku = '',
    this.note = '',
  });

  factory InvStockCountLine.fromJson(Map<String, dynamic> json) =>
      InvStockCountLine(
        id: _toInt(json['id']),
        productId: _toInt(json['product_id']),
        batchId: json['batch_id'] == null ? null : _toInt(json['batch_id']),
        batchNumber: (json['batch_number'] ?? '').toString(),
        productName: (json['product_name'] ?? '').toString(),
        productSku: (json['product_sku'] ?? '').toString(),
        systemQuantity: _toInt(json['system_quantity']),
        countedQuantity: _toInt(json['counted_quantity']),
        variance: _toInt(json['variance']),
        note: (json['note'] ?? '').toString(),
      );

  final int id;
  final int productId;
  final int? batchId;
  final String batchNumber;
  final String productName;
  final String productSku;
  final int systemQuantity;
  final int countedQuantity;
  final int variance;
  final String note;

  bool get matches => variance == 0;
}
