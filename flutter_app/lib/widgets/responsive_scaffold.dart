import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_sidebar.dart';

class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final String roleTitle;
  final String userName;
  final String userRole;
  final List<SidebarItem> sidebarItems;
  final VoidCallback? onProfileTap;

  const ResponsiveScaffold({
    super.key,
    required this.appBar,
    required this.body,
    this.floatingActionButton,
    required this.roleTitle,
    required this.userName,
    required this.userRole,
    required this.sidebarItems,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if screen is wide enough for a persistent sidebar
    final isWide = MediaQuery.of(context).size.width >= 720;

    final sidebar = AppSidebar(
      roleTitle: roleTitle,
      userName: userName,
      userRole: userRole,
      items: sidebarItems,
      width: 200,
      onProfileTap: onProfileTap,
    );

    if (isWide) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            sidebar,
            Expanded(
              child: Scaffold(
                appBar: appBar,
                body: body,
                floatingActionButton: floatingActionButton,
                backgroundColor: AppColors.background,
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: appBar,
        drawer: Drawer(
          width: 240, // Slightly wider drawer on mobile for readability
          child: sidebar,
        ),
        body: body,
        floatingActionButton: floatingActionButton,
      );
    }
  }
}
