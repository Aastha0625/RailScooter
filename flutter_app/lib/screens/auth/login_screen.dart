import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final bool initialSignUp;
  const LoginScreen({super.key, this.initialSignUp = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  late bool _isSignUp;
  String? _error;
  String? _message;
  
  // RBAC Selection
  String _selectedRole = 'Trackman';
  final List<String> _roles = ['Admin', 'Manager', 'Trackman'];

  // Theme Constants matching Welcome Screen
  final Color bgColor = const Color(0xFF0A1118);
  final Color glowColor = const Color(0xFFF97316);

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialSignUp;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });

    try {
      if (_isSignUp) {
        // Sign Up Flow
        final response = await Supabase.instance.client.auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          data: {'full_name': _emailCtrl.text.trim().split('@')[0]},
        );
        
        if (mounted) {
          setState(() {
            _loading = false;
            if (response.session == null) {
              _message = 'Check your email to confirm your account.';
            } else {
              _message = 'Account created successfully!';
              // Successfully signed up and session created
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          });
        }
      } else {
        // Sign In Flow
        final authResponse = await Supabase.instance.client.auth.signInWithPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
        
        // Validate role from backend (app_users table)
        final user = authResponse.user;
        if (user != null) {
          final profile = await Supabase.instance.client
              .from('app_users')
              .select('role')
              .eq('id', user.id)
              .maybeSingle();

          if (profile != null) {
            final dbRole = (profile['role'] as String?)?.toLowerCase() ?? 'trackman';
            final selectedRoleLower = _selectedRole.toLowerCase();

            // Check if the assigned database role matches the selected toggle
            if (dbRole != selectedRoleLower) {
              await Supabase.instance.client.auth.signOut();
              throw Exception('Access Denied: You do not have $_selectedRole privileges. (Registered as: ${dbRole.toUpperCase()})');
            }
            
            // Login successful and role validated
            if (mounted) {
              setState(() => _loading = false);
              // Pop the login screen to reveal the Dashboard which AuthGate builds automatically
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
            
          } else {
            await Supabase.instance.client.auth.signOut();
            throw Exception('Access Denied: No user profile found in the database.');
          }
        }
      }
      
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true, // Let the background grid go behind the appbar
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
          // Background grid/line effect
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(),
            ),
          ),
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
          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildGlassmorphicFormCard(),
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
        Center(
          child: Transform.scale(
            scale: 3.2, // Doubled from 1.6
            child: Image.asset(
              'assets/images/logo.png',
              height: 60, 
              fit: BoxFit.fitHeight, 
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          _isSignUp ? 'Create Account' : 'Welcome Back',
          style: const TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isSignUp ? 'Register for fleet access' : 'Sign in to manage your fleet',
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassmorphicFormCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isSignUp) _buildRoleSelector(),
                if (!_isSignUp) const SizedBox(height: 30),
                
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.severityCritical.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.severityCritical.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: const TextStyle(fontSize: 13, color: Colors.white))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (_message != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.statusActive.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.statusActive.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.lightGreenAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_message!, style: const TextStyle(fontSize: 13, color: Colors.white))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                _buildTextField(
                  controller: _emailCtrl,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  isEmail: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordCtrl,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                const SizedBox(height: 32),
                
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: glowColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isSignUp ? 'Sign Up' : 'Sign In as $_selectedRole', 
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF431407))
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, color: Color(0xFF431407), size: 20),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                        _error = null;
                        _message = null;
                      });
                    },
                    child: Text(
                      _isSignUp ? 'Already have an account? Sign In' : 'Don\'t have an account? Sign Up',
                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: _roles.map((role) {
          final isSelected = _selectedRole == role;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedRole = role;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? glowColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [BoxShadow(color: glowColor.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  role,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF431407) : Colors.white60,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isEmail = false,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.25),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: glowColor, width: 1.5),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return '$label is required';
        if (isEmail && !v.contains('@')) return 'Enter a valid email';
        if (isPassword && _isSignUp && v.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
    );
  }
}

// Custom Painter for the faint vertical center line and subtle dots (reused from welcome screen)
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1.0;

    // Faint vertical center line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    // Subtle background dots
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.05);
    for (double x = 0; x < size.width; x += 40) {
      for (double y = 0; y < size.height; y += 40) {
        canvas.drawCircle(Offset(x, y), 0.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
