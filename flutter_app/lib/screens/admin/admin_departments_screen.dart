import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/department.dart';
import '../../services/api_service.dart';
import '../departments/department_detail_sheet.dart';
import 'admin_base_screen.dart';

class AdminDepartmentsScreen extends StatefulWidget {
  const AdminDepartmentsScreen({super.key});

  @override
  State<AdminDepartmentsScreen> createState() => _AdminDepartmentsScreenState();
}

class _AdminDepartmentsScreenState extends State<AdminDepartmentsScreen> {
  List<Department> _departments = [];
  List<Map<String, dynamic>> _assignments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.fetchDepartments(),
        ApiService.fetchAssignments(),
      ]);
      if (mounted) {
        setState(() {
          _departments = results[0] as List<Department>;
          _assignments = results[1] as List<Map<String, dynamic>>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminBaseScreen(
      title: 'Departments',
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : _departments.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.accent,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                          itemCount: _departments.length,
                          itemBuilder: (_, i) {
                            final d = _departments[i];
                            final count = _assignments.where((a) => a['department_id'] == d.id).length;
                            return _DepartmentCard(
                              department: d,
                              assignmentCount: count,
                              onEdit: () => _showDepartmentForm(d),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20, right: 20, bottom: 16,
      ),
      color: AppColors.primary,
      child: Row(
        children: [
          const Icon(Icons.business_outlined, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Departments', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                Text('Manage division assignments', style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 24),
            tooltip: 'Add Department',
            onPressed: () => _showDepartmentForm(null),
          ),
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white70), onPressed: _load),
        ],
      ),
    );
  }

  Widget _buildEmpty() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.business_outlined, size: 56, color: AppColors.textLight),
        SizedBox(height: 12),
        Text('No departments found', style: TextStyle(color: AppColors.textSecondary)),
      ],
    ),
  );

  void _showDepartmentForm(Department? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final headCtrl = TextEditingController(text: existing?.headName ?? '');
    final emailCtrl = TextEditingController(text: existing?.contactEmail ?? '');
    final phoneCtrl = TextEditingController(text: existing?.contactPhone ?? '');
    final locationCtrl = TextEditingController(text: existing?.location ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(existing == null ? Icons.add_business_rounded : Icons.edit_road_rounded, color: AppColors.primary, size: 24),
                      const SizedBox(width: 8),
                      Expanded(child: Text(existing == null ? 'Add Department' : 'Edit Department', style: AppTextStyles.heading2)),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInputField('Department Name *', nameCtrl, validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: 12),
                  _buildInputField('Code *', codeCtrl, hint: 'e.g., MECH', validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: 12),
                  _buildInputField('Head of Department', headCtrl),
                  const SizedBox(height: 12),
                  _buildInputField('Contact Email', emailCtrl),
                  const SizedBox(height: 12),
                  _buildInputField('Contact Phone', phoneCtrl),
                  const SizedBox(height: 12),
                  _buildInputField('Location', locationCtrl),
                  const SizedBox(height: 12),
                  _buildInputField('Description', descCtrl, maxLines: 2),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final data = {
                          'name': nameCtrl.text.trim(),
                          'code': codeCtrl.text.trim().toUpperCase(),
                          'head_name': headCtrl.text.trim(),
                          'contact_email': emailCtrl.text.trim(),
                          'contact_phone': phoneCtrl.text.trim(),
                          'location': locationCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                        };
                        try {
                          if (existing == null) {
                            await ApiService.createDepartment(data);
                            await ApiService.logActivity(
                              eventType: 'other',
                              description: 'Department ${data['code']} was added',
                            );
                          } else {
                            await ApiService.updateDepartment(existing.id, data);
                            await ApiService.logActivity(
                              eventType: 'other',
                              description: 'Department ${existing.code} was edited',
                            );
                          }
                          if (mounted) { Navigator.pop(context); _load(); }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                          }
                        }
                      },
                      child: Text(existing == null ? 'Add Department' : 'Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController ctrl, {String? hint, int maxLines = 1, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(hintText: hint),
          validator: validator,
        ),
      ],
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  final Department department;
  final int assignmentCount;
  final VoidCallback onEdit;

  const _DepartmentCard({
    required this.department,
    required this.assignmentCount,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => DepartmentDetailSheet(department: department),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.business_outlined, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(department.name, style: AppTextStyles.heading3),
                    Text(department.code, style: AppTextStyles.caption.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: onEdit, color: AppColors.textSecondary),
            ],
          ),
          if (department.headName.isNotEmpty || department.location.isNotEmpty) ...[
            const SizedBox(height: 12),
            if (department.headName.isNotEmpty)
              _InfoRow(icon: Icons.person_outline, text: 'Head: ${department.headName}'),
            if (department.location.isNotEmpty)
              _InfoRow(icon: Icons.location_on_outlined, text: 'Location: ${department.location}'),
            if (department.contactPhone.isNotEmpty)
              _InfoRow(icon: Icons.phone_outlined, text: 'Phone: ${department.contactPhone}'),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$assignmentCount vehicle${assignmentCount != 1 ? "s" : ""}',
                    style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textLight),
        const SizedBox(width: 6),
        Text(text, style: AppTextStyles.bodySmall),
      ],
    ),
  );
}
