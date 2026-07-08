import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dashboard/dashboard_screen.dart';
import '../manager/manager_dashboard.dart';
import '../trackman/trackman_dashboard.dart';
import 'pending_approval_screen.dart';

class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  bool _isLoading = true;
  String? _role;
  String? _approvalStatus;

  @override
  void initState() {
    super.initState();
    _fetchRole();
  }

  Future<void> _fetchRole() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Fetch the user's role and approval_status from the app_users table
      final data = await Supabase.instance.client
          .from('app_users')
          .select('role, approval_status')
          .eq('id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _role = (data?['role'] as String?)?.toLowerCase() ?? 'trackman'; // Default fallback
          _approvalStatus = data?['approval_status'] as String? ?? 'pending';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching role: $e');
      if (mounted) {
        setState(() {
          _role = 'trackman'; // Fallback on error
          _approvalStatus = 'pending';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading screen while fetching the role
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A1118),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF97316)),
        ),
      );
    }

    // Route dynamically based on the fetched role
    if (_approvalStatus == 'pending') {
      return const PendingApprovalScreen();
    }
    
    if (_role == 'admin') {
      return const DashboardScreen(); // Original full-featured dashboard
    } else if (_role == 'manager') {
      return const ManagerDashboardScreen();
    } else {
      return const TrackmanDashboardScreen(); // Highly simplified trackman view
    }
  }
}
