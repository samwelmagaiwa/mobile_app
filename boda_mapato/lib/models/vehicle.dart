class Vehicle {

  Vehicle({
    required this.id,
    required this.name,
    required this.type,
    required this.plateNumber,
    required this.isActive, required this.createdAt, required this.updatedAt, this.description,
    this.driverId,
    this.driverName,
    this.driverEmail,
    this.driverPhone,
  });

  factory Vehicle.fromJson(final Map<String, dynamic> json) => Vehicle(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      plateNumber: json['plate_number'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      driverId: json['driver']?['id'] as String?,
      driverName: json['driver']?['name'] as String?,
      driverEmail: json['driver']?['email'] as String?,
      driverPhone: json['driver']?['phone'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  final String id;
  final String name;
  final String type;
  final String plateNumber;
  final String? description;
  final bool isActive;
  final String? driverId;
  final String? driverName;
  final String? driverEmail;
  final String? driverPhone;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
      "id": id,
      "name": name,
      "type": type,
      "plate_number": plateNumber,
      "description": description,
      "is_active": isActive,
      "driver_id": driverId,
      "driver_name": driverName,
      "driver_email": driverEmail,
      "driver_phone": driverPhone,
      "created_at": createdAt.toIso8601String(),
      "updated_at": updatedAt.toIso8601String(),
    };

  Vehicle copyWith({
    final String? id,
    final String? name,
    final String? type,
    final String? plateNumber,
    final String? description,
    final bool? isActive,
    final String? driverId,
    final String? driverName,
    final String? driverEmail,
    final String? driverPhone,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) => Vehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      plateNumber: plateNumber ?? this.plateNumber,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverEmail: driverEmail ?? this.driverEmail,
      driverPhone: driverPhone ?? this.driverPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );

  @override
  String toString() => "Vehicle(id: $id, name: $name, type: $type, plateNumber: $plateNumber, isActive: $isActive, driverName: $driverName)";

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;
    return other is Vehicle && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}