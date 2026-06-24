import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';
import '../../models/vehicle.dart';
import '../../services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManagerTaskAssignmentScreen extends StatefulWidget {
  const ManagerTaskAssignmentScreen({super.key});

  @override
  State<ManagerTaskAssignmentScreen> createState() => _ManagerTaskAssignmentScreenState();
}

class _ManagerTaskAssignmentScreenState extends State<ManagerTaskAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  List<AppUser> _trackmen = [];
  List<Vehicle> _vehicles = [];
  List<Map<String, dynamic>> _assignments = [];
  bool _loading = true;
  bool _submitting = false;

  AppUser? _selectedTrackman;
  Vehicle? _selectedVehicle;
  String _priority = 'High';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  AppUser? _currentManager;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final manager = await ApiService.fetchCurrentUserData();
      final results = await Future.wait([
        ApiService.fetchUsers(division: manager?.division, role: 'trackman'),
        ApiService.fetchVehicles(),
        ApiService.fetchAssignments(),
      ]);
      
      if (mounted) {
        setState(() {
          _currentManager = manager;
          _trackmen = results[0] as List<AppUser>;
          _vehicles = results[1] as List<Vehicle>;
          _assignments = results[2] as List<Map<String, dynamic>>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onTrackmanSelected(AppUser? user) {
    setState(() {
      _selectedTrackman = user;
      _selectedVehicle = null;
      if (user != null) {
        // Find if this trackman already has an assigned vehicle
        final activeAssignment = _assignments.where((a) => a['assigned_user_id'] == user.id && a['unassigned_at'] == null).firstOrNull;
        if (activeAssignment != null) {
          final vid = activeAssignment['vehicle_id'];
          _selectedVehicle = _vehicles.where((v) => v.id == vid).firstOrNull;
        }
      }
    });
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTrackman == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Trackman.'), backgroundColor: Colors.orange));
      return;
    }
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Vehicle.'), backgroundColor: Colors.orange));
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Scheduled Date and Time.'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _submitting = true);

    try {
      // Create date time object
      final scheduledTime = DateTime(
        _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
        _selectedTime!.hour, _selectedTime!.minute,
      );

      final taskData = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'assigned_to': _selectedTrackman!.id,
        'vehicle_id': _selectedVehicle!.id,
        'location': _locationCtrl.text.trim(),
        'priority': _priority,
        'scheduled_time': scheduledTime.toUtc().toIso8601String(),
        'status': 'Assigned',
        'assigned_by': Supabase.instance.client.auth.currentUser?.id,
        'zone': _currentManager?.zone,
        'division': _currentManager?.division,
        'region': (_selectedTrackman?.regions != null && _selectedTrackman!.regions!.isNotEmpty) 
            ? _selectedTrackman!.regions!.first 
            : null,
      };

      try {
        await ApiService.createTask(taskData);
      } catch (e) {
        if (e.toString().contains('assigned_by') || e.toString().contains('column')) {
          taskData.remove('assigned_by');
          await ApiService.createTask(taskData);
        } else {
          rethrow;
        }
      }

      // We should check if we need to create a new vehicle assignment
      final hasActiveAssignment = _assignments.any((a) => a['assigned_user_id'] == _selectedTrackman!.id && a['vehicle_id'] == _selectedVehicle!.id && a['unassigned_at'] == null);
      
      if (!hasActiveAssignment) {
        // If the vehicle isn't currently assigned to them, we do it now.
        await ApiService.createAssignment(
          vehicleId: _selectedVehicle!.id,
          assignedUserId: _selectedTrackman!.id,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task assigned successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to assign task: \$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _fetchLiveLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        }
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied.')));
      }
      return;
    } 

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fetching location...')));
    }
    
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _locationCtrl.text = '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Assign New Task'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Task Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  
                  _buildTextField(_titleCtrl, 'Task Title', Icons.title, 'Enter a clear task title'),
                  const SizedBox(height: 16),
                  _buildTextField(_descCtrl, 'Description', Icons.description, 'Describe the task requirements...', maxLines: 3),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _locationCtrl, 
                    'Location', 
                    Icons.location_on, 
                    'e.g. Northern Sector B',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.my_location, color: AppColors.accent),
                      onPressed: _fetchLiveLocation,
                      tooltip: 'Get Live GPS',
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  const Text('Assignment Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  
                  _buildDropdown<AppUser>(
                    value: _selectedTrackman,
                    hint: 'Select Trackman',
                    icon: Icons.person,
                    items: _trackmen.map((u) => DropdownMenuItem(value: u, child: Text(u.fullName))).toList(),
                    onChanged: _onTrackmanSelected,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildDropdown<Vehicle>(
                    value: _selectedVehicle,
                    hint: _selectedTrackman == null ? 'Select Trackman first' : 'Select Vehicle',
                    icon: Icons.electric_scooter,
                    items: _vehicles.map((v) {
                      // Optionally indicate if it's the already assigned one
                      bool isAssigned = _assignments.any((a) => a['assigned_user_id'] == _selectedTrackman?.id && a['vehicle_id'] == v.id && a['unassigned_at'] == null);
                      return DropdownMenuItem(
                        value: v, 
                        child: Text('${v.vehicleId} (${v.variant})${isAssigned ? " - Current" : ""}'),
                      );
                    }).toList(),
                    onChanged: _selectedTrackman == null ? null : (v) => setState(() => _selectedVehicle = v),
                  ),
                  
                  const SizedBox(height: 32),
                  const Text('Schedule & Priority', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),

                  _buildDropdown<String>(
                    value: _priority,
                    hint: 'Priority',
                    icon: Icons.flag,
                    items: ['High', 'Medium', 'Low'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (v) => setState(() => _priority = v!),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder)),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                                const SizedBox(width: 12),
                                Text(_selectedDate == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(_selectedDate!), style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: _pickTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder)),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, color: AppColors.primary, size: 20),
                                const SizedBox(width: 12),
                                Text(_selectedTime == null ? 'Select Time' : _selectedTime!.format(context), style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                  
                  ElevatedButton(
                    onPressed: _submitting ? null : _submitTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _submitting
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Assign Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, String hint, {int maxLines = 1, Widget? suffixIcon}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      validator: (v) => v == null || v.trim().isEmpty ? 'Required field' : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: (v) => v == null ? 'Required selection' : null,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
      ),
    );
  }
}
