import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'admin_base_screen.dart';

class AdminActivityScreen extends StatefulWidget {
  const AdminActivityScreen({super.key});

  @override
  State<AdminActivityScreen> createState() => _AdminActivityScreenState();
}

class _AdminActivityScreenState extends State<AdminActivityScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _activityLog = [];
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadActivity();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadActivity() async {
    try {
      final results = await ApiService.fetchActivityLog(limit: 100);
      if (mounted) {
        setState(() {
          _activityLog = results;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load activity: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _subscribeRealtime() {
    _channel = ApiService.subscribeToActivityLog((payload) {
      if (!mounted) return;
      setState(() {
        _activityLog.insert(0, payload);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminBaseScreen(
      title: 'Activity Feed',
      body: RefreshIndicator(
        onRefresh: _loadActivity,
        color: AppColors.accent,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : _activityLog.isEmpty
                ? const Center(
                    child: Text('No activity found.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _activityLog.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final entry = _activityLog[index];
                      return _buildActivityCard(entry);
                    },
                  ),
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> entry) {
    final eventType = entry['event_type'] as String? ?? 'other';
    final description = entry['description'] as String? ?? '';
    final actorName = entry['actor_name'] as String? ?? 'System';
    final createdAt = entry['created_at'] != null ? DateTime.tryParse(entry['created_at']) : null;
    final timeStr = createdAt != null ? DateFormat('MMM d, h:mm a').format(createdAt.toLocal()) : '';

    final iconData = _eventIcon(eventType);
    final iconColor = _eventColor(eventType);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatEventType(eventType),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Text(actorName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                    const Spacer(),
                    const Icon(Icons.access_time, size: 14, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                  ],
                ),
              ],
            ),
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
    return eventType.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }
}
