import 'package:latlong2/latlong.dart';

/// Central place for all app-wide constants.
/// Update these when deploying to production.
class AppConstants {
  AppConstants._();

  // ── App identity ──────────────────────────────────────────────────────────
  static const String appName = 'RailScooter';
  static const String appSubtitle = 'Fleet Management System';

  // ── Backend URLs (update for production) ─────────────────────────────────
  /// WebSocket endpoint for real-time tracking updates.
  /// Use 10.0.2.2 for Android emulator (maps to host machine localhost).
  /// Use your server IP / domain when running on a physical device.
  static const String backendWsUrl = 'ws://10.0.2.2:3000/ws';
  static const String backendHttpUrl = 'http://10.0.2.2:3000';

  // ── Map defaults ──────────────────────────────────────────────────────────
  /// Default map center (New Delhi) used when no live vehicles are available.
  static const LatLng defaultMapCenter = LatLng(28.6139, 77.2090);
  static const double defaultMapZoom = 14.0;

  // ── Vehicle form options ──────────────────────────────────────────────────
  static const List<String> vehicleVariants = [
    'PiScoot',
    'PiScoot-Bolt',
    'PiScoot-Aegis',
  ];

  static const List<String> batteryTypes = ['LiFe', 'LiPo', 'NMC', 'LFP'];

  static const List<String> vehicleStatuses = [
    'active',
    'idle',
    'maintenance',
    'offline',
  ];

  // ── Alert rule options ────────────────────────────────────────────────────
  static const List<String> alertRuleTypes = [
    'speed',
    'battery',
    'geofence',
    'idle_time',
    'movement',
  ];

  static const List<String> alertSeverities = [
    'low',
    'medium',
    'high',
    'critical',
  ];

  static const List<String> conditionOperators = [
    'gt',
    'lt',
    'eq',
    'gte',
    'lte',
  ];

  // ── Geofence options ──────────────────────────────────────────────────────
  static const List<String> geofenceTypes = [
    'operational',
    'restricted',
    'depot',
  ];
}
