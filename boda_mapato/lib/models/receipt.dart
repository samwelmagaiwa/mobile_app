import 'package:flutter/foundation.dart';

@immutable
class Receipt {
  const Receipt({
    required this.id,
    required this.receiptNumber,
    required this.paymentId,
    required this.driverId,
    required this.driverName,
    required this.amount,
    required this.paymentChannel,
    required this.generatedAt,
    this.vehicleNumber,
    this.remarks,
    this.paidDates = const <String>[],
    this.status = 'generated',
    this.sentAt,
    this.sentTo,
    this.companyName = 'Boda Mapato',
    this.companyPhone,
    this.companyEmail,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    double parseDouble(Object? v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    DateTime parseDateTime(Object? v) {
      if (v == null) return DateTime.now();
      if (v is String && v.isNotEmpty) {
        return DateTime.tryParse(v) ?? DateTime.now();
      }
      return DateTime.now();
    }

    List<String> parseStringList(Object? v) {
      if (v == null) return <String>[];
      if (v is List) return v.map((e) => e.toString()).toList();
      if (v is String) return v.split(',').where((s) => s.trim().isNotEmpty).toList();
      return <String>[];
    }

    // Handle both regular receipts and pending receipts (payment) data
    final bool isPendingPayment = json.containsKey('reference_number') && 
                                  !json.containsKey('receipt_number');
    
    if (isPendingPayment) {
      // This is pending receipt data (payment-based)
      final driver = json['driver'] as Map<String, dynamic>? ?? {};
      return Receipt(
        id: (json['payment_id'] ?? '').toString(),
        receiptNumber: json['reference_number']?.toString() ?? 'PENDING',
        paymentId: (json['payment_id'] ?? '').toString(),
        driverId: driver['id']?.toString() ?? '',
        driverName: driver['name']?.toString() ?? '',
        amount: parseDouble(json['amount']),
        paymentChannel: (json['payment_channel'] ?? json['formatted_payment_channel'] ?? 'cash').toString(),
        generatedAt: parseDateTime(json['payment_date'] ?? json['formatted_date']),
        vehicleNumber: driver['vehicle_number']?.toString(),
        remarks: json['remarks']?.toString(),
        paidDates: parseStringList(json['covered_days'] ?? json['covers_days']),
        status: 'pending', // Status for pending receipts
        sentAt: null,
        sentTo: null,
        companyName: 'Boda Mapato',
        companyPhone: null,
        companyEmail: null,
      );
    } else {
      // This is regular receipt data
      return Receipt(
        id: (json['id'] ?? '').toString(),
        receiptNumber: (json['receipt_number'] ?? json['number'] ?? '').toString(),
        paymentId: (json['payment_id'] ?? '').toString(),
        driverId: (json['driver_id'] ?? '').toString(),
        driverName: (json['driver_name'] ?? json['driver']?['name'] ?? '').toString(),
        amount: parseDouble(json['amount'] ?? json['total_amount']),
        paymentChannel: (json['payment_channel'] ?? json['method'] ?? 'cash').toString(),
        generatedAt: parseDateTime(json['generated_at'] ?? json['created_at']),
        vehicleNumber: json['vehicle_number']?.toString(),
        remarks: json['remarks']?.toString(),
        paidDates: parseStringList(json['paid_dates'] ?? json['covers_days']),
        status: (json['status'] ?? 'generated').toString(),
        sentAt: json['sent_at'] != null ? parseDateTime(json['sent_at']) : null,
        sentTo: json['sent_to']?.toString(),
        companyName: (json['company_name'] ?? 'Boda Mapato').toString(),
        companyPhone: json['company_phone']?.toString(),
        companyEmail: json['company_email']?.toString(),
      );
    }
  }

  final String id;
  final String receiptNumber;
  final String paymentId;
  final String driverId;
  final String driverName;
  final double amount;
  final String paymentChannel;
  final DateTime generatedAt;
  final String? vehicleNumber;
  final String? remarks;
  final List<String> paidDates;
  final String status; // generated, sent, cancelled
  final DateTime? sentAt;
  final String? sentTo;
  final String companyName;
  final String? companyPhone;
  final String? companyEmail;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'receipt_number': receiptNumber,
        'payment_id': paymentId,
        'driver_id': driverId,
        'driver_name': driverName,
        'amount': amount,
        'payment_channel': paymentChannel,
        'generated_at': generatedAt.toIso8601String(),
        'vehicle_number': vehicleNumber,
        'remarks': remarks,
        'paid_dates': paidDates,
        'status': status,
        'sent_at': sentAt?.toIso8601String(),
        'sent_to': sentTo,
        'company_name': companyName,
        'company_phone': companyPhone,
        'company_email': companyEmail,
      };

  Receipt copyWith({
    String? id,
    String? receiptNumber,
    String? paymentId,
    String? driverId,
    String? driverName,
    double? amount,
    String? paymentChannel,
    DateTime? generatedAt,
    String? vehicleNumber,
    String? remarks,
    List<String>? paidDates,
    String? status,
    DateTime? sentAt,
    String? sentTo,
    String? companyName,
    String? companyPhone,
    String? companyEmail,
  }) =>
      Receipt(
        id: id ?? this.id,
        receiptNumber: receiptNumber ?? this.receiptNumber,
        paymentId: paymentId ?? this.paymentId,
        driverId: driverId ?? this.driverId,
        driverName: driverName ?? this.driverName,
        amount: amount ?? this.amount,
        paymentChannel: paymentChannel ?? this.paymentChannel,
        generatedAt: generatedAt ?? this.generatedAt,
        vehicleNumber: vehicleNumber ?? this.vehicleNumber,
        remarks: remarks ?? this.remarks,
        paidDates: paidDates ?? this.paidDates,
        status: status ?? this.status,
        sentAt: sentAt ?? this.sentAt,
        sentTo: sentTo ?? this.sentTo,
        companyName: companyName ?? this.companyName,
        companyPhone: companyPhone ?? this.companyPhone,
        companyEmail: companyEmail ?? this.companyEmail,
      );

  String get paymentChannelDisplayName {
    switch (paymentChannel.toLowerCase()) {
      case 'cash':
        return 'Fedha taslimu';
      case 'mobile':
        return 'Pesa za simu';
      case 'bank':
        return 'Uhamisho wa benki';
      case 'other':
        return 'Njia nyingine';
      default:
        return paymentChannel;
    }
  }

  String get statusDisplayName {
    switch (status.toLowerCase()) {
      case 'generated':
        return 'Imetengenezwa';
      case 'sent':
        return 'Imetumwa';
      case 'cancelled':
        return 'Imeghairiwa';
      case 'pending':
        return 'Inazosubiri';
      default:
        return status;
    }
  }

  bool get isSent => status.toLowerCase() == 'sent';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isGenerated => status.toLowerCase() == 'generated';
  bool get isPending => status.toLowerCase() == 'pending';

  @override
  String toString() =>
      'Receipt(id: $id, receiptNumber: $receiptNumber, driverName: $driverName, amount: $amount)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Receipt && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}