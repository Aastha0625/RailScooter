import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import 'package:uuid/uuid.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import 'map_picker_screen.dart';
import 'trackman_base_screen.dart';
import '../../services/api_service.dart';

class TrackmanReportIssueScreen extends StatefulWidget {
  const TrackmanReportIssueScreen({super.key});

  @override
  State<TrackmanReportIssueScreen> createState() => _TrackmanReportIssueScreenState();
}

class _TrackmanReportIssueScreenState extends State<TrackmanReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionCtrl = TextEditingController();
  
  String _selectedCategory = 'Vehicle Defect';
  final List<String> _categories = [
    'Vehicle Defect',
    'Track Obstruction',
    'Broken Rail',
    'Software Glitch',
    'Other'
  ];

  String _selectedSeverity = 'Medium';
  final List<String> _severities = ['Low', 'Medium', 'Critical'];

  bool _isSubmitting = false;

  // New features state
  LatLng? _issueLocation;
  File? _imageFile;
  bool _fetchingLocation = false;

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _fetchLiveLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _issueLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  Future<void> _openMapPicker() async {
    LatLng startingLocation = _issueLocation ?? const LatLng(51.509865, -0.118092); // Fallback

    if (_issueLocation == null) {
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
          startingLocation = LatLng(pos.latitude, pos.longitude);
        }
      } catch (_) {}
    }

    if (!mounted) return;
    
    final selected = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLocation: startingLocation,
        ),
      ),
    );
    if (selected != null) {
      setState(() {
        _issueLocation = selected;
      });
    }
  }

  Future<void> _submitIssue() async {
    if (!_formKey.currentState!.validate()) return;
    if (_issueLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide the issue location.'), backgroundColor: Colors.red));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Check active assignment
      final data = await Supabase.instance.client
          .from('vehicle_assignments')
          .select('vehicle_id')
          .eq('assigned_user_id', user.id)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1);

      Map<String, dynamic>? activeAssignment;
      if (data.isNotEmpty) {
        activeAssignment = Map<String, dynamic>.from(data.first);
      }

      String? imageUrl;

      // Upload image if selected
      if (_imageFile != null) {
        final fileName = '${const Uuid().v4()}.jpg';
        final filePath = 'issue_uploads/$fileName';
        
        await Supabase.instance.client.storage
            .from('issue_images')
            .upload(filePath, _imageFile!);
            
        imageUrl = Supabase.instance.client.storage
            .from('issue_images')
            .getPublicUrl(filePath);
      }

      final trackmanData = await ApiService.fetchCurrentUserData();

      await Supabase.instance.client.from('trackman_issues').insert({
        'reporter_id': user.id,
        'vehicle_id': activeAssignment?['vehicle_id'],
        'category': _selectedCategory,
        'severity': _selectedSeverity,
        'description': _descriptionCtrl.text.trim(),
        'status': 'open',
        'location_lat': _issueLocation!.latitude,
        'location_lng': _issueLocation!.longitude,
        'image_url': imageUrl,
        'zone': trackmanData?.zone,
        'division': trackmanData?.division,
        'region': (trackmanData?.regions != null && trackmanData!.regions!.isNotEmpty) 
            ? trackmanData.regions!.first 
            : null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Issue reported successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit issue: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Critical': return AppColors.severityCritical;
      case 'Medium': return AppColors.severityMedium;
      default: return AppColors.statusIdle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TrackmanBaseScreen(
      appBar: const CustomAppBar(title: 'Report Issue'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Log a New Issue',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please provide details, photos, and location of the issue.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Photographic Evidence
              const Text('Photographic Evidence', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(12),
                    image: _imageFile != null
                        ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _imageFile == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, color: AppColors.textLight, size: 32),
                            SizedBox(height: 8),
                            Text('Tap to capture photo', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        )
                      : const Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.check_circle, color: Colors.green, size: 28),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Location Data
              const Text('Issue Location', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _fetchingLocation ? null : _fetchLiveLocation,
                      icon: _fetchingLocation 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.gps_fixed),
                      label: const Text('Live GPS'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openMapPicker,
                      icon: const Icon(Icons.map),
                      label: const Text('Map Pin'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusIdle),
                    ),
                  ),
                ],
              ),
              if (_issueLocation != null) ...[
                const SizedBox(height: 8),
                Text('Location Set: ${_issueLocation!.latitude.toStringAsFixed(4)}, ${_issueLocation!.longitude.toStringAsFixed(4)}', 
                     style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 24),

              // Category
              const Text('Category', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                dropdownColor: Colors.white,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                ),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 24),

              // Severity
              const Text('Severity', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: _severities.map((severity) {
                  final isSelected = _selectedSeverity == severity;
                  final color = _getSeverityColor(severity);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedSeverity = severity),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
                          border: Border.all(color: isSelected ? color : AppColors.cardBorder),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          severity,
                          style: TextStyle(
                            color: isSelected ? color : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Description
              const Text('Description', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Describe the issue in detail...',
                  hintStyle: const TextStyle(color: AppColors.textLight),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please provide a description.';
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitIssue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Submit Issue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isSubmitting ? AppColors.textSecondary : Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
