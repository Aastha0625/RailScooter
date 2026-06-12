import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class TrackmanHistoryScreen extends StatefulWidget {
  const TrackmanHistoryScreen({super.key});

  @override
  State<TrackmanHistoryScreen> createState() => _TrackmanHistoryScreenState();
}

class _TrackmanHistoryScreenState extends State<TrackmanHistoryScreen> {
  bool _loading = true;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Fetch all assignments (active and past) for this specific user
      final data = await Supabase.instance.client
          .from('vehicle_assignments')
          .select('''
            id,
            is_active,
            assigned_at,
            unassigned_at,
            notes,
            vehicles (
              vehicle_id,
              variant
            )
          ''')
          .eq('assigned_user_id', user.id)
          .order('assigned_at', ascending: false);

      if (mounted) {
        setState(() {
          _history = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load history: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Ride History'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _history.isEmpty
              ? const Center(
                  child: Text(
                    'No assignment history found.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    final vehicle = item['vehicles'] ?? {};
                    final isActive = item['is_active'] == true;
                    
                    final assignedAt = DateTime.parse(item['assigned_at']).toLocal();
                    final assignedStr = DateFormat('MMM dd, yyyy - hh:mm a').format(assignedAt);
                    
                    String unassignedStr = 'Present';
                    if (item['unassigned_at'] != null) {
                       final unassignedAt = DateTime.parse(item['unassigned_at']).toLocal();
                       unassignedStr = DateFormat('MMM dd, yyyy - hh:mm a').format(unassignedAt);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.electric_scooter, color: isActive ? Colors.green : AppColors.textSecondary, size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    vehicle['vehicle_id'] ?? 'Unknown Vehicle',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                            vehicle['variant'] ?? '',
                            style: const TextStyle(fontSize: 14, color: AppColors.accent, fontWeight: FontWeight.w600),
                          ),
                          const Divider(height: 24),
                          _buildTimeRow(Icons.play_circle_outline, 'Started', assignedStr),
                          const SizedBox(height: 8),
                          _buildTimeRow(Icons.stop_circle_outlined, 'Ended', unassignedStr),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildTimeRow(IconData icon, String label, String time) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        Text(time, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
