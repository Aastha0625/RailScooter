/// VehicleLocation represents a real-time GPS position from vehicle_tracking table.
class VehicleLocation {
  final String vehicleId;
  final String vehicleLabel;
  final double latitude;
  final double longitude;
  final double speedKmh;
  final int batteryPercent;
  final bool isOnline;
  final DateTime recordedAt;

  const VehicleLocation({
    required this.vehicleId,
    required this.vehicleLabel,
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
    required this.batteryPercent,
    required this.isOnline,
    required this.recordedAt,
  });

  factory VehicleLocation.fromJson(Map<String, dynamic> json) => VehicleLocation(
    vehicleId: json['vehicle_id'] ?? '',
    vehicleLabel: json['vehicles']?['vehicle_id'] ?? 'Unknown',
    latitude: (json['latitude'] ?? 0).toDouble(),
    longitude: (json['longitude'] ?? 0).toDouble(),
    speedKmh: (json['speed_kmh'] ?? 0).toDouble(),
    batteryPercent: json['battery_percent'] ?? 100,
    isOnline: json['is_online'] ?? false,
    recordedAt: DateTime.tryParse(json['recorded_at'] ?? '') ?? DateTime.now(),
  );
}
