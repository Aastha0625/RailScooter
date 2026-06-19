import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/app_sidebar.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_departments_screen.dart';
import 'admin_fleet_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_broadcast_screen.dart';
import '../alerts/alerts_rules_screen.dart';
import 'admin_profile_screen.dart';
import '../../widgets/custom_app_bar.dart';

class AdminBaseScreen extends StatefulWidget {
  final String? title;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;

  const AdminBaseScreen({
    super.key,
    this.title,
    this.appBar,
    required this.body,
    this.floatingActionButton,
  }) : assert(title != null || appBar != null, 'Either title or appBar must be provided');

  @override
  State<AdminBaseScreen> createState() => _AdminBaseScreenState();
}

class _AdminBaseScreenState extends State<AdminBaseScreen> {
  String _adminName = 'Admin';

  @override
  void initState() {
    super.initState();
    _loadAdminName();
  }

  Future<void> _loadAdminName() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final data = await Supabase.instance.client
          .from('app_users')
          .select('full_name')
          .eq('id', uid)
          .maybeSingle();
      if (mounted && data != null) {
        setState(() => _adminName = data['full_name'] ?? 'Admin');
      }
    } catch (e) {
      debugPrint('Error loading admin name: $e');
    }
  }

  List<SidebarItem> _getSidebarItems(BuildContext context) {
    return [
      SidebarItem(
        icon: Icons.dashboard_rounded,
        label: 'Overview',
        onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
      ),
      SidebarItem(
        icon: Icons.people_alt_rounded,
        label: 'Users',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
      ),
      SidebarItem(
        icon: Icons.business_outlined,
        label: 'Departments',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDepartmentsScreen())),
      ),
      SidebarItem(
        icon: Icons.electric_scooter_rounded,
        label: 'Fleet',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFleetScreen())),
      ),
      SidebarItem(
        icon: Icons.rule_outlined,
        label: 'Rules & Alerts',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsRulesScreen(userRole: 'admin'))),
      ),
      SidebarItem(
        icon: Icons.report_problem_rounded,
        label: 'Reports',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReportsScreen())),
      ),
      SidebarItem(
        icon: Icons.campaign_rounded,
        label: 'Broadcast',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBroadcastScreen())),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: widget.appBar ?? CustomAppBar(
        title: widget.title!,
        onProfileTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProfileScreen()));
        },
      ),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      roleTitle: 'Admin Panel',
      userName: _adminName,
      userRole: 'Administrator',
      sidebarItems: _getSidebarItems(context),
      onProfileTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProfileScreen()));
      },
    );
  }
}
