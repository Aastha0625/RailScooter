import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import 'manager_base_screen.dart';

class ManagerDispatchScreen extends StatefulWidget {
  const ManagerDispatchScreen({super.key});

  @override
  State<ManagerDispatchScreen> createState() => _ManagerDispatchScreenState();
}

class _ManagerDispatchScreenState extends State<ManagerDispatchScreen> {
  bool _loading = true;
  List<dynamic> _activeDispatches = [];

  @override
  void initState() {
    super.initState();
    _fetchActiveDispatches();
  }

  Future<void> _fetchActiveDispatches() async {
    try {
      final data = await Supabase.instance.client
          .from('vehicle_assignments')
          .select('''
            id,
            assigned_at,
            app_users:assigned_user_id (id, full_name, employee_id),
            vehicles:vehicle_id (id, vehicle_id, status)
          ''')
          .eq('is_active', true)
          .order('assigned_at', ascending: false);

      if (mounted) {
        setState(() {
          _activeDispatches = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading dispatches: $e')));
      }
    }
  }

  Future<void> _recallVehicle(String assignmentId) async {
    try {
      await Supabase.instance.client
          .from('vehicle_assignments')
          .update({
            'is_active': false,
            'unassigned_at': DateTime.now().toIso8601String()
          })
          .eq('id', assignmentId);

      _fetchActiveDispatches();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vehicle successfully recalled.'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error recalling vehicle: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _showNewDispatchDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _NewDispatchDialog(),
    ).then((value) {
      if (value == true) {
        _fetchActiveDispatches();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ManagerBaseScreen(
      appBar: const CustomAppBar(title: 'Dispatch Vehicles'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _activeDispatches.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _activeDispatches.length,
                  itemBuilder: (context, index) {
                    final dispatch = _activeDispatches[index];
                    return _buildDispatchCard(dispatch);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewDispatchDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.send_rounded, color: Colors.white),
        label: const Text('New Dispatch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_filled_outlined, size: 64, color: AppColors.textLight),
          SizedBox(height: 16),
          Text('No Active Dispatches', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          SizedBox(height: 8),
          Text('All vehicles are currently idle.', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildDispatchCard(dynamic dispatch) {
    final trackman = dispatch['app_users'];
    final vehicle = dispatch['vehicles'];
    
    // Parse the assigned_at timestamp
    final assignedAt = DateTime.parse(dispatch['assigned_at']).toLocal();
    final timeStr = '${assignedAt.hour.toString().padLeft(2, '0')}:${assignedAt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.person, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trackman != null ? trackman['full_name'] : 'Unknown Trackman', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text('Assigned at $timeStr', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: const Text('ON DUTY', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.electric_scooter, color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 6),
                    Text(vehicle != null ? vehicle['vehicle_id'] : 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 13)),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.battery_charging_full, color: AppColors.statusActive, size: 18),
                    const SizedBox(width: 4),
                    Text('${vehicle?['battery_level'] ?? 100}%', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.statusActive, fontSize: 13)),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _recallVehicle(dispatch['id']),
                  icon: const Icon(Icons.settings_backup_restore, color: AppColors.severityCritical, size: 16),
                  label: const Text('Recall', style: TextStyle(color: AppColors.severityCritical, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _NewDispatchDialog extends StatefulWidget {
  const _NewDispatchDialog();

  @override
  State<_NewDispatchDialog> createState() => _NewDispatchDialogState();
}

class _NewDispatchDialogState extends State<_NewDispatchDialog> {
  bool _loading = true;
  bool _submitting = false;
  List<AppUser> _availableTrackmen = [];
  List<dynamic> _availableVehicles = [];
  
  String? _selectedTrackmanId;
  String? _selectedVehicleId;

  @override
void initState() {
    super.initState();
    _fetchOptions();
  }

  Future<void> _fetchOptions() async {
    try {
      final manager = await ApiService.fetchCurrentUserData();
      
      // Fetch Trackmen (filter by manager's division and only approved trackmen via ApiService)
      final trackmenData = await ApiService.fetchUsers(division: manager?.division, role: 'trackman');

      // Fetch Vehicles
      final vehiclesData = await Supabase.instance.client
          .from('vehicles')
          .select('id, vehicle_id')
          .inFilter('status', ['idle', 'active']);

      // Fetch Active Assignments to filter out busy ones
      final activeAssignments = await Supabase.instance.client
          .from('vehicle_assignments')
          .select('assigned_user_id, vehicle_id')
          .eq('is_active', true);

      final busyTrackmenIds = activeAssignments.map((a) => a['assigned_user_id'] as String).toSet();
      final busyVehicleIds = activeAssignments.map((a) => a['vehicle_id'] as String).toSet();

      setState(() {
        _availableTrackmen = trackmenData.where((t) => !busyTrackmenIds.contains(t.id)).toList();
        _availableVehicles = vehiclesData.where((v) => !busyVehicleIds.contains(v['id'])).toList();
        
        if (_availableTrackmen.isNotEmpty) _selectedTrackmanId = _availableTrackmen.first.id;
        if (_availableVehicles.isNotEmpty) _selectedVehicleId = _availableVehicles.first['id'];
        
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading options: $e')));
      }
    }
  }

  Future<void> _createDispatch() async {
    if (_selectedTrackmanId == null || _selectedVehicleId == null) return;
    
    setState(() => _submitting = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      
      await Supabase.instance.client.from('vehicle_assignments').insert({
        'vehicle_id': _selectedVehicleId,
        'assigned_user_id': _selectedTrackmanId,
        'assigned_by': user?.id,
        'is_active': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dispatch successful!'), backgroundColor: Colors.green));
        Navigator.pop(context, true); // true indicates success to refresh parent
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create dispatch: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Vehicle Dispatch', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: _loading
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_availableTrackmen.isEmpty || _availableVehicles.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Cannot create dispatch. Make sure there is at least one idle Trackman and one idle Vehicle available.', style: TextStyle(color: Colors.orange, fontSize: 13)),
                  )
                else ...[
                  const Text('Select Trackman', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedTrackmanId,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                    ),
                    items: _availableTrackmen.map<DropdownMenuItem<String>>((t) => DropdownMenuItem<String>(value: t.id, child: Text(t.fullName))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedTrackmanId = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Vehicle', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedVehicleId,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                    ),
                    items: _availableVehicles.map((v) => DropdownMenuItem<String>(value: v['id'], child: Text(v['vehicle_id']))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedVehicleId = val);
                    },
                  ),
                ],
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: (_availableTrackmen.isEmpty || _availableVehicles.isEmpty || _submitting) ? null : _createDispatch,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: _submitting 
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Dispatch'),
        ),
      ],
    );
  }
}
