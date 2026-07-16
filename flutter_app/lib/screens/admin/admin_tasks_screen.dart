import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'admin_task_details_screen.dart';
import 'admin_base_screen.dart';

class AdminTasksScreen extends StatefulWidget {
  final String initialFilter;
  const AdminTasksScreen({super.key, this.initialFilter = 'all'});

  @override
  State<AdminTasksScreen> createState() => _AdminTasksScreenState();
}

class _AdminTasksScreenState extends State<AdminTasksScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _tasks = [];
  late String _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await ApiService.fetchTasks(); // Fetches all without filtering
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tasks: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredTasks {
    if (_filter == 'all') return _tasks;
    if (_filter == 'Pending') return _tasks.where((t) => t['status'] == 'Assigned' || t['status'] == 'Pending').toList();
    if (_filter == 'Completed') return _tasks.where((t) => t['status'] == 'Completed').toList();
    return _tasks;
  }

  @override
  Widget build(BuildContext context) {
    return AdminBaseScreen(
      title: 'All Tasks',
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTasks,
              color: AppColors.accent,
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                  : _filteredTasks.isEmpty
                      ? const Center(
                          child: Text('No tasks found.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: _filteredTasks.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final task = _filteredTasks[index];
                            return _buildTaskCard(task);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Text('Filter:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filter,
                isDense: true,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Tasks')),
                  DropdownMenuItem(value: 'Pending', child: Text('Pending & Assigned')),
                  DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _filter = val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final trackmanName = task['app_users']?['full_name'] ?? 'Unassigned';
    final vehicleId = task['vehicles']?['vehicle_id'] ?? 'No Vehicle';
    final isCompleted = task['status'] == 'Completed';

    String formattedTime = "Unknown Time";
    if (task['scheduled_time'] != null) {
      final dt = DateTime.parse(task['scheduled_time']).toLocal();
      formattedTime = DateFormat('MMM dd, hh:mm a').format(dt);
    }

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AdminTaskDetailsScreen(task: task)),
        );
        if (result == true) {
          _loadTasks();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task['title'] ?? 'Unnamed Task',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    task['status'] ?? 'Assigned',
                    style: TextStyle(
                      color: isCompleted ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppColors.textLight),
                const SizedBox(width: 6),
                Text('Trackman: $trackmanName', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.electric_scooter, size: 16, color: AppColors.textLight),
                const SizedBox(width: 6),
                Text('Vehicle: $vehicleId', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.flag, size: 16, color: AppColors.textLight),
                const SizedBox(width: 6),
                Text(task['priority'] ?? 'Normal', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const Spacer(),
                const Icon(Icons.schedule, size: 16, color: AppColors.textLight),
                const SizedBox(width: 6),
                Text(formattedTime, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
