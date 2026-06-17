import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';

class ManagerDispatchHistoryScreen extends StatefulWidget {
  const ManagerDispatchHistoryScreen({super.key});

  @override
  State<ManagerDispatchHistoryScreen> createState() => _ManagerDispatchHistoryScreenState();
}

class _ManagerDispatchHistoryScreenState extends State<ManagerDispatchHistoryScreen> {
  bool _loading = true;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final data = await Supabase.instance.client
          .from('vehicle_assignments')
          .select('''
            id,
            assigned_at,
            unassigned_at,
            is_active,
            app_users:assigned_user_id (id, full_name, employee_id),
            vehicles:vehicle_id (id, vehicle_id, variant)
          ''')
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading history: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dispatch History', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _history.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchHistory,
                  color: AppColors.accent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final dispatch = _history[index];
                      return _buildHistoryCard(dispatch);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined, size: 64, color: AppColors.textLight),
          const SizedBox(height: 16),
          const Text('No Dispatch History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('There are no recorded dispatches yet.', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(dynamic dispatch) {
    final trackman = dispatch['app_users'];
    final vehicle = dispatch['vehicles'];
    
    final assignedAt = DateTime.parse(dispatch['assigned_at']).toLocal();
    final isOngoing = dispatch['is_active'] == true;
    
    DateTime? unassignedAt;
    String durationText = 'Ongoing';
    
    if (!isOngoing && dispatch['unassigned_at'] != null) {
      unassignedAt = DateTime.parse(dispatch['unassigned_at']).toLocal();
      final diff = unassignedAt.difference(assignedAt);
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      if (hours > 0) {
        durationText = '${hours}h ${minutes}m';
      } else {
        durationText = '${minutes}m';
      }
    }
    
    final formattedDate = '${assignedAt.day.toString().padLeft(2, '0')}/${assignedAt.month.toString().padLeft(2, '0')}/${assignedAt.year}';
    final timeStr = '${assignedAt.hour.toString().padLeft(2, '0')}:${assignedAt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isOngoing ? Colors.green.withValues(alpha: 0.1) : AppColors.textLight.withValues(alpha: 0.1), 
                    shape: BoxShape.circle
                  ),
                  child: Icon(Icons.person, color: isOngoing ? Colors.green : AppColors.textSecondary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trackman != null ? trackman['full_name'] : 'Unknown Trackman', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                      Text('ID: ${trackman != null ? (trackman['employee_id'] ?? 'N/A') : 'N/A'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOngoing ? Colors.green.withValues(alpha: 0.1) : AppColors.textLight.withValues(alpha: 0.1), 
                    borderRadius: BorderRadius.circular(20)
                  ),
                  child: Text(isOngoing ? 'ACTIVE' : 'COMPLETED', style: TextStyle(color: isOngoing ? Colors.green : AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Vehicle', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.electric_scooter, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(vehicle != null ? vehicle['vehicle_id'] : 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dispatched At', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('$formattedDate $timeStr', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Duration', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                    const SizedBox(height: 4),
                    Text(durationText, style: TextStyle(fontWeight: FontWeight.bold, color: isOngoing ? AppColors.accent : AppColors.textSecondary)),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
