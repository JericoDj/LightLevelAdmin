import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/forgotPasswordScreen/forgotPasswordScreen.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/signupscreen/signupscreen.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/test/test/test.dart';
import '../screens/communityScreen/community_screen.dart';
import '../screens/contentsScreen/contents_screen.dart';
import '../screens/homescreen/homeScreen.dart';
import '../screens/loginScreen/loginScreen.dart';
import '../screens/sessionsScreen/chat_screen.dart';
import '../screens/sessionsScreen/sessions_screen.dart';
import '../screens/supportScreen/support_call_page.dart';
import '../screens/supportScreen/support_screen.dart';
import '../screens/test/test/pages/callPage/call_page.dart';
import '../screens/ticketsScreen/tickets_screen.dart';
import '../screens/userManagementScreen/user_management_screen.dart';
import '../navigationBarMenu.dart';

final GoRouter router = GoRouter(
  initialLocation: '/navigation/home',
  routes: [
    // ✅ Login Routes
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

    // ✅ Call Route for Talk Sessions
    GoRoute(
      path: '/navigation/talk/:userId/:roomId',
      builder: (context, state) {
        final String userId = state.pathParameters['userId'] ?? "";
        final String roomId = state.pathParameters['roomId'] ?? "";

        return CallPage(
          roomId: roomId,
          isCaller: false,
        );
      },
    ),

    // ✅ New Support Call Route
    GoRoute(
      path: '/navigation/support/:userId/:roomId',
      builder: (context, state) {
        final String userId = state.pathParameters['userId'] ?? "";
        final String roomId = state.pathParameters['roomId'] ?? "";

        return SupportCallPage(
          roomId: roomId,
          isCaller: false,
        );
      },
    ),

    // ✅ Chat Route
    GoRoute(
      path: '/navigation/chat/:userId',
      builder: (context, state) {
        final String userId = state.pathParameters['userId'] ?? "";
        return ChatScreen(userId: userId);
      },
    ),

    // ✅ Navigation Bar with Nested Routes
    ShellRoute(
      builder: (context, state, child) {
        return NavigationBarMenuScreen(child: child);
      },
      routes: [
        GoRoute(path: '/navigation/home', builder: (context, state) => HomeScreen()),
        GoRoute(path: '/navigation/contents', builder: (context, state) => ContentsScreen()),
        GoRoute(path: '/navigation/sessions', builder: (context, state) => SessionsScreen()),
        GoRoute(path: '/navigation/support', builder: (context, state) => SupportScreen()),
        GoRoute(path: '/navigation/test', builder: (context, state) => TestApp()),
        GoRoute(path: '/navigation/tickets', builder: (context, state) => TicketsScreen()),
        GoRoute(path: '/navigation/user-management', builder: (context, state) => UserManagementScreen()),
        GoRoute(path: '/navigation/community', builder: (context, state) => CommunityScreen()),

        // ✅ New Support Screen Route
        GoRoute(
          path: '/navigation/support',
          builder: (context, state) => SupportScreen(),
        ),
      ],
    ),
  ],
);
