import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../navigationBarMenu.dart';
import '../screens/community_screen.dart';
import '../screens/contents_screen.dart';
import '../screens/homeScreen.dart';
import '../screens/loginScreen.dart';
import '../screens/logout_button.dart';
import '../screens/sessions_screen.dart';
import '../screens/support_screen.dart';
import '../screens/tickets_screen.dart';
import '../screens/user_management_screen.dart';

part 'router.gr.dart'; // Ensure this matches your generated file name!

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  AppRouter({super.navigatorKey});

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: LoginRoute.page, path: '/login', initial: true),

    // Parent route for the navigation menu with nested tabs
    AutoRoute(
      page: NavigationBarMenuRoute.page,
      path: '/navigation',
      children: [
        AutoRoute(page: HomeRoute.page, path: 'home', initial: true),
        AutoRoute(page: ContentsRoute.page, path: 'contents'),
        AutoRoute(page: SessionsRoute.page, path: 'sessions'),
        AutoRoute(page: TicketsRoute.page, path: 'tickets'),
        AutoRoute(page: UserManagementRoute.page, path: 'user-management'),
        AutoRoute(page: CommunityRoute.page, path: 'community'),
        AutoRoute(page: SupportRoute.page, path: 'support'),
        AutoRoute(page: LogoutRoute.page, path: 'logout'),
      ],
    ),
  ];
}
