import "package:flutter/foundation.dart";

@immutable
class Driver {
  const Driver({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.licenseNumber,
    required this.status,
    required this.totalPayments,
    required this.joinedDate,
    required this.rating,
    required this.tripsCompleted,
    this.vehicleNumber,
    this.vehicleType,
    this.lastPayment,
    this.totalDebt = 0,
    this.unpaidDays = 0,
    this.dueDates = const <String>[],
  });

  factory Driver.fromJson(final Map<String, dynamic> json) {
    double parseDouble(final Object? v) {
      if (v == null) {
        return 0;
      }
      if (v is num) {
        return v.toDouble();
      }
      if (v is String) {
        return double.tryParse(v) ?? 0;
      }
      return 0;
    }

    int parseInt(final Object? v) {
      if (v == null) {
        return 0;
      }
      if (v is int) {
        return v;
      }
      if (v is num) {
        return v.toInt();
      }
      if (v is String) {
        return int.tryParse(v) ?? 0;
      }
      return 0;
    }

    return Driver(
      id: (json["id"] ?? "").toString(),
      name: (json["name"] ?? "").toString(),
      email: (json["email"] ?? "").toString(),
      phone: (json["phone"] ?? "").toString(),
      licenseNumber: (json["license_number"] ?? "").toString(),
      vehicleNumber: json["vehicle_number"]?.toString(),
      vehicleType: json["vehicle_type"]?.toString(),
      status: (json["status"] ?? "inactive").toString(),
      totalPayments: parseDouble(json["total_payments"]),
      lastPayment: json["last_payment"] != null &&
              json["last_payment"].toString().isNotEmpty
          ? DateTime.tryParse(json["last_payment"].toString())
          : null,
      joinedDate: json["joined_date"] != null &&
              json["joined_date"].toString().isNotEmpty
          ? DateTime.tryParse(json["joined_date"].toString()) ?? DateTime.now()
          : DateTime.now(),
      rating: parseDouble(json["rating"]),
      tripsCompleted: parseInt(json["trips_completed"]),
      totalDebt: parseDouble(json["total_debt"]),
      unpaidDays: parseInt(json["unpaid_days"]),
      dueDates: (json["due_dates"] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
    );
  }
  final String id;
  final String name;
  final String email;
  final String phone;
  final String licenseNumber;
  final String? vehicleNumber;
  final String? vehicleType;
  final String status;
  final double totalPayments;
  final DateTime? lastPayment;
  final DateTime joinedDate;
  final double rating;
  final int tripsCompleted;
  // Debt summary (optional; present on payments/debts lists)
  final double totalDebt;
  final int unpaidDays;
  final List<String> dueDates; // ordered oldest->newest when provided

  Map<String, dynamic> toJson() => <String, dynamic>{
        "id": id,
        "name": name,
        "email": email,
        "phone": phone,
        "license_number": licenseNumber,
        "vehicle_number": vehicleNumber,
        "vehicle_type": vehicleType,
        "status": status,
        "total_payments": totalPayments,
        "last_payment": lastPayment?.toIso8601String(),
        "joined_date": joinedDate.toIso8601String(),
        "rating": rating,
        "trips_completed": tripsCompleted,
        "total_debt": totalDebt,
        "unpaid_days": unpaidDays,
        "due_dates": dueDates,
      };

  Driver copyWith({
    final String? id,
    final String? name,
    final String? email,
    final String? phone,
    final String? licenseNumber,
    final String? vehicleNumber,
    final String? vehicleType,
    final String? status,
    final double? totalPayments,
    final DateTime? lastPayment,
    final DateTime? joinedDate,
    final double? rating,
    final int? tripsCompleted,
    final double? totalDebt,
    final int? unpaidDays,
    final List<String>? dueDates,
  }) =>
      Driver(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        licenseNumber: licenseNumber ?? this.licenseNumber,
        vehicleNumber: vehicleNumber ?? this.vehicleNumber,
        vehicleType: vehicleType ?? this.vehicleType,
        status: status ?? this.status,
        totalPayments: totalPayments ?? this.totalPayments,
        lastPayment: lastPayment ?? this.lastPayment,
        joinedDate: joinedDate ?? this.joinedDate,
        rating: rating ?? this.rating,
        tripsCompleted: tripsCompleted ?? this.tripsCompleted,
        totalDebt: totalDebt ?? this.totalDebt,
        unpaidDays: unpaidDays ?? this.unpaidDays,
        dueDates: dueDates ?? this.dueDates,
      );

  @override
  String toString() =>
      "Driver(id: $id, name: $name, email: $email, status: $status)";

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Driver && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
