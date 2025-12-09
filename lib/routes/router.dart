import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/bookingsScreen/bookingsScreen.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/forgotPasswordScreen/forgotPasswordScreen.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/signupscreen/signupscreen.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/test/test/test.dart';
import '../models/articles_model.dart';

import '../models/videos_models.dart';
import '../screens/communityScreen/community_screen.dart';
import '../screens/contentsScreen/articles_content_screen.dart';
import '../screens/contentsScreen/contents_screen.dart';
import '../screens/contentsScreen/ebooks_screen.dart';
import '../screens/contentsScreen/homepagecontents.dart';
import '../screens/contentsScreen/insightquest.dart';
import '../screens/contentsScreen/popups/mindHubContentScreen.dart';
import '../screens/contentsScreen/popups/mind_hub_articles_popup.dart';
import '../screens/contentsScreen/video_contents_screen.dart';
import '../screens/dataAnalyticsScreen/DataAnalytics.dart';
import '../screens/homescreen/homeScreen.dart';
import '../screens/loginScreen/loginScreen.dart';
import '../screens/reports/ReportsScreen.dart';
import '../screens/reports/bookingFace2FaceReports/bookingFace2FaceScreen.dart';
import '../screens/reports/bookingOnlineReports/bookingOnlineReportsScreen.dart';
import '../screens/reports/communityPostReports/communityPostReportsScreen.dart';
import '../screens/reports/sessionCallReports/sessionCallReportsScreen.dart';
import '../screens/reports/sessionChatReports/sessionChatReportsScreen.dart';
import '../screens/reports/ticketsReports/ticketReportsScreen.dart';
import '../screens/sessionsScreen/call_page.dart';
import '../screens/sessionsScreen/chat_screen.dart';
import '../screens/sessionsScreen/sessions_screen.dart';
import '../screens/supportScreen/support_call_page.dart';
import '../screens/supportScreen/support_screen.dart';
import '../screens/test/test/pages/callPage/call_page.dart';
import '../screens/ticketsScreen/tickets_screen.dart';
import '../screens/userManagementScreen/user_management_screen.dart';
import '../navigationBarMenu.dart';


final GoRouter router = GoRouter(


  initialLocation: '/login',
  redirect: (context, state) {
    final user = GetStorage().read('user');
    final isLoggedIn = user != null && user['uid'] != null;
    final isLoginPage = state.matchedLocation == '/login';
    final isSignUpPage = state.matchedLocation == '/sign-up';
    final isForgotPasswordPage = state.matchedLocation == '/forgot-password';

    if (!isLoggedIn && !isLoginPage && !isSignUpPage && !isForgotPasswordPage) {
      return '/login'; // ✅ Only block protected routes
    }

    if (isLoggedIn && (isLoginPage || isSignUpPage || isForgotPasswordPage)) {
      return '/navigation/home'; // ✅ Redirect logged-in users away from auth screens
    }

    return null;
  },
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
      path: '/navigation/talk/:roomId',
      builder: (context, state) {
        final roomId = state.pathParameters['roomId']!;

        return CallPage(
          roomId: roomId,
          isCaller: false, // ✅ ADMIN JOINS
        );
      },
    ),


    // ✅ New Support Call Route
    GoRoute(
      path: '/navigation/chat/:userId/:fullName/:companyId',
      builder: (context, state) {
        final String userId = state.pathParameters['userId'] ?? "";
        final String fullName = state.pathParameters['fullName'] ?? "";
        final String companyId = state.pathParameters['companyId'] ?? "";
        return ChatScreen(userId: userId ,fullName: fullName, companyId: companyId);
      },
    ),

    // ✅ Chat Route
    GoRoute(
      path: '/navigation/chat/:userId/:fullName/:companyId',
      builder: (context, state) {
        final String userId = state.pathParameters['userId'] ?? "";
        final String fullName = state.pathParameters['fullName'] ?? "";
        final String companyId = state.pathParameters['companyId'] ?? "";
        return ChatScreen(userId: userId ,fullName: fullName, companyId: companyId);
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
        GoRoute(path: '/navigation/bookings', builder: (context, state) => BookingsScreen()),

        GoRoute(path: '/navigation/test', builder: (context, state) => TestApp()),
        GoRoute(path: '/navigation/tickets', builder: (context, state) => TicketsScreen()),
        GoRoute(path: '/navigation/user-management', builder: (context, state) => UserManagementScreen()),
        GoRoute(path: '/navigation/community', builder: (context, state) => CommunityScreen()),
        GoRoute(
          path: '/navigation/dataanalytics',
          builder: (context, state) => DataAnalyticsReportScreen(),
        ),

        //Reports Routes
        GoRoute(
          path: '/navigation/reports',
          builder: (context, state) => const ReportsScreen(),
        ),

        GoRoute(path: '/navigation/reports/sessions-chats', builder: (context, state) => const SessionsChatReportScreen()),
        GoRoute(path: '/navigation/reports/session-calls', builder: (context, state) => const SessionCallsReportScreen()),
        GoRoute(path: '/navigation/reports/bookings-online', builder: (context, state) => const BookingsOnlineReportScreen()),
        GoRoute(path: '/navigation/reports/bookings-face-to-face', builder: (context, state) => const BookingsFaceToFaceReportScreen()),
        GoRoute(path: '/navigation/reports/tickets', builder: (context, state) => const TicketsReportScreen()),
        GoRoute(path: '/navigation/reports/community-posts', builder: (context, state) => const CommunityPostsReportScreen()),





        GoRoute(
          path: '/navigation/contents/homepage',
          builder: (context, state) => HomePageContentScreen(),
        ),
        GoRoute(
          path: '/navigation/contents/mindhub',
          builder: (context, state) => const MindHubContentScreen(articles: [], videos: [], ebooks: [],),
        ),
        GoRoute(
          path: '/navigation/contents/insightquest',
          builder: (context, state) => const AdminQuizManagementScreen(),
        ),

        // ✅ New Support Screen Route
        GoRoute(
          path: '/navigation/support',
          builder: (context, state) => SupportScreen(),
        ),
        GoRoute(
          path: '/mindhub-content',
          builder: (context, state) {
            final articles = state.extra as List<Article>; // Receive the articles list
            return MindHubContentScreen(articles: articles, videos: [], ebooks: [],); // Pass it to the MindHubContentScreen
          },
        ),
        GoRoute(
          path: '/articles-content',
          builder: (context, state) {
            final articles = state.extra as List<Article>; // Receive the articles list
            return ArticlesContentScreen(articles: articles); // Pass it to the ArticlesContentScreen
          },
        ),
        GoRoute(
          path: '/videos-content',
          builder: (context, state) {
            final videos = (state.extra as List<Video>?) ?? [];

            return VideosContentScreen(videos: videos);
          },
        ),
        GoRoute(
          path: '/ebooks-content',
          builder: (context, state) {
            final ebooks = state.extra != null
                ? List<Ebook>.from(state.extra as List<dynamic>)
                : <Ebook>[];
            return EbooksContentScreen(ebooks: ebooks);
          },
        ),



      ],
    ),
  ],
);
