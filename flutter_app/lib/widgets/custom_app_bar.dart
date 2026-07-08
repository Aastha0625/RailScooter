import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? additionalActions;
  final double height;
  final PreferredSizeWidget? bottom;
  final VoidCallback? onProfileTap;

  const CustomAppBar({
    super.key,
    required this.title,
    this.additionalActions,
    this.height = 52.0, // Reduced height to make it less overwhelming
    this.bottom,
    this.onProfileTap,
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
          padding: const EdgeInsets.only(right: 8),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Colors.white, size: 28),
            offset: const Offset(0, 40),
            onSelected: (value) async {
              if (value == 'profile') {
                if (onProfileTap != null) onProfileTap!();
              } else if (value == 'logout') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700)),
                    content: const Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.severityCritical),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Log Out'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
                  }
                  // Run sign out without awaiting so UI doesn't hang on bad network
                  Supabase.instance.client.auth.signOut();
                }
              }
            },
            itemBuilder: (context) => [
              if (onProfileTap != null)
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, color: AppColors.textPrimary, size: 16),
                      SizedBox(width: 8),
                      Text('View Profile', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: AppColors.severityCritical, size: 16),
                    SizedBox(width: 8),
                    Text('Log Out', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
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
