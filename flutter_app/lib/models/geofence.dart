class Geofence {
  final String id;
  final String name;
  final String description;
  final String fenceType;
  final double centerLat;
  final double centerLng;
  final double radiusMeters;
  final bool isActive;
  final bool alertOnEnter;
  final bool alertOnExit;
  final String colorHex;
  final String? departmentId;
  final String? departmentName;
  final DateTime createdAt;

  const Geofence({
    required this.id,
    required this.name,
    required this.description,
    required this.fenceType,
    required this.centerLat,
    required this.centerLng,
    required this.radiusMeters,
    required this.isActive,
    required this.alertOnEnter,
    required this.alertOnExit,
    required this.colorHex,
    this.departmentId,
    this.departmentName,
    required this.createdAt,
  });

  factory Geofence.fromJson(Map<String, dynamic> json) => Geofence(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    fenceType: json['fence_type'] ?? 'operational',
    centerLat: (json['center_lat'] ?? 0).toDouble(),
    centerLng: (json['center_lng'] ?? 0).toDouble(),
    radiusMeters: (json['radius_meters'] ?? 500).toDouble(),
    isActive: json['is_active'] ?? true,
    alertOnEnter: json['alert_on_enter'] ?? false,
    alertOnExit: json['alert_on_exit'] ?? true,
    colorHex: json['color_hex'] ?? '#F58220',
    departmentId: json['department_id'],
    departmentName: json['departments']?['name'],
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'fence_type': fenceType,
    'center_lat': centerLat,
    'center_lng': centerLng,
    'radius_meters': radiusMeters,
    'is_active': isActive,
    'alert_on_enter': alertOnEnter,
    'alert_on_exit': alertOnExit,
    'color_hex': colorHex,
    'department_id': departmentId,
  };
}

// VehicleLocation has been moved to models/vehicle_location.dart
