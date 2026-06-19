import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/mock_data_store.dart';

class TrackmanTaskDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const TrackmanTaskDetailsScreen({
    super.key,
    required this.task,
  });

  @override
  State<TrackmanTaskDetailsScreen> createState() =>
      _TrackmanTaskDetailsScreenState();
}

class _TrackmanTaskDetailsScreenState
    extends State<TrackmanTaskDetailsScreen> {
  late bool isCompleted;

  @override
  void initState() {
    super.initState();
    isCompleted = widget.task['status'] == 'Completed';
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Task Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
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
                border: Border.all(
                  color: AppColors.cardBorder,
                ),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task["title"] as String,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _infoTile(
                    Icons.location_on,
                    "Location",
                    task["location"] as String,
                  ),

                  _infoTile(
                    Icons.schedule,
                    "Scheduled Time",
                    task["time"] as String,
                  ),

                  _infoTile(
                    Icons.flag,
                    "Priority",
                    task["priority"] as String,
                  ),

                  _infoTile(
                    Icons.assignment_turned_in,
                    "Current Status",
                    task["status"] as String,
                  ),
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
                border: Border.all(
                  color: AppColors.cardBorder,
                ),
              ),

              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Task Description",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 12),

                  Text(
                    "Inspect the assigned railway infrastructure, verify operational safety standards, identify defects, document findings and update maintenance records. Escalate critical issues immediately to the control room.",
                    style: TextStyle(
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SwitchListTile(
              value: isCompleted,
              activeColor: Colors.green,

              title: const Text(
                "Mark Task as Completed",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

              onChanged: (value) {
                setState(() {
                  isCompleted = value;
                  task['status'] = value ? 'Completed' : 'Assigned';
                });
                if (task['id'] != null) {
                  MockDataStore().updateTaskStatus(task['id'], value ? 'Completed' : 'Assigned');
                }
              },
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),

              child: Text(
                isCompleted
                    ? "✅ Task Completed"
                    : "⏳ Task Pending",

                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCompleted
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),

      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),

                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}