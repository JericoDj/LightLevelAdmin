import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationBarMenuScreen extends StatelessWidget {
  final Widget child; // Accepts child for ShellRoute navigation
  const NavigationBarMenuScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final router = GoRouter.of(context);

        // Define tab routes correctly
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

        int currentIndex = routes.indexOf(GoRouter
            .of(context)
            .routeInformationProvider
            .value
            .uri
            .toString());

        if (currentIndex > 0) {
          // Move back to the previous tab instead of closing the app
          router.go(routes[currentIndex - 1]);
          return false; // Prevent default back behavior (app exit)
        }

        return true; // Allow the app to exit only when at the first tab
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          backgroundColor: Colors.blue,
          elevation: 0,
        ),
        body: Row(
          children: [
            // Sidebar for wide screens
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Navigation',
                        style: TextStyle(fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: ListView(
                        children: [
                          _buildSidebarItem(
                              context, 'Home', '/navigation/home'),
                          _buildSidebarItem(context, 'User Management',
                              '/navigation/user-management'),
                          _buildSidebarItem(
                              context, 'Contents', '/navigation/contents'),
                          _buildSidebarItem(
                              context, 'Sessions', '/navigation/sessions'),
                          _buildSidebarItem(
                              context, 'Tickets', '/navigation/tickets'),

                          _buildSidebarItem(
                              context, 'Community', '/navigation/community'),
                          _buildSidebarItem(
                              context, 'Support', '/navigation/support'),
                          _buildSidebarItem(
                              context, 'Logout', '/navigation/logout'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main Content - Shows the active tab
            Expanded(flex: 7, child: child),
          ],
        ),

        // Bottom Navigation for mobile

      ),
    );
  }

  /// Sidebar Item Builder
  Widget _buildSidebarItem(BuildContext context, String title, String route) {
    final currentRoute = GoRouter
        .of(context)
        .routeInformationProvider
        .value
        .uri
        .toString();
    final bool isSelected = currentRoute == route;

    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: isSelected ? Colors.blue : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
