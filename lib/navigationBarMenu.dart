import 'dart:async';
import 'package:audioplayers/audioplayers.dart'; // ✅ Added for sound
import 'package:cloud_firestore/cloud_firestore.dart';


import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:lightlevelpsychosolutionsadmin/utils/colors.dart';
import 'package:lightlevelpsychosolutionsadmin/utils/user_storage.dart';
import 'package:get/get.dart';
import 'package:lightlevelpsychosolutionsadmin/controllers/login_controller/login_controller.dart';
import 'repository/authentication_repositories/authentication_repository.dart';

class NavigationBarMenuScreen extends StatefulWidget {
  final Widget child; // Accepts child for ShellRoute navigation
  const NavigationBarMenuScreen({super.key, required this.child});

  @override
  _NavigationBarMenuScreenState createState() =>
      _NavigationBarMenuScreenState();
}

class _NavigationBarMenuScreenState extends State<NavigationBarMenuScreen> {
  String? userRole;
  bool canAccessHome = false;
  bool isUser = false;
  bool isSpecialist = false;
  bool isLoading = true; // ✅ Loading state to prevent flashing 'Access Denied'

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int chatQueueCount = 0;
  int talkQueueCount = 0;
  StreamSubscription<QuerySnapshot>? _chatSub;

  StreamSubscription<QuerySnapshot>? _talkSub;
  final AudioPlayer _audioPlayer = AudioPlayer(); // ✅ Global Audio Player


  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _startGlobalSessionListeners();
  }

  void _startGlobalSessionListeners() {
    // 🎧 Listen to Chat Queue
    _chatSub = _firestore
        .collection('safe_talk/chat/queue')
        .where('status', isEqualTo: 'queue')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          chatQueueCount = snapshot.docs.length;
        });
        _showIncomingSessionNotification("Chat", snapshot);
      }
    });

    // 🎧 Listen to Talk Queue
    _talkSub = _firestore
        .collection('safe_talk/talk/queue')
        .where('status', isEqualTo: 'queue')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          talkQueueCount = snapshot.docs.length;
        });
        _showIncomingSessionNotification("Talk", snapshot);
      }
    });
  }

  void _showIncomingSessionNotification(String type, QuerySnapshot snapshot) {
    // 🔒 GUARD: Don't show or sound if not logged in
    if (FirebaseAuth.instance.currentUser == null) return;

    // Only show if a NEW document was added
    for (var change in snapshot.docChanges) {

      if (change.type == DocumentChangeType.added) {
        final data = change.doc.data() as Map<String, dynamic>?;
        final name = data?['fullName'] ?? 'Someone';
        
        _playSound();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('New $type Session Request from $name')),
                TextButton(
                  onPressed: () => context.go('/navigation/sessions'),
                  child: const Text('VIEW', style: TextStyle(color: Colors.yellow)),
                ),
              ],
            ),
            backgroundColor: MyColors.color1,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    _talkSub?.cancel();
    _audioPlayer.dispose(); // ✅ Cleanup
    super.dispose();
  }

  void _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('notify.mp3'));
    } catch (e) {
      debugPrint("❌ Error playing sound: $e");
    }
  }



  // ✅ Load role from GetStorage
  Future<void> _loadUserRole() async {
    // Try a few times only
    const maxRetries = 5;
    int retries = 0;

    while (retries < maxRetries) {
      if (!mounted) return;

      final role = UserStorage.getUserRole();

      if (role != null) {
        if (!mounted) return;

        setState(() {
          userRole = role;
          canAccessHome = role == 'Super Admin' || role == 'Admin';
          isSpecialist = role == 'Specialist';
          isLoading = false;
        });

        // ✅ Navigation OUTSIDE setState
        if (isSpecialist && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.go('/navigation/bookings');
            }
          });
        }

        return; // ✅ EXIT once role is found
      }

      retries++;
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Optional fallback
    if (mounted) {
      // ✅ Fallback to Firestore if local storage fails
      await _fetchUserRole();
    }
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
            Future.delayed(
                Duration.zero, () => context.go('/navigation/bookings'));
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

        int currentIndex = routes
            .indexOf(router.routeInformationProvider.value.uri.toString());

        if (currentIndex > 0) {
          router.go(routes[currentIndex - 1]);
          return false; // Prevents exiting the app
        }
        return true; // Allows app exit at the first tab
      },
      child: Scaffold(
        backgroundColor: MyColors.white,
        appBar: AppBar(
          title: const Text('Luminara Admin Panel',
              style: TextStyle(
                  color: MyColors.color1, fontWeight: FontWeight.bold)),
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
                  ? const Center(
                      child: CircularProgressIndicator()) // ⏳ Show loading
                  : (userRole == null)
                      ? _noUserFoundWidget() // ❌ Handle no user case
                      : _canAccessRoute(
                          userRole!,
                          GoRouter.of(context)
                              .routeInformationProvider
                              .value
                              .uri
                              .toString(),
                        )
                          ? widget.child
                          : _restrictedAccessWidget(),
            ),
          ],
        ),
      ),
    );
  }

  bool _canAccessRoute(String role, String route) {
    // SUPER ADMIN → all access
    if (role == 'Super Admin') return true;

    // ADMIN
    if (role == 'Admin') {
      return [
        '/navigation/home',
        '/navigation/contents',
        '/navigation/sessions',
        '/navigation/bookings',
        '/navigation/tickets',
        '/navigation/community',
        '/navigation/user-tracking',
        '/navigation/support',
        '/navigation/notifications',
      ].any(route.startsWith);
    }

    // SPECIALIST
    if (role == 'Specialist') {
      return [
        '/navigation/bookings',
        '/navigation/sessions',
      ].any(route.startsWith);
    }

    // CORPORATE
    if (role == 'Corporate') {
      return route.startsWith('/navigation/dataanalytics');
    }

    return false;
  }

  Widget _noUserFoundWidget() {
    return const Center(
      child: Text(
        'No user found. Please log in again.',
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, color: Colors.red),
      ),
    );
  }

  /// Dynamic Sidebar Items Based on Role
  List<Widget> _buildSidebarItems(BuildContext context) {
    switch (userRole) {
      case 'Super Admin':
        return [
          _buildSidebarItem(context, Icons.home, 'Home', '/navigation/home'),
          _buildSidebarItem(context, Icons.people, 'User Management',
              '/navigation/user-management'),
          _buildSidebarItem(
              context, Icons.article, 'Contents', '/navigation/contents'),
          _buildSidebarItem(context, Icons.chat, 'Sessions', '/navigation/sessions',
              badgeCount: chatQueueCount + talkQueueCount),
          _buildSidebarItem(context, Icons.video_camera_front, 'Bookings',
              '/navigation/bookings'),
          _buildSidebarItem(context, Icons.confirmation_number, 'Tickets',
              '/navigation/tickets'),
          _buildSidebarItem(context, Icons.track_changes, 'Telemetry',
              '/navigation/user-tracking'),
          _buildSidebarItem(
              context, Icons.groups, 'Community', '/navigation/community'),
          _buildSidebarItem(context, Icons.data_thresholding, 'Data Analytics',
              '/navigation/dataanalytics'),
          _buildSidebarItem(
              context, Icons.notifications_active, 'Notifications', '/navigation/notifications'),
          _buildSidebarItem(
              context, Icons.support_agent, 'Support', '/navigation/support'),
          _buildLogoutItem(context),
          _buildVersionInfoWidget(),
        ];
      case 'Admin':
        return [
          _buildSidebarItem(context, Icons.home, 'Home', '/navigation/home'),
          _buildSidebarItem(
              context, Icons.article, 'Contents', '/navigation/contents'),
          _buildSidebarItem(context, Icons.chat, 'Sessions', '/navigation/sessions',
              badgeCount: chatQueueCount + talkQueueCount),
          _buildSidebarItem(context, Icons.video_camera_front, 'Bookings',
              '/navigation/bookings'),
          _buildSidebarItem(context, Icons.confirmation_number, 'Tickets',
              '/navigation/tickets'),
          _buildSidebarItem(context, Icons.track_changes, 'Telemetry',
              '/navigation/user-tracking'),
          _buildSidebarItem(
              context, Icons.groups, 'Community', '/navigation/community'),
          _buildSidebarItem(
              context, Icons.notifications_active, 'Notifications', '/navigation/notifications'),
          _buildSidebarItem(
              context, Icons.support_agent, 'Support', '/navigation/support'),
          _buildLogoutItem(context),
          _buildVersionInfoWidget(),
        ];
      case 'Specialist':
        return [
          _buildSidebarItem(context, Icons.video_camera_front, 'Bookings',
              '/navigation/bookings'),
          _buildSidebarItem(context, Icons.chat, 'Sessions', '/navigation/sessions',
              badgeCount: chatQueueCount + talkQueueCount),
          _buildLogoutItem(context),
          _buildVersionInfoWidget(),
        ];
      case 'Corporate':
        return [
          _buildSidebarItem(context, Icons.data_thresholding, 'Data Analytics',
              '/navigation/dataanalytics'),
          _buildLogoutItem(context),
          _buildVersionInfoWidget(),
        ];
      default: // For 'User'
        return [
          _buildLogoutItem(context),
          _buildVersionInfoWidget(),
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
  Widget _buildSidebarItem(
      BuildContext context, IconData icon, String title, String route, {int badgeCount = 0}) {
    final currentRoute =
        GoRouter.of(context).routeInformationProvider.value.uri.toString();
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
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? MyColors.color1 : Colors.grey[800],
                ),
              ),
            ),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
        await AuthRepository.instance.logoutUser();
        // ✅ Delete LoginController to ensure fields are cleared when returning to LoginScreen
        if (Get.isRegistered<LoginController>()) {
          Get.delete<LoginController>();
        }
        if (mounted) {
          context.go('/login');
        }
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

  _buildVersionInfoWidget() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Divider(),
          Text(
            'App Version: 2.0.15',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          SizedBox(height: 4),
          Text(
            'Build Number: 15',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
