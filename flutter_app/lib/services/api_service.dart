import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import '../models/alert_rule.dart';
import '../models/department.dart';
import '../models/geofence.dart';
import '../models/user.dart';
import '../models/vehicle.dart';
import '../models/vehicle_alert.dart';
import '../models/vehicle_location.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiService {
  static const Duration _timeout = Duration(seconds: 20);

  static Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String?> query = const {},
    Map<String, dynamic>? body,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      throw const ApiException(
          401, 'Your session has expired. Please sign in again.');
    }

    final queryParameters = <String, String>{
      for (final entry in query.entries)
        if (entry.value != null && entry.value!.isNotEmpty)
          entry.key: entry.value!,
    };
    final baseUrl = AppConstants.backendHttpUrl.endsWith('/')
        ? AppConstants.backendHttpUrl.substring(
            0,
            AppConstants.backendHttpUrl.length - 1,
          )
        : AppConstants.backendHttpUrl;
    final uri = Uri.parse(
      '$baseUrl/api$path',
    ).replace(
        queryParameters: queryParameters.isEmpty ? null : queryParameters);
    final headers = {
      'Authorization': 'Bearer ${session.accessToken}',
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
    };

    final http.Response response;
    if (method == 'GET') {
      response = await http.get(uri, headers: headers).timeout(_timeout);
    } else if (method == 'POST') {
      response = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(_timeout);
    } else if (method == 'PUT') {
      response = await http
          .put(uri, headers: headers, body: jsonEncode(body))
          .timeout(_timeout);
    } else if (method == 'DELETE') {
      response = await http.delete(uri, headers: headers).timeout(_timeout);
    } else {
      throw ArgumentError.value(method, 'method', 'Unsupported HTTP method');
    }

    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw ApiException(
          response.statusCode,
          'The server returned an invalid response.',
        );
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          decoded is Map<String, dynamic> ? decoded['error']?.toString() : null;
      throw ApiException(
        response.statusCode,
        message ?? 'Request failed with status ${response.statusCode}.',
      );
    }
    return decoded;
  }

  static Map<String, dynamic> _map(dynamic value) =>
      Map<String, dynamic>.from(value as Map);

  static List<dynamic> _list(dynamic value) => value as List<dynamic>;

  // -------- VEHICLES --------

  static Future<List<Vehicle>> fetchVehicles({
    String? status,
    String? search,
  }) async {
    final response = _map(await _request(
      'GET',
      '/vehicles',
      query: {
        'status': status,
        'search': search,
        'limit': '1000',
      },
    ));
    return _list(response['data'])
        .map((json) => Vehicle.fromJson(_map(json)))
        .toList();
  }

  static Future<Map<String, dynamic>> fetchVehicleDetail(String id) async {
    return _map(await _request('GET', '/vehicles/$id'));
  }

  static Future<Vehicle> createVehicle(Map<String, dynamic> data) async {
    return Vehicle.fromJson(
      _map(await _request('POST', '/vehicles', body: data)),
    );
  }

  static Future<Vehicle> updateVehicle(
    String id,
    Map<String, dynamic> data,
  ) async {
    return Vehicle.fromJson(
      _map(await _request('PUT', '/vehicles/$id', body: data)),
    );
  }

  static Future<void> deleteVehicle(String id) async {
    await _request('DELETE', '/vehicles/$id');
  }

  // -------- DEPARTMENTS --------

  static Future<List<Department>> fetchDepartments() async {
    return _list(await _request('GET', '/departments'))
        .map((json) => Department.fromJson(_map(json)))
        .toList();
  }

  static Future<Department> createDepartment(
    Map<String, dynamic> data,
  ) async {
    return Department.fromJson(
      _map(await _request('POST', '/departments', body: data)),
    );
  }

  static Future<Department> updateDepartment(
    String id,
    Map<String, dynamic> data,
  ) async {
    return Department.fromJson(
      _map(await _request('PUT', '/departments/$id', body: data)),
    );
  }

  static Future<void> deleteDepartment(String id) async {
    await _request('DELETE', '/departments/$id');
  }

  // -------- USERS --------

  static Future<List<AppUser>> fetchUsers() async {
    return _list(await _request('GET', '/users'))
        .map((json) => AppUser.fromJson(_map(json)))
        .toList();
  }

  // -------- ASSIGNMENTS --------

  static Future<List<Map<String, dynamic>>> fetchAssignments() async {
    return _list(await _request('GET', '/assignments')).map(_map).toList();
  }

  static Future<void> createAssignment({
    required String vehicleId,
    String? departmentId,
    String? assignedUserId,
    String? notes,
  }) async {
    await _request('POST', '/assignments', body: {
      'vehicle_id': vehicleId,
      'department_id': departmentId,
      'assigned_user_id': assignedUserId,
      'notes': notes ?? '',
    });
  }

  static Future<void> removeAssignment(String assignmentId) async {
    await _request('DELETE', '/assignments/$assignmentId');
  }

  // -------- ALERTS --------

  static Future<List<AlertRule>> fetchAlertRules() async {
    return _list(await _request('GET', '/alerts/rules'))
        .map((json) => AlertRule.fromJson(_map(json)))
        .toList();
  }

  static Future<AlertRule> createAlertRule(
    Map<String, dynamic> data,
  ) async {
    return AlertRule.fromJson(
      _map(await _request('POST', '/alerts/rules', body: data)),
    );
  }

  static Future<AlertRule> updateAlertRule(
    String id,
    Map<String, dynamic> data,
  ) async {
    return AlertRule.fromJson(
      _map(await _request('PUT', '/alerts/rules/$id', body: data)),
    );
  }

  static Future<void> deleteAlertRule(String id) async {
    await _request('DELETE', '/alerts/rules/$id');
  }

  static Future<List<VehicleAlert>> fetchAlertEvents({
    bool? unacknowledged,
  }) async {
    return _list(await _request(
      'GET',
      '/alerts/events',
      query: {
        if (unacknowledged == true) 'is_acknowledged': 'false',
      },
    ))
        .map((json) => VehicleAlert.fromJson(_map(json)))
        .toList();
  }

  static Future<void> acknowledgeAlert(String alertId) async {
    await _request('PUT', '/alerts/events/$alertId/acknowledge');
  }

  // -------- GEOFENCES --------

  static Future<List<Geofence>> fetchGeofences() async {
    return _list(await _request('GET', '/tracking/geofences/all'))
        .map((json) => Geofence.fromJson(_map(json)))
        .toList();
  }

  static Future<Geofence> createGeofence(
    Map<String, dynamic> data,
  ) async {
    return Geofence.fromJson(
      _map(await _request('POST', '/tracking/geofences', body: data)),
    );
  }

  static Future<void> deleteGeofence(String id) async {
    await _request('DELETE', '/tracking/geofences/$id');
  }

  // -------- TRACKING --------

  static Future<List<VehicleLocation>> fetchLiveTracking() async {
    return _list(await _request('GET', '/tracking/live'))
        .map((json) => VehicleLocation.fromJson(_map(json)))
        .toList();
  }

  // -------- DASHBOARD STATS --------

  static Future<Map<String, int>> fetchDashboardStats() async {
    final response = _map(await _request('GET', '/stats'));
    return response.map(
      (key, value) => MapEntry(key, (value as num).toInt()),
    );
  }
}
