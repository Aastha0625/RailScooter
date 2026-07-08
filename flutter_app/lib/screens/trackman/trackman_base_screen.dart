import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/custom_app_bar.dart';

import 'trackman_dashboard.dart';
import 'trackman_tasks_screen.dart';
import 'trackman_history_screen.dart';
import 'trackman_safety_screen.dart';
import 'trackman_geofencing_screen.dart';
import 'trackman_report_issue_screen.dart';
import '../alerts/alerts_rules_screen.dart';
import 'trackman_profile_screen.dart';

class TrackmanBaseScreen extends StatefulWidget {
  final String? title;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;

  const TrackmanBaseScreen({
    super.key,
    this.title,
    this.appBar,
    required this.body,
    this.floatingActionButton,
  }) : assert(title != null || appBar != null, 'Either title or appBar must be provided');

  @override
  State<TrackmanBaseScreen> createState() => _TrackmanBaseScreenState();
}

class _TrackmanBaseScreenState extends State<TrackmanBaseScreen> {
  String _trackmanName = 'Trackman';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final data = await Supabase.instance.client
          .from('app_users')
          .select('full_name')
          .eq('id', uid)
          .maybeSingle();
      if (mounted && data != null) {
        setState(() => _trackmanName = data['full_name'] ?? 'Trackman');
      }
    } catch (e) {
      debugPrint('Error loading trackman name: $e');
    }
  }

  List<SidebarItem> _getSidebarItems(BuildContext context) {
    return [
      SidebarItem(
        icon: Icons.dashboard_outlined,
        label: 'Dashboard',
        onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const TrackmanDashboardScreen()), (route) => false),
      ),
      SidebarItem(
        icon: Icons.assignment_outlined,
        label: 'My Tasks',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackmanTasksScreen())),
      ),
      SidebarItem(
        icon: Icons.history,
        label: 'My Ride History',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackmanHistoryScreen())),
      ),
      SidebarItem(
        icon: Icons.shield_outlined,
        label: 'Safety Guidelines',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackmanSafetyScreen())),
      ),
      SidebarItem(
        icon: Icons.map_outlined,
        label: 'My Current Zone',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackmanGeofencingScreen())),
      ),
      SidebarItem(
        icon: Icons.report_problem_outlined,
        label: 'Report an Issue',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackmanReportIssueScreen())),
      ),
      SidebarItem(
        icon: Icons.notifications_active_outlined,
        label: 'Alerts & Rules',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsRulesScreen(userRole: 'trackman'))),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: widget.appBar ?? CustomAppBar(
        title: widget.title!,
        onProfileTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackmanProfileScreen()));
        },
      ),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      roleTitle: 'Trackman Portal',
      userName: _trackmanName,
      userRole: 'Trackman',
      sidebarItems: _getSidebarItems(context),
      onProfileTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackmanProfileScreen()));
      },
    );
  }
}
