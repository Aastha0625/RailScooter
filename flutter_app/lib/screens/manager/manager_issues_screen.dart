import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ManagerIssuesScreen extends StatelessWidget {
  const ManagerIssuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Issue Management'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: const Center(
        child: Text('Manager Issues Screen Placeholder'),
      ),
    );
  }
}
