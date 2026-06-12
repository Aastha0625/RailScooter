import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/role_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
      url: 'https://mskizgdxpcuuqzjlblou.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1za2l6Z2R4cGN1dXF6amxibG91Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA5MDk0NzgsImV4cCI6MjA5NjQ4NTQ3OH0.gwAKQFhfeLMLUh4I1L4UUORv8hVQ1HzNvLTGQvs4ib4');

  runApp(const PiScootApp());
}

class PiScootApp extends StatelessWidget {
  const PiScootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PiScoot',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    // Route dynamically based on role if logged in
    if (session != null) return const RoleRouter();
    return const WelcomeScreen();
  }
}
