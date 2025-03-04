import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/forgotPasswordScreen/forgotPasswordScreen.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/signupscreen/signupscreen.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/test/test/test.dart';
import '../screens/communityScreen/community_screen.dart';
import '../screens/contentsScreen/contents_screen.dart';
import '../screens/homescreen/homeScreen.dart';
import '../screens/loginScreen/loginScreen.dart';
import '../screens/sessionsScreen/sessions_screen.dart';
import '../screens/sessionsScreen/video_call_screen.dart';
import '../screens/supportScreen/support_screen.dart';
import '../screens/ticketsScreen/tickets_screen.dart';
import '../screens/userManagementScreen/user_management_screen.dart';
import '../navigationBarMenu.dart';

final GoRouter router = GoRouter(
  initialLocation: '/navigation/home', // Ensure login is the first screen
  routes: [
    // Login Route
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(),
    ),

    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/sign-up',
      builder: (context, state) => SignUpScreen(),
    ),

    GoRoute(
      path: '/navigation/videocall/:roomId', // ✅ Correctly set route parameter
      builder: (context, state) {
        final String roomId = state.pathParameters['roomId'] ?? "";
        return VideoCallScreen(roomId: roomId);
      },
    ),

    // Parent Route: Navigation Bar with Nested Tabs
    ShellRoute(
      builder: (context, state, child) {
        return NavigationBarMenuScreen(child: child); // Pass the child for navigation
      },
      routes: [
        GoRoute(path: '/navigation/home', builder: (context, state) =>HomeScreen()),
        GoRoute(path: '/navigation/contents', builder: (context, state) =>  ContentsScreen()),
        GoRoute(path: '/navigation/sessions', builder: (context, state) => TestApp()),
        GoRoute(path: '/navigation/tickets', builder: (context, state) => TicketsScreen()),
        GoRoute(path: '/navigation/user-management', builder: (context, state) => UserManagementScreen()),
        GoRoute(path: '/navigation/community', builder: (context, state) => CommunityScreen()),
        GoRoute(path: '/navigation/support', builder: (context, state) => SupportScreen()),
      ],
    ),
  ],
);
