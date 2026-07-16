import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_app_bar.dart';
import 'manager_base_screen.dart';
import 'manager_task_details_screen.dart';

class ManagerTasksScreen extends StatefulWidget {
  const ManagerTasksScreen({super.key});

  @override
  State<ManagerTasksScreen> createState() => _ManagerTasksScreenState();
}

class _ManagerTasksScreenState extends State<ManagerTasksScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _filteredTasks = [];
  AppUser? _manager;
  
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    try {
      final user = await ApiService.fetchCurrentUserData();
      if (user == null) throw Exception('Not logged in');
      _manager = user;
      
      final tasks = await ApiService.fetchTasks(
        assignedByUserId: user.id,
      );
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _applyFilter();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load tasks: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _applyFilter() {
    if (_statusFilter == 'All') {
      _filteredTasks = List.from(_tasks);
    } else if (_statusFilter == 'In Progress') {
      _filteredTasks = _tasks.where((t) => t['status'] == 'In Progress' || t['status'] == 'Review Pending').toList();
    } else {
      _filteredTasks = _tasks.where((t) => t['status'] == _statusFilter).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ManagerBaseScreen(
      appBar: const CustomAppBar(title: "Assigned Tasks"),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['All', 'Assigned', 'In Progress', 'On Hold', 'Completed'].map((status) {
                final isSelected = _statusFilter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _statusFilter = status;
                          _applyFilter();
                        });
                      }
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    labelStyle: TextStyle(color: isSelected ? AppColors.primary : AppColors.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTasks,
              color: AppColors.primary,
              child: _loading 
                ? const Center(child: CircularProgressIndicator())
                : _filteredTasks.isEmpty 
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text("No tasks found.", style: TextStyle(fontSize: 16, color: AppColors.textLight))),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = _filteredTasks[index];
                    
                    String formattedTime = "Unknown Time";
                    if (task['scheduled_time'] != null) {
                      final dt = DateTime.parse(task['scheduled_time']).toLocal();
                      formattedTime = DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
                    }

                    Color pColor = Colors.orange;
                    if (task['priority'] == 'High') pColor = Colors.red;
                    if (task['priority'] == 'Low') pColor = Colors.green;

                    final assignedUser = task['app_users']?['full_name'] ?? 'Unassigned';

                    return GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ManagerTaskDetailsScreen(task: Map<String, dynamic>.from(task)),
                          ),
                        );
                        if (result == true) {
                          _loadTasks();
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: pColor.withValues(alpha: 0.15),
                              radius: 26,
                              child: Icon(
                                Icons.assignment_outlined,
                                color: pColor,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task["title"] ?? 'Unknown Task',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    task["location"] ?? 'Unknown Location',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        assignedUser,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formattedTime,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: pColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          task["priority"] ?? 'Normal',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: pColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          task["status"] ?? 'Assigned',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppColors.textLight,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ), // Closes ListView.builder
              ), // Closes Padding
            ), // Closes RefreshIndicator
          ), // Closes Expanded
        ], // Closes children
      ), // Closes Column
    ); // Closes ManagerBaseScreen
  }
}
