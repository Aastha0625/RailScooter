import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final AppUser user;
  final VoidCallback onUpdated;

  const AdminUserDetailScreen({
    super.key,
    required this.user,
    required this.onUpdated,
  });

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _empIdCtrl;
  late TextEditingController _phoneCtrl;
  late String _selectedRole;
  bool _saving = false;
  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.user.fullName);
    _empIdCtrl = TextEditingController(text: widget.user.employeeId ?? '');
    _phoneCtrl = TextEditingController(text: widget.user.phone);
    _selectedRole   = widget.user.role;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _empIdCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiService.updateUserDetails(widget.user.id, {
        'full_name':    _nameCtrl.text.trim(),
        'employee_id':  _empIdCtrl.text.trim().isEmpty ? null : _empIdCtrl.text.trim(),
        'phone':        _phoneCtrl.text.trim(),
        'role':         _selectedRole,
      });
      await ApiService.logActivity(
        eventType: 'user_edited',
        description: '${widget.user.fullName}\'s profile was updated',
      );
      if (mounted) {
        widget.onUpdated();
        Navigator.pop(context); // Close the detail screen on save
      }
    } catch (e) {
      if (mounted) {
        String errMsg = e.toString();
        if (e is PostgrestException) errMsg = '${e.message} (Code: ${e.code}, Details: ${e.details})';
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error'),
            content: Text(errMsg),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleSuspend() async {
    final action = widget.user.isActive ? 'Suspend' : 'Reactivate';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$action ${widget.user.fullName}?',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          widget.user.isActive
              ? 'This user will lose access to the app immediately.'
              : 'This user will regain access to the app.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.user.isActive ? AppColors.severityCritical : AppColors.statusActive,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (widget.user.isActive) {
      await ApiService.suspendUser(widget.user.id);
      await ApiService.logActivity(eventType: 'user_suspended', description: '${widget.user.fullName} was suspended');
    } else {
      await ApiService.reactivateUser(widget.user.id);
      await ApiService.logActivity(eventType: 'user_reactivated', description: '${widget.user.fullName} was reactivated');
    }
    if (mounted) {
      widget.onUpdated();
      Navigator.pop(context);
    }
  }
  
  Future<void> _deleteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete ${widget.user.fullName}?',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.severityCritical)),
        content: const Text(
          'This action is permanent and cannot be undone. All data related to this user will be removed.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.severityCritical),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    
    setState(() => _saving = true);
    try {
      await ApiService.deleteUser(widget.user.id);
      await ApiService.logActivity(eventType: 'user_deleted', description: '${widget.user.fullName} was permanently deleted');
      if (mounted) {
        widget.onUpdated();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted successfully.')));
      }
    } catch (e) {
      if (mounted) {
        String errMsg = e.toString();
        if (e is PostgrestException) errMsg = '${e.message} (Code: ${e.code}, Details: ${e.details})';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $errMsg', maxLines: 5), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  
  Future<void> _approve() async {
    setState(() => _saving = true);
    try {
      await ApiService.updateUserApproval(widget.user.id, 'approved');
      if (mounted) {
        widget.onUpdated();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User approved.')));
      }
    } catch (e) {
      if (mounted) {
        String errMsg = e.toString();
        if (e is PostgrestException) errMsg = '${e.message} (Code: ${e.code}, Details: ${e.details})';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $errMsg', maxLines: 5), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _saving = true);
    try {
      await ApiService.updateUserApproval(widget.user.id, 'rejected');
      if (mounted) {
        widget.onUpdated();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User rejected.')));
      }
    } catch (e) {
      if (mounted) {
        String errMsg = e.toString();
        if (e is PostgrestException) errMsg = '${e.message} (Code: ${e.code}, Details: ${e.details})';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $errMsg', maxLines: 5), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('User Details', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_editMode ? Icons.check : Icons.edit_outlined, color: AppColors.primary),
            onPressed: () {
              if (_editMode) {
                // If turning off edit mode without saving, reset fields to original
                setState(() {
                  _editMode = false;
                  _nameCtrl.text = widget.user.fullName;
                  _empIdCtrl.text = widget.user.employeeId ?? '';
                  _phoneCtrl.text = widget.user.phone;
                  _selectedRole = widget.user.role;
                });
              } else {
                setState(() => _editMode = true);
              }
            },
            tooltip: _editMode ? 'Cancel Edit' : 'Edit User',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          widget.user.fullName.isNotEmpty ? widget.user.fullName[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.user.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                              widget.user.isActive ? '● Active' : '● Suspended',
                              style: TextStyle(
                                fontSize: 13,
                                color: widget.user.isActive ? AppColors.statusActive : AppColors.severityCritical,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.user.approvalStatus == 'pending') ...[
                        OutlinedButton.icon(
                          icon: const Icon(Icons.check_circle, color: AppColors.statusActive, size: 20),
                          label: const Text('Approve', style: TextStyle(color: AppColors.statusActive)),
                          onPressed: _approve,
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.cancel, color: AppColors.severityCritical, size: 20),
                          label: const Text('Reject', style: TextStyle(color: AppColors.severityCritical)),
                          onPressed: _reject,
                        ),
                      ] else
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: widget.user.isActive 
                                ? AppColors.severityCritical.withOpacity(0.1) 
                                : AppColors.statusActive.withOpacity(0.1),
                            foregroundColor: widget.user.isActive 
                                ? AppColors.severityCritical 
                                : AppColors.statusActive,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          icon: Icon(
                            widget.user.isActive ? Icons.block_rounded : Icons.restore_rounded,
                            size: 18,
                          ),
                          label: Text(
                            widget.user.isActive ? 'Suspend' : 'Reactivate',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onPressed: _toggleSuspend,
                        ),
                      
                      if (!widget.user.isActive) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          style: IconButton.styleFrom(backgroundColor: AppColors.severityCritical.withOpacity(0.1)),
                          icon: const Icon(Icons.delete_forever, color: AppColors.severityCritical, size: 24),
                          onPressed: _deleteUser,
                          tooltip: 'Delete User',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Details Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Registration Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  _infoRow(Icons.wc_outlined, 'Gender', widget.user.gender),
                  _infoRow(Icons.map_outlined, 'Zone', widget.user.zone),
                  _infoRow(Icons.location_city_outlined, 'Division', widget.user.division),
                  _infoRow(Icons.add_road_outlined, 'Regions',
                      (widget.user.regions != null && widget.user.regions!.isNotEmpty)
                          ? widget.user.regions!.join(', ')
                          : null),
                  
                  if (_editMode) ...[
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 24),
                    const Text('Edit Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 16),
                    _field('Full Name', _nameCtrl, Icons.person_outline),
                    const SizedBox(height: 12),
                    _field('Employee ID', _empIdCtrl, Icons.badge_outlined),
                    const SizedBox(height: 12),
                    _field('Phone', _phoneCtrl, Icons.phone_outlined),
                    const SizedBox(height: 12),
                    _label('Role'),
                    const SizedBox(height: 6),
                    _dropdown<String>(
                      value: _selectedRole,
                      items: const ['admin', 'manager', 'trackman'],
                      display: (v) => v.capitalize(),
                      onChanged: (v) => setState(() => _selectedRole = v!),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Save Changes'),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    _infoRow(Icons.person_outline, 'Full Name', widget.user.fullName),
                    _infoRow(Icons.badge_outlined, 'Employee ID', widget.user.employeeId),
                    _infoRow(Icons.phone_outlined, 'Phone', widget.user.phone),
                    _infoRow(Icons.shield_outlined, 'Role', widget.user.role.capitalize()),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label(label),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 18, color: AppColors.textLight),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    ],
  );

  Widget _label(String text) => Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary));

  Widget _infoRow(IconData icon, String label, String? value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textLight),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                (value != null && value.isNotEmpty) ? value : '—',
                style: TextStyle(
                  fontSize: 14,
                  color: (value != null && value.isNotEmpty) ? AppColors.textPrimary : AppColors.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) display,
    required ValueChanged<T?> onChanged,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.textLight.withOpacity(0.5)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        items: items.map((i) => DropdownMenuItem<T>(value: i, child: Text(display(i), style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: onChanged,
      ),
    ),
  );
}

extension on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
