import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? additionalActions;
  final double height;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.additionalActions,
    this.height = 52.0, // Reduced height to make it less overwhelming
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
      backgroundColor: AppColors.primary,
      elevation: 0,
      toolbarHeight: height,
      bottom: bottom,
      actions: [
        if (additionalActions != null) ...additionalActions!,
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: 100, // Explicit width instead of aggressive scaling
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0.0;
    return Size.fromHeight(height + bottomHeight);
  }
}
