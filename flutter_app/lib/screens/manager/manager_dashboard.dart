import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../vehicles/vehicle_registry_screen.dart';
import '../tracking/geofence_tracking_screen.dart';
import 'manager_dispatch_screen.dart';
import 'manager_issues_screen.dart';
import '../manager/manager_dispatch_history_screen.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_drawer.dart';
import '../alerts/alerts_rules_screen.dart';
import '../departments/department_assignment_screen.dart';
import 'manager_profile_screen.dart';
import 'manager_base_screen.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  Map<String, int> _stats = {};
  int _openIssuesCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await ApiService.fetchDashboardStats();
      
      // Fetch open issues specific to Manager
      final issuesResp = await Supabase.instance.client
          .from('trackman_issues')
          .select('id')
          .eq('status', 'open')
          .count();
          
      final issuesCount = issuesResp.count;

      if (mounted) {
        setState(() { 
          _stats = stats; 
          _openIssuesCount = issuesCount;
          _loading = false; 
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load manager dashboard: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
            action: SnackBarAction(label: 'Retry', textColor: Colors.white, onPressed: _loadStats),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ManagerBaseScreen(
      title: 'Operations Hub',
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppColors.accent,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroSection(),
                    const SizedBox(height: 16),
                    _buildQuickActionCards(context),
                    const SizedBox(height: 24),
                    _buildAnalyticsTitle('Fleet Status Overview'),
                    _buildFleetStatusChart(),
                    const SizedBox(height: 24),
                    _buildAnalyticsTitle('Manager Metrics'),
                    _buildMetricsGrid(),
                    const SizedBox(height: 24),
                    _buildAnalyticsTitle('Recent Dispatches'),
                    _buildDispatchHistoryButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeroSection() {
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
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.assignment_ind, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manager Hub', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                  Text('Dispatch & Monitoring', style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCards(BuildContext context) {
    final modules = [
      _ModuleItem(icon: Icons.send_rounded, label: 'Dispatch', color: Colors.green, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerDispatchScreen()))),
      _ModuleItem(icon: Icons.report_problem, label: 'Issues', color: AppColors.severityHigh, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerIssuesScreen()))),
      _ModuleItem(icon: Icons.map_outlined, label: 'Tracking', color: AppColors.primary, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GeofenceTrackingScreen()))),
      _ModuleItem(icon: Icons.directions_car_outlined, label: 'Vehicles', color: AppColors.accent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleRegistryScreen()))),
    ];

    return SizedBox(
      height: 75,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: modules.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _buildActionCard(modules[i]),
      ),
    );
  }

  Widget _buildActionCard(_ModuleItem module) {
    return GestureDetector(
      onTap: module.onTap,
      child: Container(
        width: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(module.icon, color: module.color, size: 24),
            const SizedBox(height: 6),
            Text(module.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
    );
  }

  Widget _buildFleetStatusChart() {
    final total = _stats['total_vehicles'] ?? 10;
    final active = _stats['active_vehicles'] ?? 6;
    final idle = (total * 0.2).toInt();
    final offline = (total * 0.1).toInt();
    final maintenance = total - active - idle - offline;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                      return;
                    }
                    if (event is FlTapUpEvent) {
                      final title = pieTouchResponse.touchedSection!.touchedSection!.title;
                      String? status;
                      if (title == active.toString() && active > 0) {
                        status = 'active';
                      } else if (title == idle.toString() && idle > 0) status = 'idle';
                      else if (title == maintenance.toString() && maintenance > 0) status = 'maintenance';
                      else if (title == offline.toString() && offline > 0) status = 'offline';

                      if (status != null) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleRegistryScreen(initialStatusFilter: status)));
                      }
                    }
                  },
                ),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  if (active > 0)
                    PieChartSectionData(
                      color: AppColors.statusActive,
                      value: active.toDouble(),
                      title: '$active',
                      radius: 24,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  if (idle > 0)
                    PieChartSectionData(
                      color: AppColors.statusIdle,
                      value: idle.toDouble(),
                      title: '$idle',
                      radius: 20,
                      titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  if (maintenance > 0)
                    PieChartSectionData(
                      color: AppColors.statusMaintenance,
                      value: maintenance.toDouble(),
                      title: '$maintenance',
                      radius: 20,
                      titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  if (offline > 0)
                    PieChartSectionData(
                      color: AppColors.statusOffline,
                      value: offline.toDouble(),
                      title: '$offline',
                      radius: 20,
                      titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildChartLegend(AppColors.statusActive, 'Active Run'),
              _buildChartLegend(AppColors.statusIdle, 'Available'),
              _buildChartLegend(AppColors.statusMaintenance, 'Maint'),
              _buildChartLegend(AppColors.statusOffline, 'Offline'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildChartLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildMetricsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildMetricCard(
            icon: Icons.report_problem, 
            label: 'Open Issues', 
            value: '$_openIssuesCount', 
            color: AppColors.severityHigh,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerIssuesScreen())),
          )),
          const SizedBox(width: 16),
          Expanded(child: _buildMetricCard(
            icon: Icons.electric_scooter, 
            label: 'Available for Dispatch', 
            value: '${(_stats['total_vehicles'] ?? 10) - (_stats['active_vehicles'] ?? 6)}', 
            color: Colors.green,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleRegistryScreen(initialStatusFilter: 'idle'))),
          )),
        ],
      ),
    );
  }

  Widget _buildMetricCard({required IconData icon, required String label, required String value, required Color color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    ),
    );
  }

  Widget _buildDispatchHistoryButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerDispatchHistoryScreen())),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.history_outlined, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('View Dispatch History', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        SizedBox(height: 2),
                        Text('See all active and completed runs', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textLight),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}

class _ModuleItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ModuleItem({required this.icon, required this.label, required this.color, required this.onTap});
}
