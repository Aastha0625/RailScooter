import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/mock_data_store.dart';
import 'trackman_task_details_screen.dart';
import '../../widgets/custom_app_bar.dart';
import 'trackman_base_screen.dart';

class TrackmanTasksScreen extends StatelessWidget {
  const TrackmanTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TrackmanBaseScreen(
      appBar: const CustomAppBar(title: "My Tasks"),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: MockDataStore().tasks,
        builder: (context, tasks, _) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TrackmanTaskDetailsScreen(task: task),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.cardBorder,
                      ),
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
                          backgroundColor:
                              (task["color"] as Color)
                                  .withValues(alpha: 0.15),
                          radius: 26,
                          child: Icon(
                            task["icon"] as IconData,
                            color: task["color"] as Color,
                            size: 26,
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                task["title"] as String,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                task["location"] as String,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                task["time"] as String,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),

                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  _buildChip(
                                    task["priority"] as String,
                                    task["color"] as Color,
                                  ),

                                  const SizedBox(width: 8),

                                  _buildStatusChip(
                                    task["status"] as String,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  static Widget _buildChip(
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  static Widget _buildStatusChip(
    String status,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}