/// VehicleAlert represents a triggered alert event stored in vehicle_alerts table.
class VehicleAlert {
  final String id;
  final String vehicleId;
  final String vehicleLabel;
  final String alertType;
  final String severity;
  final String message;
  final double? latitude;
  final double? longitude;
  final bool isAcknowledged;
  final DateTime createdAt;

  const VehicleAlert({
    required this.id,
    required this.vehicleId,
    required this.vehicleLabel,
    required this.alertType,
    required this.severity,
    required this.message,
    this.latitude,
    this.longitude,
    required this.isAcknowledged,
    required this.createdAt,
  });

  factory VehicleAlert.fromJson(Map<String, dynamic> json) => VehicleAlert(
    id: json['id'] ?? '',
    vehicleId: json['vehicle_id'] ?? '',
    vehicleLabel: json['vehicles']?['vehicle_id'] ?? 'Unknown',
    alertType: json['alert_type'] ?? 'speed',
    severity: json['severity'] ?? 'medium',
    message: json['message'] ?? '',
    latitude: json['latitude']?.toDouble(),
    longitude: json['longitude']?.toDouble(),
    isAcknowledged: json['is_acknowledged'] ?? false,
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  );
}
