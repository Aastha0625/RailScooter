import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import '../models/alert_rule.dart';
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

  static SupabaseClient get _sb => Supabase.instance.client;

  static Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String?> query = const {},
    Map<String, dynamic>? body,
  }) async {
    final session = _sb.auth.currentSession;
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



  static Future<List<AppUser>> fetchUsers({String? division, String? zone, String? role}) async {
    var query = _sb.from('app_users').select('*').eq('approval_status', 'approved');
    if (division != null) query = query.eq('division', division);
    if (zone != null) query = query.eq('zone', zone);
    if (role != null) query = query.eq('role', role);
    final data = await query.order('created_at', ascending: false);
    return (data as List).map((j) => AppUser.fromJson(Map<String, dynamic>.from(j))).toList();
  }

  static Future<List<AppUser>> fetchAllUsersAdmin() async {
    final data = await _sb
        .from('app_users')
        .select('*')
        .order('created_at', ascending: false);
    return (data as List).map((j) => AppUser.fromJson(Map<String, dynamic>.from(j))).toList();
  }

  /// Fetch users by approval status
  static Future<List<AppUser>> fetchUsersByApprovalStatus(String status) async {
    final data = await _sb
        .from('app_users')
        .select('*')
        .eq('approval_status', status)
        .order('created_at', ascending: false);
    return (data as List).map((j) => AppUser.fromJson(Map<String, dynamic>.from(j))).toList();
  }

  /// Approve or reject a pending user
  static Future<void> updateUserApproval(String userId, String status) async {
    final isApproved = status == 'approved';
    await _sb.from('app_users').update({
      'approval_status': status,
      'is_active': isApproved,
    }).eq('id', userId);
  }

  /// Update a user's profile details (admin)
  static Future<void> updateUserDetails(String userId, Map<String, dynamic> data) async {
    await _sb.from('app_users').update(data).eq('id', userId);
  }

  /// Suspend a user
  static Future<void> suspendUser(String userId) async {
    await _sb.from('app_users').update({'is_active': false}).eq('id', userId);
  }

  /// Reactivate a suspended user
  static Future<void> reactivateUser(String userId) async {
    await _sb.from('app_users').update({'is_active': true}).eq('id', userId);
  }

  /// Delete a user permanently (Admin only)
  static Future<void> deleteUser(String userId) async {
    // Calls a Supabase RPC to delete the user from auth.users (which cascades to app_users)
    await _sb.rpc('delete_user_by_admin', params: {'target_user_id': userId});
  }

  /// Fetch the current logged-in user's role
  static Future<String?> fetchCurrentUserRole() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return null;
    final data = await _sb
        .from('app_users')
        .select('role')
        .eq('id', uid)
        .maybeSingle();
    return data?['role'] as String?;
  }

  /// Fetch the current logged-in user's full data
  static Future<AppUser?> fetchCurrentUserData() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return null;
    final data = await _sb
        .from('app_users')
        .select('*')
        .eq('id', uid)
        .maybeSingle();
    if (data == null) return null;
    return AppUser.fromJson(data);
  }

  /// Fetch count of all users (admin)
  static Future<int> fetchUsersCount() async {
    return await _sb
        .from('app_users')
        .count(CountOption.exact);
  }

  /// Fetch count of users by approval status
  static Future<int> fetchPendingUsersCount() async {
    return await _sb
        .from('app_users')
        .count(CountOption.exact)
        .eq('approval_status', 'pending');
  }

  // -------- ASSIGNMENTS --------

  static Future<List<Map<String, dynamic>>> fetchAssignments() async {
    final data = await _sb
        .from('vehicle_assignments')
        .select('*');
    return (data as List).map((j) => Map<String, dynamic>.from(j)).toList();
  }

  static Future<void> createAssignment({
    required String vehicleId,
    String? assignedUserId,
    String? notes,
  }) async {
    if (assignedUserId != null) {
      await _sb.from('vehicle_assignments')
          .update({'is_active': false})
          .eq('assigned_user_id', assignedUserId)
          .eq('is_active', true);
    }
    
    await _sb.from('vehicle_assignments')
        .update({'is_active': false})
        .eq('vehicle_id', vehicleId)
        .eq('is_active', true);
        
    await _sb.from('vehicle_assignments').insert({
      'vehicle_id': vehicleId,
      'assigned_user_id': assignedUserId,
      'notes': notes ?? '',
      'is_active': true,
      'assigned_by': _sb.auth.currentUser?.id,
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
    // Check if it's a dummy alert first so we don't crash
    if (alertId.startsWith('dummy')) return;
    
    await _sb.from('vehicle_alerts')
        .update({'is_acknowledged': true})
        .eq('id', alertId);
  }

  static Future<void> simulateAlertEvent() async {
    // Pick a random vehicle
    final vehiclesData = await _sb.from('vehicles').select('id').limit(1);
    if (vehiclesData.isEmpty) throw Exception("No vehicles found");
    final vehicleId = vehiclesData.first['id'];

    await _sb.from('vehicle_alerts').insert({
      'vehicle_id': vehicleId,
      'alert_type': 'geofence',
      'severity': 'critical',
      'message': 'Simulated Alert: Manual DB Injection',
      'latitude': 28.6139,
      'longitude': 77.2090,
    });
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

  // -------- ACTIVITY LOG --------

  /// Fetch recent activity log entries
  static Future<List<Map<String, dynamic>>> fetchActivityLog({int limit = 50}) async {
    final data = await _sb
        .from('activity_log')
        .select('*')
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List).map((j) => Map<String, dynamic>.from(j)).toList();
  }

  /// Write an activity log entry (admin/manager only)
  static Future<void> logActivity({
    required String eventType,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    final uid = _sb.auth.currentUser?.id;
    final userData = uid != null
        ? await _sb.from('app_users').select('full_name').eq('id', uid).maybeSingle()
        : null;
    await _sb.from('activity_log').insert({
      'actor_id': uid,
      'actor_name': userData?['full_name'] ?? 'Admin',
      'event_type': eventType,
      'description': description,
      if (metadata != null) 'metadata': metadata,
    });
  }

  /// Subscribe to the activity_log for real-time updates.
  /// Returns the channel. Caller must call .unsubscribe() on dispose.
  static RealtimeChannel subscribeToActivityLog(
    void Function(Map<String, dynamic> payload) onInsert,
  ) {
    return _sb
        .channel('activity_log_inserts')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'activity_log',
          callback: (payload) => onInsert(payload.newRecord),
        )
        .subscribe();
  }

  /// Subscribe to alert_events for real-time updates.
  static RealtimeChannel subscribeToAlertEvents(
    void Function(Map<String, dynamic> payload) onInsert,
  ) {
    return _sb
        .channel('alert_events_inserts_admin')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'alert_events',
          callback: (payload) => onInsert(payload.newRecord),
        )
        .subscribe();
  }

  /// Subscribe to alert_rules for real-time updates.
  static RealtimeChannel subscribeToAlertRules(
    void Function(Map<String, dynamic> payload) onUpdate,
  ) {
    return _sb
        .channel('alert_rules_updates_admin')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'alert_rules',
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
  }

  // -------- BROADCAST MESSAGES --------

  static Future<List<Map<String, dynamic>>> fetchBroadcasts() async {
    final data = await _sb
        .from('broadcast_messages')
        .select('*, app_users(full_name)')
        .order('created_at', ascending: false)
        .limit(50);
    return (data as List).map((j) => Map<String, dynamic>.from(j)).toList();
  }

  /// Fetch total count of broadcasts
  static Future<int> fetchBroadcastsCount() async {
    return await _sb
        .from('broadcast_messages')
        .count(CountOption.exact);
  }

  static Future<void> sendBroadcast({
    required String title,
    required String body,
    required String targetRole,
    String? taskId,
  }) async {
    final uid = _sb.auth.currentUser?.id;
    await _sb.from('broadcast_messages').insert({
      'title': title,
      'body': body,
      'target_role': targetRole,
      'sent_by': uid,
      if (taskId != null) 'task_id': taskId,
    });
  }

  static Future<Map<String, dynamic>?> fetchTaskById(String taskId) async {
    final data = await _sb.from('trackman_tasks').select('*, app_users!trackman_tasks_assigned_to_fkey(full_name), vehicles(vehicle_id, variant)').eq('id', taskId).maybeSingle();
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  // -------- TRACKMAN TASKS --------

  static Future<List<Map<String, dynamic>>> fetchTasks({
    String? assignedToUserId,
    String? assignedByUserId,
    List<String>? regions,
    String? division,
    String? zone,
  }) async {
    var query = _sb.from('trackman_tasks').select('*, app_users!trackman_tasks_assigned_to_fkey(full_name), vehicles(vehicle_id, variant)');
    if (assignedToUserId != null) {
      query = query.eq('assigned_to', assignedToUserId);
    }
    if (assignedByUserId != null) {
      query = query.eq('assigned_by', assignedByUserId);
    }
    if (regions != null && regions.isNotEmpty) {
      query = query.inFilter('region', regions);
    }
    if (division != null) {
      query = query.eq('division', division);
    }
    if (zone != null) {
      query = query.eq('zone', zone);
    }
    final data = await query.order('created_at', ascending: false);
    return (data as List).map((j) => Map<String, dynamic>.from(j)).toList();
  }

  static Future<Map<String, dynamic>> createTask(Map<String, dynamic> data) async {
    final response = await _sb.from('trackman_tasks').insert(data).select().single();
    return Map<String, dynamic>.from(response);
  }

  static Future<int> fetchCompletedTasksCount() async {
    try {
      final response = await _sb
          .from('trackman_tasks')
          .select('id')
          .eq('status', 'Completed');
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  static Future<void> updateTaskStatus(String taskId, String status) async {
    await _sb.from('trackman_tasks').update({'status': status}).eq('id', taskId);
  }

  static Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    await _sb.from('trackman_tasks').update(data).eq('id', taskId);
  }

  static Future<String> uploadTaskPhoto(String taskId, Uint8List imageBytes, String extension) async {
    final fileName = 'task_${taskId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    await _sb.storage.from('task_proofs').uploadBinary(
      fileName, 
      imageBytes,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
    );
    return _sb.storage.from('task_proofs').getPublicUrl(fileName);
  }
}
