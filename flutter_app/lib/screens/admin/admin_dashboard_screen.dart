import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/alert_rule.dart';
import '../../models/vehicle_alert.dart';
import '../../utils/formatters.dart';
import '../tracking/geofence_tracking_screen.dart';
import 'admin_base_screen.dart';
import 'admin_fleet_screen.dart';
import 'admin_users_screen.dart';
import 'admin_tasks_screen.dart';
import 'admin_activity_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  int _pendingCount = 0;
  int _totalUsers = 0;
  int _totalVehicles = 0;
  int _broadcastCount = 0;
  List<Map<String, dynamic>> _activityLog = [];
  List<AlertRule> _rules = [];
  List<VehicleAlert> _alerts = [];
  RealtimeChannel? _channel;
  RealtimeChannel? _alertsChannel;
  RealtimeChannel? _rulesChannel;
  String _adminName = 'Admin';

  @override
  void initState() {
    super.initState();
    _loadAdminName();
    _loadData();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _alertsChannel?.unsubscribe();
    _rulesChannel?.unsubscribe();
    super.dispose();
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

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.fetchPendingUsersCount(),
        ApiService.fetchUsersCount(),
        ApiService.fetchActivityLog(limit: 5), // Only need a preview now
        ApiService.fetchBroadcastsCount(),
        ApiService.fetchDashboardStats(),
        ApiService.fetchAlertRules(),
        ApiService.fetchAlertEvents(unacknowledged: true),
      ]);
      if (!mounted) return;
      setState(() {
        _pendingCount = results[0] as int;
        _totalUsers = results[1] as int;
        _activityLog = results[2] as List<Map<String, dynamic>>;
        _broadcastCount = results[3] as int;
        final stats = results[4] as Map<String, int>;
        _totalVehicles = stats['total_vehicles'] ?? 0;
        _rules = (results[5] as List<AlertRule>).take(3).toList();
        _alerts = (results[6] as List<VehicleAlert>).take(4).toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _subscribeRealtime() {
    _channel = ApiService.subscribeToActivityLog((payload) {
      if (!mounted) return;
      setState(() {
        _activityLog.insert(0, payload);
        if (_activityLog.length > 5) _activityLog.removeLast();
      });
    });

    _alertsChannel = ApiService.subscribeToAlertEvents((payload) {
      if (!mounted) return;
      setState(() {
        final alert = VehicleAlert.fromJson(payload);
        if (!alert.isAcknowledged) {
          _alerts.insert(0, alert);
          if (_alerts.length > 4) _alerts.removeLast();
        }
      });
    });

    _rulesChannel = ApiService.subscribeToAlertRules((payload) {
      if (!mounted) return;
      final updatedRule = AlertRule.fromJson(payload);
      setState(() {
        final index = _rules.indexWhere((r) => r.id == updatedRule.id);
        if (index != -1) {
          _rules[index] = updatedRule;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AdminBaseScreen(
        title: 'Overview',
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    return AdminBaseScreen(
      title: 'Overview',
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroSection(),
              const SizedBox(height: 16),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    _buildRefreshButton(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildQuickActionCards(context),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildStatCardsGrid(),
                    const SizedBox(height: 28),

                    _buildSectionHeader(Icons.rule_outlined, 'Active Rules', AppColors.primary),
                    const SizedBox(height: 12),
                    _buildRulesPreview(),
                    const SizedBox(height: 28),

                    _buildActivitySectionHeader(),
                    const SizedBox(height: 12),
                    _buildActivityFeedPreview(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
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
                child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Admin Hub', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                    Text('Welcome, $_adminName', style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCards(BuildContext context) {
    final modules = [
      _ModuleItem(
        icon: Icons.map_rounded,
        label: 'Live Map',
        color: Colors.green,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GeofenceTrackingScreen(userRole: 'admin'))),
      ),
      _ModuleItem(
        icon: Icons.assignment,
        label: 'Tasks',
        color: Colors.blueAccent,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTasksScreen())),
      ),
      _ModuleItem(
        icon: Icons.electric_scooter_rounded,
        label: 'Fleet',
        color: AppColors.accent,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFleetScreen())),
      ),
      _ModuleItem(
        icon: Icons.people_alt_rounded,
        label: 'Users',
        color: Colors.purple,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: modules.map((m) => SizedBox(
          width: (MediaQuery.of(context).size.width - 48 - (12 * 3)) / 4 < 70 
              ? (MediaQuery.of(context).size.width - 48 - 12) / 2 // Fallback to 2 per row on very small screens
              : (MediaQuery.of(context).size.width - 48 - (12 * 3)) / 4,
          child: _buildActionCard(m),
        )).toList(),
      ),
    );
  }

  Widget _buildActionCard(_ModuleItem module) {
    return GestureDetector(
      onTap: module.onTap,
      child: Container(
        height: 76,
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
            Text(
              module.label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() => _loading = true);
          _loadData();
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 18),
        ),
      ),
    );
  }

  Widget _buildStatCardsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount = width > 700 ? 4 : 2;
        
        return GridView(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            mainAxisExtent: 115,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard(
              context: context,
              icon: Icons.pending_actions_rounded,
              label: 'Pending Approvals',
              value: '$_pendingCount',
              color: AppColors.severityHigh,
              highlight: _pendingCount > 0,
            ),
            _buildStatCard(
              context: context,
              icon: Icons.people_alt_rounded,
              label: 'Total Users',
              value: '$_totalUsers',
              color: AppColors.primary,
            ),
            _buildStatCard(
              context: context,
              icon: Icons.electric_scooter_rounded,
              label: 'Fleet Size',
              value: '$_totalVehicles',
              color: AppColors.accent,
            ),
            _buildStatCard(
              context: context,
              icon: Icons.campaign_rounded,
              label: 'Broadcasts',
              value: '$_broadcastCount',
              color: AppColors.statusIdle,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool highlight = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 360;
    final padding = isNarrow ? 12.0 : 16.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: highlight ? color.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? color.withValues(alpha: 0.3) : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isNarrow ? 4.0 : 6.0),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: isNarrow ? 16.0 : 18.0),
              ),
              const Spacer(),
              if (highlight)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
                    ],
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: isNarrow ? 20.0 : 22.0,
                      fontWeight: FontWeight.w700,
                      color: highlight ? color : AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontSize: isNarrow ? 10.0 : 11.0,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.statusActive.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.statusActive,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text('LIVE',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.statusActive)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySectionHeader() {
    return Row(
      children: [
        const Icon(Icons.timeline_rounded, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        const Text('Activity Feed Preview',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const Spacer(),
        TextButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminActivityScreen()));
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('View All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ),
      ],
    );
  }

  Widget _buildActivityFeedPreview() {
    if (_activityLog.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.inbox_rounded, size: 40, color: AppColors.textLight),
              SizedBox(height: 12),
              Text('No activity yet',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _activityLog.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = _activityLog[index];
          return _buildActivityItem(entry);
        },
      ),
    );
  }

  Widget _buildAlertsPreview() {
    if (_alerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.shield_outlined, size: 40, color: AppColors.textLight),
              SizedBox(height: 12),
              Text('No unacknowledged alerts', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _alerts.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final alert = _alerts[index];
          final sevColor = _severityColor(alert.severity);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: sevColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${alert.vehicleLabel} - ${alert.alertType}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                      Text(Formatters.formatAlertMessage(alert.alertType, alert.message), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Text(DateFormat('MMM d, h:mm a').format(alert.createdAt.toLocal()), style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRulesPreview() {
    if (_rules.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.rule_outlined, size: 40, color: AppColors.textLight),
              SizedBox(height: 12),
              Text('No active rules configured', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _rules.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final rule = _rules[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.rule_outlined, color: AppColors.primary, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rule.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                      Text(Formatters.formatRule(rule.ruleType, rule.conditionOperator, rule.conditionValue, rule.conditionUnit), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Switch(
                  value: rule.isActive,
                  onChanged: (val) async {
                    try {
                      await ApiService.updateAlertRule(rule.id, {'is_active': val});
                      setState(() {
                        _rules[index] = AlertRule(
                          id: rule.id,
                          name: rule.name,
                          description: rule.description,
                          ruleType: rule.ruleType,
                          severity: rule.severity,
                          conditionOperator: rule.conditionOperator,
                          conditionValue: rule.conditionValue,
                          conditionUnit: rule.conditionUnit,
                          isActive: val,
                          notificationEmail: rule.notificationEmail,
                          notificationPush: rule.notificationPush,
                          notificationSms: rule.notificationSms,
                          createdAt: rule.createdAt,
                        );
                      });
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update rule: $e'), backgroundColor: Colors.red));
                      }
                    }
                  },
                  activeThumbColor: AppColors.accent,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical': return AppColors.severityCritical;
      case 'high': return AppColors.severityHigh;
      case 'medium': return AppColors.severityMedium;
      default: return AppColors.severityLow;
    }
  }

  Widget _buildActivityItem(Map<String, dynamic> entry) {
    final eventType = entry['event_type'] as String? ?? 'other';
    final description = entry['description'] as String? ?? '';
    final actorName = entry['actor_name'] as String? ?? 'System';
    final createdAt = entry['created_at'] != null
        ? DateTime.tryParse(entry['created_at'])
        : null;
    final timeStr = createdAt != null
        ? DateFormat('MMM d, h:mm a').format(createdAt.toLocal())
        : '';

    final iconData = _eventIcon(eventType);
    final iconColor = _eventColor(eventType);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(iconData, color: iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatEventType(eventType),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(description,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(actorName,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(timeStr,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textLight)),
            ],
          ),
        ],
      ),
    );
  }

  IconData _eventIcon(String eventType) {
    switch (eventType) {
      case 'user_approved': return Icons.check_circle_rounded;
      case 'user_rejected': return Icons.cancel_rounded;
      case 'user_suspended': return Icons.pause_circle_rounded;
      case 'user_reactivated': return Icons.play_circle_rounded;
      case 'user_edited': return Icons.edit_rounded;
      case 'user_deleted': return Icons.delete_rounded;
      case 'clock_in': return Icons.login_rounded;
      case 'clock_out': return Icons.logout_rounded;
      case 'report_submitted': return Icons.description_rounded;
      case 'alert_acknowledged': return Icons.notifications_active_rounded;
      case 'vehicle_updated': return Icons.electric_scooter_rounded;
      case 'broadcast_sent': return Icons.campaign_rounded;
      default: return Icons.info_rounded;
    }
  }

  Color _eventColor(String eventType) {
    switch (eventType) {
      case 'user_approved':
      case 'user_reactivated':
        return AppColors.statusActive;
      case 'user_rejected':
      case 'user_suspended':
      case 'user_deleted':
        return AppColors.severityCritical;
      case 'user_edited':
      case 'vehicle_updated':
        return AppColors.statusIdle;
      case 'broadcast_sent':
        return AppColors.accent;
      case 'alert_acknowledged':
        return AppColors.severityMedium;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatEventType(String eventType) {
    return eventType
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

class _ModuleItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _ModuleItem({required this.icon, required this.label, required this.color, required this.onTap});
}
