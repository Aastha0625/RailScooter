import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/vehicle.dart';
import '../../services/api_service.dart';
import 'admin_base_screen.dart';
import 'admin_fleet_screen.dart';
import 'admin_tasks_screen.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  bool _loading = true;
  List<Vehicle> _vehicles = [];
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final vehicles = await ApiService.fetchVehicles();
      final tasks = await ApiService.fetchTasks();
      
      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          _tasks = tasks;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminBaseScreen(
      title: 'Analytics',
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.accent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Fleet Utilization', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _StatCard(
                          title: 'Active', 
                          value: _vehicles.where((v) => v.status == 'active').length.toString(), 
                          icon: Icons.electric_scooter, color: Colors.green,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFleetScreen(initialFilter: 'active'))),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(
                          title: 'Idle', 
                          value: _vehicles.where((v) => v.status == 'idle').length.toString(), 
                          icon: Icons.pause_circle_outline, color: Colors.blue,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFleetScreen(initialFilter: 'idle'))),
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _StatCard(
                          title: 'Maintenance', 
                          value: _vehicles.where((v) => v.status == 'maintenance').length.toString(), 
                          icon: Icons.build, color: Colors.orange,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFleetScreen(initialFilter: 'maintenance'))),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(
                          title: 'Total', 
                          value: _vehicles.length.toString(), 
                          icon: Icons.directions_car, color: AppColors.primary,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFleetScreen(initialFilter: 'all'))),
                        )),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text('Manager Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _StatCard(
                          title: 'Completed Tasks', 
                          value: _tasks.where((t) => t['status'] == 'Completed').length.toString(), 
                          icon: Icons.check_circle_outline, color: Colors.green,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTasksScreen(initialFilter: 'Completed'))),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(
                          title: 'Pending Tasks', 
                          value: _tasks.where((t) => t['status'] == 'Assigned' || t['status'] == 'Pending').length.toString(), 
                          icon: Icons.pending_actions, color: Colors.orange,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTasksScreen(initialFilter: 'Pending'))),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
