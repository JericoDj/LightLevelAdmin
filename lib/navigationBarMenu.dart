import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lightlevelpsychosolutionsadmin/utils/colors.dart';

class NavigationBarMenuScreen extends StatelessWidget {
  final Widget child; // Accepts child for ShellRoute navigation
  const NavigationBarMenuScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final router = GoRouter.of(context);
        const routes = [
          '/navigation/home',
          '/navigation/contents',
          '/navigation/sessions',
          '/navigation/tickets',
          '/navigation/user-management',
          '/navigation/community',
          '/navigation/support',
          '/navigation/logout',
        ];

        int currentIndex = routes.indexOf(router.routeInformationProvider.value.uri.toString());

        if (currentIndex > 0) {
          router.go(routes[currentIndex - 1]);
          return false; // Prevents exiting the app
        }
        return true; // Allows app exit at the first tab
      },
      child: Scaffold(
        backgroundColor: MyColors.white,
        appBar: AppBar(
          title: const Text('Admin Panel',style: TextStyle(color: Colors.white),),
          backgroundColor: MyColors.color1,
          elevation: 3,
        ),
        body: Row(
          children: [
            // Sidebar Navigation
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Navigation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: MyColors.color1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView(
                        children: [
                          _buildSidebarItem(context, Icons.home, 'Home', '/navigation/home'),
                          _buildSidebarItem(context, Icons.people, 'User Management', '/navigation/user-management'),
                          _buildSidebarItem(context, Icons.article, 'Contents', '/navigation/contents'),
                          _buildSidebarItem(context, Icons.video_camera_front, 'Sessions', '/navigation/sessions'),
                          _buildSidebarItem(context, Icons.video_camera_front, 'Test', '/navigation/test'),
                          _buildSidebarItem(context, Icons.confirmation_number, 'Tickets', '/navigation/tickets'),
                          _buildSidebarItem(context, Icons.groups, 'Community', '/navigation/community'),
                          _buildSidebarItem(context, Icons.support, 'Support', '/navigation/support'),
                          _buildLogoutItem(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main Content
            Expanded(flex: 8, child: child),
          ],
        ),
      ),
    );
  }

  /// Sidebar Item with Icons & Improved Styling
  Widget _buildSidebarItem(BuildContext context, IconData icon, String title, String route) {
    final currentRoute = GoRouter.of(context).routeInformationProvider.value.uri.toString();
    final bool isSelected = currentRoute == route;

    return GestureDetector(
      onTap: () => context.go(route),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? MyColors.color1.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: MyColors.color1, width: 2) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? MyColors.color1 : Colors.grey),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? MyColors.color1 : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Logout Button with a More Professional Look
  Widget _buildLogoutItem(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/login'),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: Row(
          children: const [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 10),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
