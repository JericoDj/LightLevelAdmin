import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lightlevelpsychosolutionsadmin/utils/colors.dart';
import 'package:lightlevelpsychosolutionsadmin/utils/user_storage.dart';

class NavigationBarMenuScreen extends StatefulWidget {
  final Widget child; // Accepts child for ShellRoute navigation
  const NavigationBarMenuScreen({super.key, required this.child});

  @override
  _NavigationBarMenuScreenState createState() => _NavigationBarMenuScreenState();
}

class _NavigationBarMenuScreenState extends State<NavigationBarMenuScreen> {
  String? userRole;
  bool canAccessHome = false;
  bool isUser = false;
  bool isSpecialist = false;
  bool isLoading = true; // ✅ Loading state to prevent flashing 'Access Denied'

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  // ✅ Load role from GetStorage
  Future<void> _loadUserRole() async {
    final role = UserStorage.getUserRole();

    if (role == null) {
      // Optionally fetch from Firestore if needed or wait a bit
      print("⚠️ Role not found in local storage. Retrying...");
      await Future.delayed(Duration(milliseconds: 200)); // small delay
      return _loadUserRole(); // retry (careful to avoid infinite loop)
    }

    setState(() {
      userRole = role;
      canAccessHome = role == 'Super Admin' || role == 'Admin';
      isSpecialist = role == 'Specialist';
      isLoading = false;

      if (isSpecialist) {
        Future.delayed(Duration.zero, () => context.go('/navigation/bookings'));
      }
    });
  }

  // ✅ Fetch User Role from Firestore
  Future<void> _fetchUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      final adminDoc = await _firestore.collection('admins').doc(uid).get();
      if (adminDoc.exists) {
        final role = adminDoc.data()?['role'] ?? 'User';

        setState(() {
          userRole = role;
          canAccessHome = role == 'Super Admin' || role == 'Admin';
          isSpecialist = role == 'Specialist';
          isLoading = false; // ✅ Stop loading once data is fetched

          // ✅ Auto-redirect Specialist to 'Test' page
          if (isSpecialist) {
            Future.delayed(Duration.zero, () => context.go('/navigation/bookings'));
          }
        });
      } else {
        print("❌ No role found for UID: $uid");
        setState(() {
          userRole = 'User'; // Default if no role is found
          isLoading = false; // ✅ Stop loading
        });
      }
    } else {
      print("❌ No authenticated user found.");
      setState(() {
        userRole = 'User'; // Default role for safety
        isLoading = false; // ✅ Stop loading
      });
    }
  }

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
          title: const Text('Luminara Admin Panel', style: TextStyle(color: MyColors.color1, fontWeight: FontWeight.bold)),
          backgroundColor: MyColors.greyLight,
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
                        children: _buildSidebarItems(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main Content — Show Loading, Content, or Restricted Access
            Expanded(
              flex: 8,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator()) // ✅ Loading indicator
                  : (userRole == 'Super Admin' || userRole == 'Admin' || isSpecialist)
                  ? widget.child // ✅ Show content for Admin/Super Admin/Specialist
                  : _restrictedAccessWidget(), // ❌ Restricted view for unknown roles
            ),
          ],
        ),
      ),
    );
  }

  /// Dynamic Sidebar Items Based on Role
  List<Widget> _buildSidebarItems(BuildContext context) {
    switch (userRole) {
      case 'Super Admin':
        return [
          _buildSidebarItem(context, Icons.home, 'Home', '/navigation/home'),
          _buildSidebarItem(context, Icons.people, 'User Management', '/navigation/user-management'),
          _buildSidebarItem(context, Icons.article, 'Contents', '/navigation/contents'),
          _buildSidebarItem(context, Icons.video_camera_front, 'Sessions', '/navigation/sessions'),
          _buildSidebarItem(context, Icons.video_camera_front, 'Bookings', '/navigation/bookings'),
          _buildSidebarItem(context, Icons.video_camera_front, 'Support', '/navigation/support'),

          _buildSidebarItem(context, Icons.confirmation_number, 'Tickets', '/navigation/tickets'),

          _buildSidebarItem(context, Icons.groups, 'Community', '/navigation/community'),
          // _buildSidebarItem(context, Icons.report, 'Reports', '/navigation/reports'),
          _buildLogoutItem(context),
        ];
      case 'Admin':
        return [
          _buildSidebarItem(context, Icons.home, 'Home', '/navigation/home'),
          _buildSidebarItem(context, Icons.video_camera_front, 'Sessions', '/navigation/sessions'),
          // _buildSidebarItem(context, Icons.video_camera_front, 'Support', '/navigation/support'),
          _buildSidebarItem(context, Icons.video_camera_front, 'Bookings', '/navigation/bookings'),
          _buildSidebarItem(context, Icons.confirmation_number, 'Tickets', '/navigation/tickets'),
          _buildSidebarItem(context, Icons.groups, 'Community', '/navigation/community'),
          _buildLogoutItem(context),
        ];
      case 'Specialist':
        return [

          _buildSidebarItem(context, Icons.video_camera_front, 'Bookings', '/navigation/bookings'),
          _buildLogoutItem(context),
        ];
      default: // For 'User'
        return [
          _buildLogoutItem(context),
        ];
    }
  }

  /// Restricted Access Widget
  Widget _restrictedAccessWidget() {
    return const Center(
      child: Text(
        "❌ Access Denied: You don't have permission to view this content.",
        style: TextStyle(fontSize: 18, color: Colors.red),
      ),
    );
  }

  /// Sidebar Item
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
        color: isSelected ? MyColors.color1.withOpacity(0.15) : Colors.white,
        child: Row(
          children: [
            Icon(icon, color: isSelected ? MyColors.color1 : Colors.grey),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? MyColors.color1 : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Logout Button
  Widget _buildLogoutItem(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await FirebaseAuth.instance.signOut();
        context.go('/login');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        color: Colors.red[50],
        child: Row(
          children: const [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 10),
            Text('Logout', style: TextStyle(fontSize: 16, color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
