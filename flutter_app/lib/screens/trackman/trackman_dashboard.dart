import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import 'trackman_history_screen.dart';
import 'trackman_safety_screen.dart';
import 'trackman_geofencing_screen.dart';
import 'trackman_report_issue_screen.dart';
import 'trackman_tasks_screen.dart';
import 'trackman_notifications_screen.dart';
import 'trackman_profile_screen.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_drawer.dart';
import '../alerts/alerts_rules_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _checkNotifications();
    _fetchActiveVehicle();
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
            // Fallback values if no telemetry exists yet
            updatedVehicleMap['current_speed'] = 0;
            updatedVehicleMap['battery_level'] = 100;
            updatedVehicleMap['estimated_range'] = '45.0';
          }
          assignmentData['vehicles'] = updatedVehicleMap;
        }
      }

      if (mounted) {
        setState(() {
          _activeAssignment = assignmentData;
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

    final broadcasts = await client
        .from('broadcast_messages')
        .select('id')
        .or('target_role.eq.trackman,target_role.eq.all');

    final alerts = await client
        .from('vehicle_alerts')
        .select('id')
        .eq('is_acknowledged', false);

    if (!mounted) return;

    setState(() {
      hasNotifications =
          broadcasts.isNotEmpty || alerts.isNotEmpty;
    });

  } catch (e) {
    debugPrint('Notification error: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Trackman Dashboard'),
      drawer: CustomDrawer(
        roleTitle: 'Trackman Portal',
        menuItems: [
          CustomDrawer.buildDrawerItem(context, Icons.dashboard_outlined, 'Dashboard', () => Navigator.pop(context)),
          CustomDrawer.buildDrawerItem(context, Icons.assignment_outlined, 'My Tasks', () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute( builder: (_) => const TrackmanTasksScreen())); }),
          CustomDrawer.buildDrawerItem(context, Icons.history, 'My Ride History', () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackmanHistoryScreen())); }),
          CustomDrawer.buildDrawerItem(context, Icons.shield_outlined, 'Safety Guidelines', () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackmanSafetyScreen())); }),
          CustomDrawer.buildDrawerItem(context, Icons.map_outlined, 'My Current Zone', () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackmanGeofencingScreen())); }),
          CustomDrawer.buildDrawerItem(context, Icons.report_problem_outlined, 'Report an Issue', () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackmanReportIssueScreen())); }),
          CustomDrawer.buildDrawerItem(context, Icons.notifications_active_outlined, 'Alerts & Rules', () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsRulesScreen())); }),
          CustomDrawer.buildDrawerItem(context, Icons.person_outline, 'My Profile', () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackmanProfileScreen())); }),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActiveVehicleHero(),
            const SizedBox(height: 16),
            _buildSafetyAndLocationCard(),
            const SizedBox(height: 16),
            _buildEmergencyActions(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveVehicleHero() {
    if (_loading) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
        ),
        child: const Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    final hasAssignment = _activeAssignment != null;
    final vehicle = hasAssignment ? _activeAssignment!['vehicles'] : null;
    final vehicleLabel = vehicle != null ? vehicle['vehicle_id'] : 'No Vehicle Assigned';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _isUnlocked ? Colors.green : AppColors.statusIdle,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: (_isUnlocked ? Colors.green : AppColors.statusIdle).withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Icon(_isUnlocked ? Icons.lock_open : Icons.lock, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vehicleLabel, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  Text(hasAssignment ? (_isUnlocked ? 'Active Run' : 'Locked') : 'Awaiting Assignment', style: TextStyle(color: hasAssignment ? (_isUnlocked ? Colors.greenAccent : Colors.white70) : Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
              const Spacer(),
              if (hasAssignment)
                Switch(
                  value: _isUnlocked,
                  activeThumbColor: Colors.greenAccent,
                  onChanged: (val) {
                    setState(() {
                      _isUnlocked = val;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),
          // Telemetry Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTelemetryItem(Icons.speed, _isUnlocked ? '${vehicle?['current_speed'] ?? 25} km/h' : '0 km/h', 'Speed'),
              _buildTelemetryItem(Icons.battery_charging_full, '${vehicle?['battery_level'] ?? 100}%', 'Battery'),
              _buildTelemetryItem(Icons.timeline, '${vehicle?['estimated_range'] ?? 45} km', 'Est. Range'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

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
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          const Icon(
            Icons.location_on,
            color: AppColors.accent,
            size: 40,
          ),

          const SizedBox(width: 16),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Zone',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Main Station Zone',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
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
                  builder: (_) => const TrackmanNotificationsScreen(),
                ),
              ).then((_) {
                _checkNotifications();
              });
            },

            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.primary, 
                  size: 30, 
                ), 

                if (hasNotifications) 
                  Positioned(
                    right: 0, 
                    top: 0, 
                    child: Container(
                      width: 10, 
                      height: 10, 
                      decoration: const BoxDecoration(
                        color: Colors.red, 
                        shape: BoxShape.circle, 
                      ), 
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

  Widget _buildEmergencyActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TrackmanReportIssueScreen(),));
                  },
                  icon: const Icon(Icons.report_problem, color: Colors.white, size: 20),
                  label: const Text('Report Issue', style: TextStyle(color: Colors.white, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Emergency Stop Triggered!'), backgroundColor: Colors.red));
                  },
                  icon: const Icon(Icons.warning, color: Colors.white, size: 20),
                  label: const Text('SOS / Stop', style: TextStyle(color: Colors.white, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
