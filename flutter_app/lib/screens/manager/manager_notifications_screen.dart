import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'manager_task_details_screen.dart';

class ManagerNotificationsScreen extends StatefulWidget {
  const ManagerNotificationsScreen({super.key});

  @override
  State<ManagerNotificationsScreen> createState() =>
      _ManagerNotificationsScreenState();
}

class _ManagerNotificationsScreenState
    extends State<ManagerNotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _saveReadTime();
  }

  Future<void> _saveReadTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_notification_read_time', DateTime.now().toIso8601String());
  }

  Future<void> _loadNotifications() async {
    try {
      final client = Supabase.instance.client;

      // Fetch broadcast messages
      final broadcasts = await client
          .from('broadcast_messages')
          .select()
          .or('target_role.eq.manager,target_role.eq.all')
          .order('created_at', ascending: false);

      // Fetch active vehicle assignments in this manager's zone
      final manager = await ApiService.fetchCurrentUserData();
      final assignments = await client
          .from('vehicle_assignments')
          .select('vehicle_id, app_users!inner(zone)')
          .eq('is_active', true)
          .eq('app_users.zone', manager?.zone ?? '');
      
      final myZoneVehicleIds = assignments.map((a) => a['vehicle_id']).toSet();

      // Fetch active vehicle alerts, then filter in Dart
      final allAlertsData = await client
          .from('vehicle_alerts')
          .select()
          .eq('is_acknowledged', false)
          .order('created_at', ascending: false);

      final alerts = allAlertsData.where((a) => myZoneVehicleIds.contains(a['vehicle_id'])).toList();

      final List<Map<String, dynamic>> allNotifications = [];

      // Convert broadcasts
      for (final item in broadcasts) {
        allNotifications.add({
          'title': item['title'],
          'message': item['body'],
          'time': item['created_at'],
          'type': 'broadcast',
          'task_id': item['task_id'],
        });
      }

      // Convert alerts
      for (final item in alerts) {
        allNotifications.add({
          'title':
              '${item['alert_type'].toString().toUpperCase()} Alert',
          'message': item['message'],
          'time': item['created_at'],
          'type': 'alert',
          'severity': item['severity'],
        });
      }

      // Sort newest first
      allNotifications.sort(
        (a, b) =>
            DateTime.parse(b['time'])
                .compareTo(DateTime.parse(a['time'])),
      );

      setState(() {
        notifications = allNotifications;
        loading = false;
      });
    } catch (e) {
      debugPrint('Notification Error: $e');

      setState(() {
        loading = false;
      });
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'broadcast':
        return Icons.campaign;

      case 'alert':
        return Icons.warning_amber_rounded;

      default:
        return Icons.notifications;
    }
  }

  Color _getColor(Map<String, dynamic> notification) {
    if (notification['type'] == 'alert') {
      switch (notification['severity']) {
        case 'critical':
          return Colors.red;

        case 'high':
          return Colors.orange;

        case 'medium':
          return Colors.amber;

        default:
          return Colors.green;
      }
    }

    return AppColors.primary;
  }

  String _formatTime(String time) {
    final date = DateTime.parse(time);
    final difference = DateTime.now().difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} hrs ago';
    }

    return '${difference.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 60,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No notifications available',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,

                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      final color = _getColor(notification);

                      return GestureDetector(
                        onTap: () async {
                          if (notification['task_id'] != null) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(child: CircularProgressIndicator()),
                            );
                            try {
                              final taskData = await ApiService.fetchTaskById(notification['task_id']);
                              if (mounted) Navigator.pop(context); // close dialog
                              if (taskData != null && mounted) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => ManagerTaskDetailsScreen(task: taskData)));
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task not found.')));
                              }
                            } catch (e) {
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            }
                          }
                        },
                        child: Container(
                          margin:
                              const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.cardBorder,
                          ),
                        ),

                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  color.withValues(alpha: 0.15),

                              child: Icon(
                                _getIcon(notification['type']),
                                color: color,
                              ),
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                children: [
                                  Text(
                                    notification['title'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold,
                                      color:
                                          AppColors.textPrimary,
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  Text(
                                    notification['message'],
                                    style: const TextStyle(
                                      color:
                                          AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  Text(
                                    _formatTime(
                                      notification['time'],
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ));
                    },
                  ),
                ),
    );
  }
}
