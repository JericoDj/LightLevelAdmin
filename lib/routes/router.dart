import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/communityScreen/community_screen.dart';
import '../screens/contentsScreen/contents_screen.dart';
import '../screens/homescreen/homeScreen.dart';
import '../screens/loginScreen/loginScreen.dart';
import '../screens/logoutScreen/logout_button.dart';
import '../screens/sessionsScreen/sessions_screen.dart';
import '../screens/supportScreen/support_screen.dart';
import '../screens/ticketsScreen/tickets_screen.dart';
import '../screens/userManagementScreen/user_management_screen.dart';
import '../navigationBarMenu.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login', // Ensure login is the first screen
  routes: [
    // Login Route
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(),
    ),

    // Parent Route: Navigation Bar with Nested Tabs
    ShellRoute(
      builder: (context, state, child) {
        return NavigationBarMenuScreen(child: child); // Pass the child for navigation
      },
      routes: [
        GoRoute(path: '/navigation/home', builder: (context, state) =>HomeScreen()),
        GoRoute(path: '/navigation/contents', builder: (context, state) =>  ContentsScreen()),
        GoRoute(path: '/navigation/sessions', builder: (context, state) => SessionsScreen()),
        GoRoute(path: '/navigation/tickets', builder: (context, state) => TicketsScreen()),
        GoRoute(path: '/navigation/user-management', builder: (context, state) => UserManagementScreen()),
        GoRoute(path: '/navigation/community', builder: (context, state) => CommunityScreen()),
        GoRoute(path: '/navigation/support', builder: (context, state) => SupportScreen()),
        GoRoute(path: '/navigation/logout', builder: (context, state) =>  LogoutScreen()),
      ],
    ),
  ],
);
