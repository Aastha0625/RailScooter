import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AdminTaskDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const AdminTaskDetailsScreen({
    super.key,
    required this.task,
  });

  @override
  State<AdminTaskDetailsScreen> createState() => _AdminTaskDetailsScreenState();
}

class _AdminTaskDetailsScreenState extends State<AdminTaskDetailsScreen> {
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
        if (value) {
          await ApiService.sendBroadcast(
            title: 'Task Completed',
            body: 'Admin approved and completed the task "${widget.task['title']}".',
            targetRole: 'trackman',
            taskId: widget.task['id'],
          );
        }
      }
      setState(() {
        isCompleted = value;
        widget.task['status'] = newStatus;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to permanently delete this task?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _updating = true);
      try {
        await Supabase.instance.client.from('trackman_tasks').delete().eq('id', widget.task['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task deleted successfully'), backgroundColor: Colors.green));
          Navigator.pop(context, true); // return true to refresh
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete task: $e'), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) setState(() => _updating = false);
      }
    }
  }

  Future<void> _editTask() async {
    final titleController = TextEditingController(text: widget.task['title']);
    final descController = TextEditingController(text: widget.task['description']);
    String priority = widget.task['priority'] ?? 'Normal';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Edit Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: priority,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: ['Low', 'Normal', 'High', 'Urgent'].map((p) {
                        return DropdownMenuItem(value: p, child: Text(p));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => priority = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );

    if (result == true) {
      setState(() => _updating = true);
      try {
        await Supabase.instance.client.from('trackman_tasks').update({
          'title': titleController.text,
          'description': descController.text,
          'priority': priority,
        }).eq('id', widget.task['id']);
        
        setState(() {
          widget.task['title'] = titleController.text;
          widget.task['description'] = descController.text;
          widget.task['priority'] = priority;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task updated successfully'), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update task: $e'), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) setState(() => _updating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    LatLng? _taskLocation;
    final locStr = task['location'] ?? '';
    if (locStr.contains(',')) {
      final parts = locStr.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0].trim());
        final lng = double.tryParse(parts[1].trim());
        if (lat != null && lng != null) {
          _taskLocation = LatLng(lat, lng);
        }
      }
    }

    String formattedTime = "Unknown Time";
    if (task['scheduled_time'] != null) {
      final dt = DateTime.parse(task['scheduled_time']).toLocal();
      formattedTime = DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
    }

    final trackmanName = task['app_users']?['full_name'] ?? 'Unknown Trackman';

    String vehicleName = "No Vehicle Assigned";
    if (task['vehicles'] != null) {
      final vId = task['vehicles']['vehicle_id'] ?? '';
      final vVar = task['vehicles']['variant'] ?? '';
      vehicleName = "$vId $vVar".trim();
      if (vehicleName.isEmpty) vehicleName = "Unknown Vehicle";
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('Task Details', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _editTask,
            tooltip: 'Edit Task',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteTask,
            tooltip: 'Delete Task',
          ),
        ],
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
                  if (_taskLocation != null) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text("Task Location", style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            FlutterMap(
                              options: MapOptions(
                                initialCenter: _taskLocation,
                                initialZoom: 15.0,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.none,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.railscooter',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _taskLocation,
                                      width: 40,
                                      height: 40,
                                      alignment: Alignment.topCenter,
                                      child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Positioned.fill(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        insetPadding: const EdgeInsets.all(16),
                                        backgroundColor: Colors.transparent,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(16),
                                              child: SizedBox(
                                                width: double.infinity,
                                                height: MediaQuery.of(context).size.height * 0.7,
                                                child: FlutterMap(
                                                  options: MapOptions(
                                                    initialCenter: _taskLocation!,
                                                    initialZoom: 15.0,
                                                  ),
                                                  children: [
                                                    TileLayer(
                                                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                                      userAgentPackageName: 'com.example.railscooter',
                                                    ),
                                                    MarkerLayer(
                                                      markers: [
                                                        Marker(
                                                          point: _taskLocation!,
                                                          width: 40,
                                                          height: 40,
                                                          alignment: Alignment.topCenter,
                                                          child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: -10,
                                              right: -10,
                                              child: IconButton(
                                                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                                onPressed: () => Navigator.pop(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.fullscreen, size: 16, color: AppColors.primary),
                                    SizedBox(width: 4),
                                    Text("Expand Map", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    _infoTile(Icons.location_on, "Location", task["location"] ?? "Unknown"),
                  ],
                  _infoTile(Icons.schedule, "Scheduled Time", formattedTime),
                  _infoTile(Icons.flag, "Priority", task["priority"] ?? "Normal"),
                  _infoTile(Icons.assignment_turned_in, "Current Status", task["status"] ?? "Assigned"),
                  _infoTile(Icons.electric_scooter, "Assigned Vehicle", vehicleName),
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
            if (task['subtasks'] != null && (task['subtasks'] as List).isNotEmpty) ...[
              const SizedBox(height: 24),
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
                    const Text("Checklist", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...(task['subtasks'] as List).map((st) {
                      bool checked = st['is_completed'] == true;
                      return Row(
                        children: [
                          Icon(checked ? Icons.check_box : Icons.check_box_outline_blank, color: checked ? Colors.green : Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(child: Text(st['title'], style: TextStyle(color: checked ? AppColors.textSecondary : AppColors.textPrimary, decoration: checked ? TextDecoration.lineThrough : null))),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
            if (task['completion_photo_url'] != null || task['completion_notes'] != null) ...[
              const SizedBox(height: 24),
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
                    const Text("Proof of Completion", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (task['completion_notes'] != null && task['completion_notes'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text("Notes: ${task['completion_notes']}", style: const TextStyle(color: AppColors.textPrimary)),
                      ),
                    if (task['completion_photo_url'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(task['completion_photo_url'], width: double.infinity, height: 200, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Text("Failed to load photo", style: TextStyle(color: Colors.red))),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (task['status'] == 'Review Pending')
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _updating ? null : () => _toggleStatus(true),
                  icon: _updating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.verified, color: Colors.white),
                  label: Text(_updating ? "Approving..." : "Approve & Complete Task", style: const TextStyle(color: Colors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              )
            else if (task['status'] == 'Completed')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                child: const Text("✅ Task Approved & Completed", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                child: Text("⏳ Task Status: ${task['status']}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
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
