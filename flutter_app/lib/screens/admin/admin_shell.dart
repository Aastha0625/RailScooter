import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import 'tabs/admin_overview_tab.dart';
import 'tabs/admin_approvals_tab.dart';
import 'tabs/admin_users_tab.dart';
import 'tabs/admin_fleet_tab.dart';
import 'tabs/admin_reports_tab.dart';
import 'tabs/admin_broadcast_tab.dart';
import '../alerts/alerts_rules_screen.dart';
import 'widgets/admin_sidebar.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  static const List<AdminNavItem> _navItems = [
    AdminNavItem(icon: Icons.dashboard_rounded,        label: 'Overview'),
    AdminNavItem(icon: Icons.how_to_reg_rounded,       label: 'Approvals', hasBadge: true),
    AdminNavItem(icon: Icons.people_alt_rounded,       label: 'Users'),
    AdminNavItem(icon: Icons.electric_scooter_rounded, label: 'Fleet'),
    AdminNavItem(icon: Icons.rule_outlined,            label: 'Rules & Alerts'),
    AdminNavItem(icon: Icons.report_problem_rounded,   label: 'Reports'),
    AdminNavItem(icon: Icons.campaign_rounded,         label: 'Broadcast'),
  ];

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      const AdminOverviewTab(),
      AdminApprovalsTab(onBadgeCountChanged: (_) => setState(() {})),
      const AdminUsersTab(),
      const AdminFleetTab(),
      const AlertsRulesScreen(),
      const AdminReportsTab(),
      const AdminBroadcastTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // On narrow screens (phone / small tablet), use bottom nav instead of sidebar
    final isWide = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        AdminSidebar(
          navItems: _navItems,
          selectedIndex: _selectedIndex,
          onItemSelected: (i) => setState(() => _selectedIndex = i),
        ),
        Expanded(
          child: _tabs[_selectedIndex],
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        // Top AppBar for narrow layout (only on Overview)
        if (_selectedIndex == 0)
          Container(
            height: MediaQuery.of(context).padding.top + 56,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            color: AppColors.primary,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Image.asset('assets/images/logo.png', height: 32),
                const SizedBox(width: 12),
                const Text(
                  'Admin Panel',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                  tooltip: 'Log Out',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700)),
                        content: const Text('Are you sure you want to log out of the Admin Panel?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.severityCritical,
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Log Out'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await Supabase.instance.client.auth.signOut();
                    }
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        Expanded(child: _tabs[_selectedIndex]),
        _buildBottomNav(),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (i) => setState(() => _selectedIndex = i),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.textLight,
      backgroundColor: Colors.white,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      items: _navItems
          .map((item) => BottomNavigationBarItem(
                icon: Icon(item.icon, size: 22),
                label: item.label,
              ))
          .toList(),
    );
  }
}
