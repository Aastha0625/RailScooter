import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_base_screen.dart';
import 'admin_user_detail_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AppUser> _users = [];
  List<AppUser> _pending = [];
  List<AppUser> _current = [];
  bool _loading = true;
  String _searchQuery = '';
  String _filterRole = 'all';   // all | admin | manager | trackman | suspended

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() { if (mounted) setState(() {}); });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.fetchAllUsersAdmin(),
      ]);
      if (mounted) {
        
        setState(() {
          _users = results[0] as List<AppUser>;
          _pending = _users.where((u) => u.approvalStatus == 'pending').toList();
          _current = _users.where((u) => u.approvalStatus != 'pending').toList();

          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<AppUser> get _filtered {
    var list = _current;
    if (_filterRole == 'suspended') {
      list = list.where((u) => !u.isActive).toList();
    } else if (_filterRole != 'all') {
      list = list.where((u) => u.role == _filterRole).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((u) =>
        u.fullName.toLowerCase().contains(q) ||
        (u.employeeId?.toLowerCase().contains(q) ?? false) ||
        u.phone.contains(q) ||
        u.role.contains(q),
      ).toList();
    }
    return list;
  }

  List<AppUser> get _filteredPending {
    var list = _pending;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((u) =>
        u.fullName.toLowerCase().contains(q) ||
        (u.employeeId?.toLowerCase().contains(q) ?? false) ||
        u.phone.contains(q) ||
        u.role.contains(q),
      ).toList();
    }
    return list;
  }


  @override
  Widget build(BuildContext context) {
    return AdminBaseScreen(
      title: 'Users & Approvals',
      body: Column(
        children: [
          _buildTopBar(),
          Container(
            color: AppColors.primary,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'Requests'),
                Tab(text: 'Current Users'),
              ],
            ),
          ),
          _buildFilters(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPendingList(),
                      _buildCurrentList(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingList() {
    if (_filteredPending.isEmpty) return const Center(child: Text('No pending requests', style: TextStyle(color: AppColors.textSecondary)));
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        itemCount: _filteredPending.length,
        itemBuilder: (_, i) => _UserCard(
          user: _filteredPending[i],
          onTap: () => _openDetail(_filteredPending[i]),
        ),
      ),
    );
  }

  Widget _buildCurrentList() {
    if (_filtered.isEmpty) return const Center(child: Text('No users match filter', style: TextStyle(color: AppColors.textSecondary)));
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        itemCount: _filtered.length,
        itemBuilder: (_, i) => _UserCard(
          user: _filtered[i],
          onTap: () => _openDetail(_filtered[i]),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20, right: 20, bottom: 12,
      ),
      color: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_alt_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('All Users', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    Text('${_users.length} total • ${_users.where((u) => u.isActive).length} active',
                        style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white70), onPressed: _load),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by name, ID, phone...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    const filters = [
      ('all', 'All'),
      ('admin', 'Admin'),
      ('manager', 'Manager'),
      ('trackman', 'Trackman'),
      ('suspended', 'Suspended'),
    ];

    return Container(
      height: 48,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filters.map((f) {
          final isSelected = _filterRole == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filterRole = f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppColors.accent : AppColors.cardBorder),
                ),
                child: Text(f.$2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    )),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _openDetail(AppUser user) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminUserDetailScreen(
          user: user,
          onUpdated: _load,
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AppUser user;
  final VoidCallback onTap;

  const _UserCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: user.isActive ? AppColors.cardBorder : AppColors.severityCritical.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _roleColor(user.role).withValues(alpha: 0.12),
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                    style: TextStyle(color: _roleColor(user.role), fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                if (!user.isActive)
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      width: 12, height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.severityCritical,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.white, spreadRadius: 1.5)],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (user.phone.isNotEmpty) user.phone,
                      if (user.employeeId != null) 'ID: ',
                    ].join(' · '),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _RoleBadge(role: user.role),
                const SizedBox(height: 4),
                if (!user.isActive)
                  const Text('SUSPENDED', style: TextStyle(fontSize: 9, color: AppColors.severityCritical, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 20),
          ],
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':   return AppColors.severityCritical;
      case 'manager': return AppColors.accent;
      default:        return AppColors.primary;
    }
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color bg;
    switch (role) {
      case 'manager': bg = AppColors.accent; break;
      case 'admin':   bg = AppColors.severityCritical; break;
      default:        bg = AppColors.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(role.toUpperCase(),
          style: TextStyle(fontSize: 9, color: bg, fontWeight: FontWeight.w700)),
    );
  }
}
