import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import 'tabs/admin_overview_tab.dart';
import 'tabs/admin_approvals_tab.dart';
import 'tabs/admin_users_tab.dart';
import 'tabs/admin_departments_tab.dart';
import 'tabs/admin_fleet_tab.dart';
import 'tabs/admin_reports_tab.dart';
import 'tabs/admin_broadcast_tab.dart';
import '../alerts/alerts_rules_screen.dart';
import 'admin_profile_screen.dart';
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
    AdminNavItem(icon: Icons.business_outlined,        label: 'Departments'),
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
      const AdminDepartmentsTab(),
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
    final activeItem = _navItems[_selectedIndex];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(activeItem.label),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accent,
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
            offset: const Offset(0, 48),
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
                );
              } else if (value == 'logout') {
                final confirm = await _showLogoutConfirmation();
                if (confirm == true) {
                  await Supabase.instance.client.auth.signOut();
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: AppColors.textPrimary, size: 18),
                    SizedBox(width: 8),
                    Text('View Profile', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: AppColors.severityCritical, size: 18),
                    SizedBox(width: 8),
                    Text('Log Out', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.primary,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PiScoot', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      Text('Admin Panel', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _navItems.length,
                itemBuilder: (context, index) {
                  final item = _navItems[index];
                  final isSelected = index == _selectedIndex;
                  return ListTile(
                    leading: Icon(item.icon, color: isSelected ? AppColors.accent : Colors.white70),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: isSelected ? AppColors.accent : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onTap: () {
                      Navigator.pop(context); // close drawer
                      setState(() => _selectedIndex = index);
                    },
                  );
                },
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.white70),
              title: const Text('Log Out', style: TextStyle(color: Colors.white70)),
              onTap: () async {
                Navigator.pop(context); // close drawer
                final confirm = await _showLogoutConfirmation();
                if (confirm == true) {
                  await Supabase.instance.client.auth.signOut();
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: _tabs[_selectedIndex],
    );
  }

  Future<bool?> _showLogoutConfirmation() {
    return showDialog<bool>(
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
  }
}
