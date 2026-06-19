import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/custom_app_bar.dart';

import 'manager_dashboard.dart';
import 'manager_dispatch_screen.dart';
import 'manager_issues_screen.dart';
import '../tracking/geofence_tracking_screen.dart';
import '../vehicles/vehicle_registry_screen.dart';
import '../alerts/alerts_rules_screen.dart';
import 'manager_profile_screen.dart';
import 'manager_task_assignment_screen.dart';

class ManagerBaseScreen extends StatefulWidget {
  final String? title;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;

  const ManagerBaseScreen({
    super.key,
    this.title,
    this.appBar,
    required this.body,
    this.floatingActionButton,
  }) : assert(title != null || appBar != null, 'Either title or appBar must be provided');

  @override
  State<ManagerBaseScreen> createState() => _ManagerBaseScreenState();
}

class _ManagerBaseScreenState extends State<ManagerBaseScreen> {
  String _managerName = 'Manager';

  @override
  void initState() {
    super.initState();
    _loadManagerName();
  }

  Future<void> _loadManagerName() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final data = await Supabase.instance.client
          .from('app_users')
          .select('full_name')
          .eq('id', uid)
          .maybeSingle();
      if (mounted && data != null) {
        setState(() => _managerName = data['full_name'] ?? 'Manager');
      }
    } catch (e) {
      debugPrint('Error loading manager name: $e');
    }
  }

  List<SidebarItem> _getSidebarItems(BuildContext context) {
    return [
      SidebarItem(
        icon: Icons.dashboard_outlined,
        label: 'Overview',
        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManagerDashboardScreen())),
      ),
      SidebarItem(
        icon: Icons.assignment_add,
        label: 'Assign Task',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerTaskAssignmentScreen())),
      ),
      SidebarItem(
        icon: Icons.send_rounded,
        label: 'Dispatch Vehicles',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerDispatchScreen())),
      ),
      SidebarItem(
        icon: Icons.report_problem_outlined,
        label: 'Issue Management',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerIssuesScreen())),
      ),
      SidebarItem(
        icon: Icons.map_outlined,
        label: 'Fleet Tracking',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GeofenceTrackingScreen(userRole: 'manager'))),
      ),
      SidebarItem(
        icon: Icons.electric_scooter_outlined,
        label: 'Vehicle Status',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleRegistryScreen(userRole: 'manager'))),
      ),
      SidebarItem(
        icon: Icons.notifications_active_outlined,
        label: 'Alerts & Rules',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsRulesScreen(userRole: 'manager'))),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: widget.appBar ?? CustomAppBar(
        title: widget.title!,
        onProfileTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerProfileScreen()));
        },
      ),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      roleTitle: 'Manager Operations',
      userName: _managerName,
      userRole: 'Manager',
      sidebarItems: _getSidebarItems(context),
      onProfileTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerProfileScreen()));
      },
    );
  }
}
