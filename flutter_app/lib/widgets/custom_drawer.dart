import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class CustomDrawer extends StatelessWidget {
  final String roleTitle;
  final List<Widget> menuItems;

  const CustomDrawer({
    super.key,
    required this.roleTitle,
    required this.menuItems,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Row(
              children: [
                Transform.scale(
                  scale: 2.5,
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PiScoot', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(roleTitle, style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: menuItems,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.primary, size: 22),
            title: const Text('Log Out', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            onTap: () async {
              Navigator.pop(context);
              await Supabase.instance.client.auth.signOut();
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static Widget buildDrawerItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
