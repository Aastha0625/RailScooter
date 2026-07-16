import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/app_sidebar.dart';
import '../tracking/geofence_tracking_screen.dart';

import 'admin_users_screen.dart';

import 'admin_fleet_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_broadcast_screen.dart';
import 'admin_tasks_screen.dart';
import 'admin_activity_screen.dart';
import 'admin_analytics_screen.dart';
import '../manager/manager_dispatch_screen.dart';
import '../alerts/alerts_rules_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_profile_screen.dart';
import 'admin_notifications_screen.dart';
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
  bool _hasNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadAdminName();
    _checkNotifications();
  }

  Future<void> _checkNotifications() async {
    try {
      final client = Supabase.instance.client;
      final prefs = await SharedPreferences.getInstance();
      final lastReadStr = prefs.getString('last_admin_notification_read_time');
      DateTime lastRead;
      if (lastReadStr != null) {
        lastRead = DateTime.parse(lastReadStr);
      } else {
        lastRead = DateTime.now();
        await prefs.setString('last_admin_notification_read_time', lastRead.toIso8601String());
      }

      final broadcastsResponse = await client
          .from('broadcast_messages')
          .select('id, created_at')
          .or('target_role.eq.admin,target_role.eq.manager,target_role.eq.trackman,target_role.eq.all');

      final hasUnreadBroadcasts = broadcastsResponse
          .any((b) => DateTime.parse(b['created_at']).isAfter(lastRead));

      if (!mounted) return;
      setState(() => _hasNotifications = hasUnreadBroadcasts);
    } catch (e) {
      debugPrint('Notification error: $e');
    }
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
        icon: Icons.map_rounded,
        label: 'Live Map & Zones',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GeofenceTrackingScreen(userRole: 'admin'))),
      ),
      SidebarItem(
        icon: Icons.assignment,
        label: 'Tasks',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTasksScreen())),
      ),
      SidebarItem(
        icon: Icons.people_alt_rounded,
        label: 'Users',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
      ),
      SidebarItem(
        icon: Icons.send_rounded,
        label: 'Dispatch Operations',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerDispatchScreen(userRole: 'admin'))),
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
        icon: Icons.analytics_outlined,
        label: 'Analytics',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen())),
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
      SidebarItem(
        icon: Icons.timeline_rounded,
        label: 'Activity Feed',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminActivityScreen())),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: widget.appBar ?? CustomAppBar(
        title: widget.title!,
        additionalActions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const AdminNotificationsScreen())
              ).then((_) => _checkNotifications());
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                if (_hasNotifications)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
