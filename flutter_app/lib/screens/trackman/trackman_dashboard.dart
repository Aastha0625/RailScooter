import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import 'trackman_history_screen.dart';
import 'trackman_safety_screen.dart';
import 'trackman_geofencing_screen.dart';
import 'trackman_report_issue_screen.dart';
import 'trackman_task_details_screen.dart';
import 'trackman_tasks_screen.dart';
import 'trackman_notifications_screen.dart';
import 'trackman_base_screen.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';

class TrackmanDashboardScreen extends StatefulWidget {
  const TrackmanDashboardScreen({super.key});

  @override
  State<TrackmanDashboardScreen> createState() => _TrackmanDashboardScreenState();
}

class _TrackmanDashboardScreenState extends State<TrackmanDashboardScreen> {
  bool _isUnlocked = false;
  bool _loading = true;
  bool hasNotifications = false;
  Map<String, dynamic>? _activeAssignment;
  AppUser? _trackmanUser;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _checkNotifications();
    _fetchActiveVehicle();
  }

  Future<void> _fetchUserData() async {
    final user = await ApiService.fetchCurrentUserData();
    if (mounted) {
      setState(() => _trackmanUser = user);
    }
  }

  Future<void> _fetchActiveVehicle() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
          .from('vehicle_assignments')
          .select('''
            id,
            is_active,
            vehicles (
              id,
              vehicle_id
            )
          ''')
          .eq('assigned_user_id', user.id)
          .eq('is_active', true)
          .maybeSingle();

      Map<String, dynamic>? assignmentData;
      if (data != null) {
        assignmentData = Map<String, dynamic>.from(data);
        final vehicleMap = assignmentData['vehicles'];
        if (vehicleMap != null && vehicleMap['id'] != null) {
          final trackingData = await Supabase.instance.client
              .from('vehicle_tracking')
              .select('speed_kmh, battery_percent')
              .eq('vehicle_id', vehicleMap['id'])
              .order('recorded_at', ascending: false)
              .limit(1)
              .maybeSingle();

          final updatedVehicleMap = Map<String, dynamic>.from(vehicleMap);
          if (trackingData != null) {
            updatedVehicleMap['current_speed'] = trackingData['speed_kmh'];
            updatedVehicleMap['battery_level'] = trackingData['battery_percent'];
            final double battery = (trackingData['battery_percent'] ?? 100).toDouble();
            updatedVehicleMap['estimated_range'] = (battery * 0.45).toStringAsFixed(1);
          } else {
            updatedVehicleMap['current_speed'] = 0;
            updatedVehicleMap['battery_level'] = 100;
            updatedVehicleMap['estimated_range'] = '45.0';
          }
          assignmentData['vehicles'] = updatedVehicleMap;
        }
      }

      bool savedUnlockedState = false;
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        savedUnlockedState = prefs.getBool('run_active_${user.id}') ?? false;
      }

      if (mounted) {
        setState(() {
          _activeAssignment = assignmentData;
          _isUnlocked = savedUnlockedState;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching active vehicle: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkNotifications() async {
    try {
      final client = Supabase.instance.client;
      final prefs = await SharedPreferences.getInstance();
      final lastReadStr = prefs.getString('last_notification_read_time');
      DateTime lastRead;
      if (lastReadStr != null) {
        lastRead = DateTime.parse(lastReadStr);
      } else {
        lastRead = DateTime.now();
        await prefs.setString('last_notification_read_time', lastRead.toIso8601String());
      }

      final broadcastsResponse = await client
          .from('broadcast_messages')
          .select('id, created_at')
          .or('target_role.eq.trackman,target_role.eq.all');

      final alertsResponse = await client
          .from('vehicle_alerts')
          .select('id, created_at')
          .eq('is_acknowledged', false);

      final hasUnreadBroadcasts = broadcastsResponse
          .any((b) => DateTime.parse(b['created_at']).isAfter(lastRead));
      final hasUnreadAlerts = alertsResponse
          .any((a) => DateTime.parse(a['created_at']).isAfter(lastRead));

      if (!mounted) return;
      setState(() => hasNotifications = hasUnreadBroadcasts || hasUnreadAlerts);
    } catch (e) {
      debugPrint('Notification error: $e');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return TrackmanBaseScreen(
      title: 'Trackman Dashboard',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _buildActiveVehicleHero(),
            const SizedBox(height: 16),
            _buildAnalyticsTitle('Quick Actions'),
            _buildQuickActionCards(context),
            const SizedBox(height: 16),
            _buildSafetyAndLocationCard(),
            const SizedBox(height: 16),
            _buildEmergencyActions(),
            const SizedBox(height: 24),
            _buildAnalyticsTitle('My Recent Tasks'),
            _buildRecentTasks(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
    );
  }

  // ── Hero header (slimmer version) ─────────────────────────────────────────

  Widget _buildActiveVehicleHero() {
    if (_loading) {
      return Container(
        width: double.infinity,
        height: 160,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20)),
        ),
        child:
            const Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    final hasAssignment = _activeAssignment != null;
    final vehicle = hasAssignment ? _activeAssignment!['vehicles'] : null;
    final vehicleLabel =
        vehicle != null ? vehicle['vehicle_id'] : 'No Vehicle Assigned';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      // ↓ reduced from (24,0,24,20) → tighter vertical padding
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ↓ smaller circle: 48→40, icon 24→20
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _isUnlocked ? Colors.green : AppColors.statusIdle,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: (_isUnlocked ? Colors.green : AppColors.statusIdle)
                            .withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3)),
                  ],
                ),
                child: Icon(
                    _isUnlocked ? Icons.lock_open : Icons.lock,
                    color: Colors.white,
                    size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ↓ font 20→17
                  Text(vehicleLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                  Text(
                    hasAssignment
                        ? (_isUnlocked ? 'Active Run' : 'Locked')
                        : 'Awaiting Assignment',
                    style: TextStyle(
                        color: hasAssignment
                            ? (_isUnlocked ? Colors.greenAccent : Colors.white70)
                            : Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const Spacer(),
              if (hasAssignment)
                Switch(
                  value: _isUnlocked,
                  activeThumbColor: Colors.greenAccent,
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    final uid = Supabase.instance.client.auth.currentUser?.id;
                    if (val) {
                      final isChecked =
                          prefs.getBool('safety_checked_$uid') ?? false;
                      if (!isChecked) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Please complete the Safety Guidelines checklist first.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                        return;
                      }
                    }
                    if (uid != null) {
                      await prefs.setBool('run_active_$uid', val);
                    }
                    setState(() => _isUnlocked = val);
                  },
                ),
            ],
          ),
          // ↓ gap 24→12
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTelemetryItem(Icons.speed,
                  _isUnlocked ? '${vehicle?['current_speed'] ?? 25} km/h' : '0 km/h',
                  'Speed'),
              _buildTelemetryItem(Icons.battery_charging_full,
                  '${vehicle?['battery_level'] ?? 100}%', 'Battery'),
              _buildTelemetryItem(Icons.timeline,
                  '${vehicle?['estimated_range'] ?? 45} km', 'Est. Range'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        // ↓ icon 24→20, gap 8→5, font 16→14
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 5),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  // ── Quick-action cards (evenly spaced) ────────────────────────────────────

  Widget _buildQuickActionCards(BuildContext context) {
    final modules = [
      _ModuleItem(
          icon: Icons.assignment_outlined,
          label: 'Tasks',
          color: Colors.blue,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TrackmanTasksScreen()))),
      _ModuleItem(
          icon: Icons.history,
          label: 'History',
          color: Colors.purple,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TrackmanHistoryScreen()))),
      _ModuleItem(
          icon: Icons.shield_outlined,
          label: 'Safety',
          color: Colors.green,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TrackmanSafetyScreen()))),
      _ModuleItem(
          icon: Icons.report_problem_outlined,
          label: 'Report',
          color: Colors.orange,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const TrackmanReportIssueScreen()))),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: modules
            .map((m) => Expanded(child: _buildActionCard(m)))
            .toList()
            .expand((w) => [w, const SizedBox(width: 10)])
            .toList()
          ..removeLast(),
      ),
    );
  }

  Widget _buildActionCard(_ModuleItem module) {
    return GestureDetector(
      onTap: module.onTap,
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(module.icon, color: module.color, size: 24),
            const SizedBox(height: 6),
            Text(
              module.label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Safety & zone card ────────────────────────────────────────────────────

  Widget _buildSafetyAndLocationCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.accent, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Location',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  if (_trackmanUser != null && (_trackmanUser!.regions?.isNotEmpty == true || _trackmanUser!.division != null))
                    Text(
                      [
                        if (_trackmanUser!.regions?.isNotEmpty == true) _trackmanUser!.regions!.join(', '),
                        if (_trackmanUser!.division != null) _trackmanUser!.division,
                      ].join(' • '),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    const Text('Main Station',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                            
                  if (_trackmanUser?.zone != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _trackmanUser!.zone!,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TrackmanNotificationsScreen()),
                ).then((_) => _checkNotifications());
              },
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined,
                      color: AppColors.primary, size: 30),
                  if (hasNotifications)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Recent tasks ──────────────────────────────────────────────────────────

  Widget _buildRecentTasks() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: ApiService.fetchTasks(
              assignedToUserId: Supabase.instance.client.auth.currentUser?.id,
              regions: _trackmanUser?.regions,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return const Text('No recent tasks');
            }
            final tasks = snapshot.data!;
            final task1 = tasks[0];
            final task2 = tasks.length > 1 ? tasks[1] : null;

            return Column(
              children: [
                _buildTaskTile(task1),
                if (task2 != null) ...[
                  const Divider(height: 24),
                  _buildTaskTile(task2),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTaskTile(Map<String, dynamic> task) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => TrackmanTaskDetailsScreen(task: task)),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: task['color'], shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task['title'],
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(task['priority'],
                    style: TextStyle(
                        color: task['color'],
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textLight, size: 20),
        ],
      ),
    );
  }

  // ── Emergency ─────────────────────────────────────────────────────────────

  Widget _buildEmergencyActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Emergency Stop Triggered!'),
                  backgroundColor: Colors.red));
            },
            icon: const Icon(Icons.warning, color: Colors.white, size: 20),
            label: const Text('SOS / Stop',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _ModuleItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ModuleItem(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
}
