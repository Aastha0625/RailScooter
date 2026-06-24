import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  static String get backendHttpUrl {
    const configured = String.fromEnvironment('BACKEND_HTTP_URL');
    if (configured.isNotEmpty) return configured;
    if (kIsWeb) return 'http://localhost:3000';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000'
        : 'http://localhost:3000';
  }

  static String get backendWsUrl {
    const configured = String.fromEnvironment('BACKEND_WS_URL');
    if (configured.isNotEmpty) return configured;
    return '${backendHttpUrl.replaceFirst('http', 'ws')}/ws';
  }

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

  // ── Geographical Data ──────────────────────────────────────────────────────
  static const List<String> zones = [
    'North Western Railway',
    'Northern Railway',
    'Central Railway',
    'Western Railway'
  ];

  static const Map<String, List<String>> zoneDivisions = {
    'North Western Railway': ['Bikaner', 'Jaipur', 'Jodhpur', 'Ajmer'],
    'Northern Railway': ['Delhi', 'Ambala', 'Firozpur', 'Lucknow', 'Moradabad'],
    'Central Railway': ['Mumbai', 'Bhusawal', 'Pune', 'Solapur', 'Nagpur'],
    'Western Railway': ['Mumbai Central', 'Vadodara', 'Ahmedabad', 'Ratlam', 'Rajkot', 'Bhavnagar'],
  };

  static const Map<String, List<String>> divisionRegions = {
    'Bikaner': ['Bikaner City', 'Suratgarh', 'Hanumangarh', 'Churu', 'Rewari'],
    'Jaipur': ['Jaipur City', 'Phulera', 'Bandikui', 'Sikar', 'Alwar'],
    'Jodhpur': ['Jodhpur City', 'Pali Marwar', 'Marwar Junction', 'Barmer', 'Jaisalmer'],
    'Ajmer': ['Ajmer City', 'Bhilwara', 'Udaipur', 'Abu Road', 'Marwar'],
    'Delhi': ['New Delhi', 'Old Delhi', 'Hazrat Nizamuddin', 'Anand Vihar', 'Rohtak'],
    'Ambala': ['Ambala Cantt', 'Chandigarh', 'Kalka', 'Saharanpur', 'Bathinda'],
    'Firozpur': ['Firozpur Cantt', 'Ludhiana', 'Jalandhar', 'Amritsar', 'Jammu Tawi'],
    'Lucknow': ['Lucknow Charbagh', 'Kanpur', 'Varanasi', 'Ayodhya', 'Bareilly'],
    'Moradabad': ['Moradabad City', 'Haridwar', 'Dehradun', 'Roorkee', 'Shahjahanpur'],
    'Mumbai': ['CSMT', 'Dadar', 'Kurla', 'Kalyan', 'Thane'],
    'Bhusawal': ['Bhusawal City', 'Jalgaon', 'Nasik Road', 'Manmad', 'Khandwa'],
    'Pune': ['Pune City', 'Shivajinagar', 'Miraj', 'Kolhapur', 'Daund'],
    'Solapur': ['Solapur City', 'Gulbarga', 'Wadi', 'Daund', 'Kurduvadi'],
    'Nagpur': ['Nagpur City', 'Wardha', 'Ballarshah', 'Amla', 'Betul'],
    'Mumbai Central': ['Mumbai Central', 'Bandra Terminus', 'Borivali', 'Surat', 'Valsad'],
    'Vadodara': ['Vadodara City', 'Anand', 'Nadiad', 'Godhra', 'Bharuch'],
    'Ahmedabad': ['Ahmedabad City', 'Maninagar', 'Sabarmati', 'Viramgam', 'Mehsana'],
    'Ratlam': ['Ratlam City', 'Ujjain', 'Indore', 'Dewas', 'Mhow'],
    'Rajkot': ['Rajkot City', 'Surendranagar', 'Jamnagar', 'Okha', 'Dwarka'],
    'Bhavnagar': ['Bhavnagar Terminus', 'Botad', 'Dhola', 'Porbandar', 'Veraval'],
  };
}
