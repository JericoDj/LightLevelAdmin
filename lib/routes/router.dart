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
import '../screens/sessionsScreen/video_call_screen.dart';
import '../screens/supportScreen/support_screen.dart';
import '../screens/ticketsScreen/tickets_screen.dart';
import '../screens/userManagementScreen/user_management_screen.dart';
import '../navigationBarMenu.dart';

final GoRouter router = GoRouter(
  initialLocation: '/navigation/home',
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

    // ✅ Modified Route for Video Call with `callRoom`
    GoRoute(
      path: '/navigation/videocall/:roomId',
      builder: (context, state) {
        final String roomId = state.pathParameters['roomId'] ?? "";
        return VideoCallScreen(roomId: roomId);
      },
    ),

    // ✅ New Route for Open Session using `callRoom`
    GoRoute(
      path: '/navigation/:sessionType/:userId/:callRoom',
      builder: (context, state) {
        final String sessionType = state.pathParameters['sessionType'] ?? "";
        final String userId = state.pathParameters['userId'] ?? "";
        final String callRoom = state.pathParameters['callRoom'] ?? "";

        return sessionType.toLowerCase() == 'chat'
            ? ChatScreen(userId: userId)
            : VideoCallScreen(roomId: callRoom);
      },
    ),

    GoRoute(
      path: '/navigation/chat/:userId',
      builder: (context, state) {
        final String userId = state.pathParameters['userId'] ?? "";
        return ChatScreen(userId: userId);
      },
    ),

    // Parent Route: Navigation Bar with Nested Tabs
    ShellRoute(
      builder: (context, state, child) {
        return NavigationBarMenuScreen(child: child);
      },
      routes: [
        GoRoute(path: '/navigation/home', builder: (context, state) => HomeScreen()),
        GoRoute(path: '/navigation/contents', builder: (context, state) => ContentsScreen()),
        GoRoute(path: '/navigation/sessions', builder: (context, state) => SessionsScreen()),
        GoRoute(path: '/navigation/test', builder: (context, state) => TestApp()),
        GoRoute(path: '/navigation/tickets', builder: (context, state) => TicketsScreen()),
        GoRoute(path: '/navigation/user-management', builder: (context, state) => UserManagementScreen()),
        GoRoute(path: '/navigation/community', builder: (context, state) => CommunityScreen()),
        GoRoute(path: '/navigation/support', builder: (context, state) => SupportScreen()),
      ],
    ),
  ],
);
