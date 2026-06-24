import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'trackman_task_details_screen.dart';
import '../../widgets/custom_app_bar.dart';
import 'trackman_base_screen.dart';

class TrackmanTasksScreen extends StatefulWidget {
  const TrackmanTasksScreen({super.key});

  @override
  State<TrackmanTasksScreen> createState() => _TrackmanTasksScreenState();
}

class _TrackmanTasksScreenState extends State<TrackmanTasksScreen> {
  List<Map<String, dynamic>> _tasks = [];
  bool _loading = true;

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
      
      final tasks = await ApiService.fetchTasks(
        assignedToUserId: user.id,
        regions: user.regions,
      );
      if (mounted) {
        setState(() {
          _tasks = tasks;
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

  @override
  Widget build(BuildContext context) {
    return TrackmanBaseScreen(
      appBar: const CustomAppBar(title: "My Tasks"),
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        color: AppColors.primary,
        child: _loading 
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty 
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text("No tasks assigned yet.", style: TextStyle(fontSize: 16, color: AppColors.textLight))),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    
                    String formattedTime = "Unknown Time";
                    if (task['scheduled_time'] != null) {
                      final dt = DateTime.parse(task['scheduled_time']).toLocal();
                      formattedTime = DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
                    }

                    Color pColor = Colors.orange;
                    if (task['priority'] == 'High') pColor = Colors.red;
                    if (task['priority'] == 'Low') pColor = Colors.green;

                    return GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TrackmanTaskDetailsScreen(task: Map<String, dynamic>.from(task)),
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
                                Icons.build,
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
                ),
              ),
      ),
    );
  }
}