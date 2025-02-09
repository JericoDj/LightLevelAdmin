import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import '../routes/router.dart'; // Import the generated routes

@RoutePage()
class NavigationBarMenuScreen extends StatelessWidget {
  const NavigationBarMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWideScreen = constraints.maxWidth > 800; // Show sidebar if width > 800px

        return AutoTabsRouter(
          routes: const [
            HomeRoute(),
            ContentsRoute(),
            SessionsRoute(),
            TicketsRoute(),
            UserManagementRoute(),
            CommunityRoute(),
            SupportRoute(),
            LogoutRoute(),
          ],
          builder: (context, child) {
            final tabsRouter = AutoTabsRouter.of(context);

            return WillPopScope(
              onWillPop: () async {
                // If not on the first tab, go back to the previous tab instead of exiting the app
                if (tabsRouter.activeIndex > 0) {
                  tabsRouter.setActiveIndex(tabsRouter.activeIndex - 1);
                  return false; // Prevent default back button behavior
                }
                return true; // Exit app if on first tab
              },
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Admin Panel'),
                  backgroundColor: Colors.blue,
                  automaticallyImplyLeading: !isWideScreen, // Hide back button if widescreen
                  elevation: 0,
                ),
                body: Row(
                  children: [
                    // Sidebar (Flex 3) for Wide Screens

                      Expanded(
                        flex: 3,
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sidebar Title
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  'Navigation',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Sidebar Items
                              Expanded(
                                child: ListView.builder(
                                  itemCount: 8,
                                  itemBuilder: (context, index) {
                                    final titles = [
                                      'Home',
                                      'Contents',
                                      'Sessions',
                                      'Tickets',
                                      'User Management',
                                      'Community',
                                      'Support',
                                      'Logout'
                                    ];
                                    return GestureDetector(
                                      onTap: () {
                                        tabsRouter.setActiveIndex(index);
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                        decoration: BoxDecoration(
                                          color: tabsRouter.activeIndex == index
                                              ? Colors.blue[50]
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: tabsRouter.activeIndex == index
                                              ? Border.all(color: Colors.blue, width: 2)
                                              : null,
                                        ),
                                        child: Text(
                                          titles[index],
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: tabsRouter.activeIndex == index ? Colors.blue : Colors.grey,
                                            fontWeight: tabsRouter.activeIndex == index
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Main Content (Flex 7) - AutoRouter to display active tab content
                    Expanded(
                      flex: 7,
                      child: child, // Use AutoTabsRouter's child widget
                    ),
                  ],
                ),
                bottomNavigationBar: isWideScreen
                    ? null
                    : BottomNavigationBar(
                  currentIndex: tabsRouter.activeIndex,
                  onTap: tabsRouter.setActiveIndex,
                  items: const [
                    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                    BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Contents'),
                    BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Sessions'),
                    BottomNavigationBarItem(icon: Icon(Icons.airplane_ticket), label: 'Tickets'),
                    BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
                    BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Community'),
                    BottomNavigationBarItem(icon: Icon(Icons.support), label: 'Support'),
                    BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
