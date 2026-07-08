import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TrackmanHistoryDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> historyItem;

  const TrackmanHistoryDetailsScreen({super.key, required this.historyItem});

  @override
  Widget build(BuildContext context) {
    final vehicle = historyItem['vehicles'] ?? {};
    final isActive = historyItem['is_active'] == true;
    final notes = historyItem['notes'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ride Details'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header map placeholder (if we want a map) or just a solid color background
            Container(
              height: 200,
              color: AppColors.primary.withValues(alpha: 0.1),
              child: const Center(
                child: Icon(Icons.map, size: 64, color: AppColors.primary),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        vehicle['vehicle_id'] ?? 'Unknown Vehicle',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isActive ? 'ACTIVE' : 'COMPLETED',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.green : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  Text(
                    'Variant: ${vehicle['variant'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    "Ride Information",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildDetailRow(Icons.play_circle_outline, "Started At", historyItem['assignedStr'] ?? 'Unknown'),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.stop_circle_outlined, "Ended At", historyItem['unassignedStr'] ?? (isActive ? 'Ongoing' : 'Unknown')),
                  
                  const SizedBox(height: 32),
                  
                  const Text(
                    "Notes",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    (notes != null && notes.isNotEmpty) ? notes : "No notes available for this ride.",
                    style: const TextStyle(
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
