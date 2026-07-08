import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrackmanTaskDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const TrackmanTaskDetailsScreen({
    super.key,
    required this.task,
  });

  @override
  State<TrackmanTaskDetailsScreen> createState() => _TrackmanTaskDetailsScreenState();
}

class _TrackmanTaskDetailsScreenState extends State<TrackmanTaskDetailsScreen> {
  late bool isCompleted;
  bool _updating = false;
  String _managerName = "Unknown Manager";

  @override
  void initState() {
    super.initState();
    isCompleted = widget.task['status'] == 'Completed';
    _fetchManagerName();
  }

  Future<void> _fetchManagerName() async {
    final assignedBy = widget.task['assigned_by'];
    if (assignedBy != null) {
      try {
        final res = await Supabase.instance.client
            .from('app_users')
            .select('full_name')
            .eq('id', assignedBy)
            .single();
        if (mounted) {
          setState(() {
            _managerName = res['full_name'] ?? "Unknown (User has no name)";
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _managerName = "Unknown (DB Error)";
            debugPrint('Error fetching manager: $e');
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _managerName = "Unknown (Missing 'assigned_by' in task)";
        });
      }
    }
  }

  Future<void> _toggleStatus(bool value) async {
    setState(() => _updating = true);
    final newStatus = value ? 'Completed' : 'Assigned';
    try {
      if (widget.task['id'] != null) {
        await ApiService.updateTaskStatus(widget.task['id'], newStatus);
      }
      setState(() {
        isCompleted = value;
        widget.task['status'] = newStatus;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update: \$e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    String formattedTime = "Unknown Time";
    if (task['scheduled_time'] != null) {
      final dt = DateTime.parse(task['scheduled_time']).toLocal();
      formattedTime = DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
    }

    final trackmanName = task['app_users']?['full_name'] ?? 'Unknown Trackman';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('Task Details', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task["title"] ?? "Unknown Task",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  _infoTile(Icons.location_on, "Location", task["location"] ?? "Unknown"),
                  _infoTile(Icons.schedule, "Scheduled Time", formattedTime),
                  _infoTile(Icons.flag, "Priority", task["priority"] ?? "Normal"),
                  _infoTile(Icons.assignment_turned_in, "Current Status", task["status"] ?? "Assigned"),
                  const Divider(height: 32),
                  _infoTile(Icons.person, "Assigned To", trackmanName),
                  _infoTile(Icons.manage_accounts, "Assigned By", _managerName),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Task Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    task["description"] ?? "No description provided.",
                    style: const TextStyle(height: 1.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              value: isCompleted,
              activeThumbColor: Colors.green,
              title: const Text("Mark Task as Completed", style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: _updating ? const Text("Updating...") : null,
              onChanged: _updating ? null : _toggleStatus,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                isCompleted ? "✅ Task Completed" : "⏳ Task Pending",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}