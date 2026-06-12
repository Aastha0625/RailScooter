import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ManagerDispatchScreen extends StatelessWidget {
  const ManagerDispatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dispatch Hub'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: const Center(
        child: Text('Manager Dispatch Screen Placeholder'),
      ),
    );
  }
}
