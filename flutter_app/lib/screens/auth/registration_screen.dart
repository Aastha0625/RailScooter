import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  int _currentStep = 1;
  bool _loading = false;
  String? _error;
  String? _message;

  // Step 1 Controllers
  final _formKey1 = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _gender = 'Male';

  // Step 2 Controllers
  final _formKey2 = GlobalKey<FormState>();
  String _jobRole = 'Trackman';
  String _zone = 'North Western Railway';
  String _division = 'Bikaner';
  List<String> _selectedRegions = [];
  final _empIdCtrl = TextEditingController();

  final Color bgColor = const Color(0xFF0A1118);
  final Color glowColor = const Color(0xFFF97316);

  final List<String> _roles = ['Admin', 'Manager', 'Trackman'];
  final List<String> _zones = ['North Western Railway', 'Northern Railway', 'Central Railway', 'Western Railway'];
  
  final Map<String, List<String>> _zoneDivisions = {
    'North Western Railway': ['Bikaner', 'Jaipur', 'Jodhpur', 'Ajmer'],
    'Northern Railway': ['Delhi', 'Ambala', 'Firozpur', 'Lucknow', 'Moradabad'],
    'Central Railway': ['Mumbai', 'Bhusawal', 'Pune', 'Solapur', 'Nagpur'],
    'Western Railway': ['Mumbai Central', 'Vadodara', 'Ahmedabad', 'Ratlam', 'Rajkot', 'Bhavnagar'],
  };

  final Map<String, List<String>> _divisionRegions = {
    'Bikaner': ['Bikaner City', 'Suratgarh', 'Hanumangarh', 'Churu', 'Rewari'],
    'Jaipur': ['Jaipur City', 'Phulera', 'Bandikui', 'Sikar', 'Alwar'],
    'Jodhpur': ['Jodhpur City', 'Pali Marwar', 'Jaisalmer', 'Barmer', 'Merta Road'],
    'Ajmer': ['Ajmer City', 'Bhilwara', 'Udaipur', 'Abu Road', 'Marwar Junction'],
  };

  List<String> get _currentDivisions => _zoneDivisions[_zone] ?? ['General Division'];
  List<String> get _currentRegions => _divisionRegions[_division] ?? ['Region 1', 'Region 2', 'Region 3'];

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _empIdCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (!_formKey1.currentState!.validate()) return;
      setState(() {
        _error = null;
        _currentStep++;
      });
    }
  }

  void _prevStep() {
    setState(() {
      _error = null;
      _currentStep--;
    });
  }

  Future<void> _submit() async {
    if (!_formKey2.currentState!.validate()) return;
    if (_selectedRegions.isEmpty) {
      setState(() => _error = "Please select at least one region.");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        data: {
          'full_name': '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
          'first_name': _firstNameCtrl.text.trim(),
          'last_name': _lastNameCtrl.text.trim(),
          'role': _jobRole.toLowerCase(),
          'phone': '+91${_mobileCtrl.text.trim()}',
          'gender': _gender,
          'zone': _zone,
          'division': _division,
          'regions': _selectedRegions,
          'employee_id': _empIdCtrl.text.trim(),
          'approval_status': 'pending',
        },
      );

      if (mounted) {
        setState(() {
          _loading = false;
          if (response.session == null) {
            _message = 'Check your email to confirm your account.';
          } else {
            _message = 'Registration successful! Pending admin approval.';
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
            });
          }
        });
      }
    } on AuthException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _showRegionModal() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              backgroundColor: bgColor,
              title: const Text('Select Region', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _currentRegions.map((r) {
                    return CheckboxListTile(
                      title: Text(r, style: const TextStyle(color: Colors.white70)),
                      value: _selectedRegions.contains(r),
                      checkColor: Colors.white,
                      activeColor: glowColor,
                      onChanged: (val) {
                        setModalState(() {
                          if (val == true) {
                            _selectedRegions.add(r);
                          } else {
                            _selectedRegions.remove(r);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(ctx);
                  },
                  child: Text('Apply', style: TextStyle(color: glowColor)),
                )
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Subtle center glow
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: 0,
            right: 0,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.05),
                    blurRadius: 150,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  _buildGlassmorphicCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'Registration',
          style: TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        // Progress Bar
        Row(
          children: [
            Expanded(child: Container(height: 6, decoration: BoxDecoration(color: glowColor, borderRadius: BorderRadius.circular(3)))),
            const SizedBox(width: 4),
            Expanded(child: Container(height: 6, decoration: BoxDecoration(color: _currentStep >= 2 ? glowColor : Colors.white12, borderRadius: BorderRadius.circular(3)))),
            const SizedBox(width: 12),
            Text('$_currentStep/2', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildGlassmorphicCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_currentStep == 1) _buildStep1(),
              if (_currentStep == 2) _buildStep2(),
              
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                      ],
                    ),
                  ),
                ),

              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_message!, style: const TextStyle(color: Colors.green, fontSize: 13))),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 30),
              
              Row(
                children: [
                  if (_currentStep > 1)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loading ? null : _prevStep,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white30),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Previous', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (_currentStep > 1) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _loading ? null : (_currentStep == 2 ? _submit : _nextStep),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: glowColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              _currentStep == 2 ? 'Register' : 'Next',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF431407)),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Text('1', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              const Text('Personal Details', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildInput('First Name *', _firstNameCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _buildInput('Last Name *', _lastNameCtrl)),
            ],
          ),
          const SizedBox(height: 16),
          _buildInput('Mobile Number *', _mobileCtrl, prefix: '+91 ', isNumber: true),
          const SizedBox(height: 16),
          _buildInput('Email Address *', _emailCtrl, isEmail: true),
          const SizedBox(height: 16),
          _buildInput('Password *', _passwordCtrl, isPassword: true),
          const SizedBox(height: 16),
          const Text('Gender *', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          _buildDropdown(_gender, ['Male', 'Female', 'Other'], (v) => setState(() => _gender = v!)),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Text('2', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              const Text('Work Details', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          
          const Text('Job Role *', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          _buildDropdown(_jobRole, _roles, (v) => setState(() => _jobRole = v!)),
          const SizedBox(height: 12),

          const Text('Zone *', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          _buildDropdown(_zone, _zones, (v) {
            setState(() {
              _zone = v!;
              _division = _currentDivisions.first;
              _selectedRegions.clear();
            });
          }),
          const SizedBox(height: 12),

          const Text('Division *', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          _buildDropdown(_division, _currentDivisions, (v) {
            setState(() {
              _division = v!;
              _selectedRegions.clear();
            });
          }),
          const SizedBox(height: 12),

          const Text('Region *', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: _showRegionModal,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Text(
                _selectedRegions.isEmpty ? 'Select region' : _selectedRegions.join(', '),
                style: TextStyle(color: _selectedRegions.isEmpty ? Colors.white54 : Colors.white, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),

          _buildInput('Employee ID Number', _empIdCtrl),
        ],
      ),
    );
  }


  Widget _buildInput(String label, TextEditingController controller, {bool isPassword = false, bool isEmail = false, bool isNumber = false, String? prefix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: isEmail ? TextInputType.emailAddress : (isNumber ? TextInputType.phone : TextInputType.text),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            prefixText: prefix,
            prefixStyle: const TextStyle(color: Colors.white70, fontSize: 14),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: glowColor.withValues(alpha: 0.5)),
            ),
            errorStyle: const TextStyle(color: Colors.redAccent),
          ),
          validator: (v) {
            if (label.contains('*') && (v == null || v.isEmpty)) return 'Required';
            if (isEmail && v != null && !v.contains('@')) return 'Invalid email';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: bgColor,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
