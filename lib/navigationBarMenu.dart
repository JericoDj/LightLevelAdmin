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

import 'controllers/session_controller.dart';
import 'screens/sessionsScreen/call_page.dart';

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

  // 🔢 Live badge counts for Bookings / Tickets / Community
  int bookingRequestedCount = 0;
  int openTicketsCount = 0;
  int pendingPostsCount = 0;
  StreamSubscription<QuerySnapshot>? _bookingSub;
  StreamSubscription<QuerySnapshot>? _ticketsSub;
  StreamSubscription<QuerySnapshot>? _postsSub;
  // Skip the sound/snackbar burst on each listener's first snapshot
  bool _bookingInit = false;
  bool _ticketsInit = false;
  bool _postsInit = false;

  // Floating Overlay State Variables
  bool _isMinimized = false;
  Offset _position = const Offset(-1, -1);

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _startGlobalSessionListeners();
    _startGlobalBadgeListeners();
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

  void _startGlobalBadgeListeners() {
    // 📅 Bookings → REQUESTED
    _bookingSub = _firestore.collection('bookings').snapshots().listen((snapshot) {
      if (!mounted) return;
      bool matches(Map<String, dynamic> d) =>
          (d['status']?.toString().toLowerCase() ?? 'requested') == 'requested';

      setState(() {
        bookingRequestedCount =
            snapshot.docs.where((doc) => matches(doc.data())).length;
      });

      if (_bookingInit) {
        _notifyNewItems(
          snapshot: snapshot,
          matches: matches,
          buildMessage: (d) =>
              'New Booking Request from ${d['clientName'] ?? 'a client'}',
          route: '/navigation/bookings',
        );
      }
      _bookingInit = true;
    });

    // 🎫 Tickets → OPEN / IN PROGRESS
    _ticketsSub = _firestore.collection('tickets').snapshots().listen((snapshot) {
      if (!mounted) return;
      bool matches(Map<String, dynamic> d) {
        final s = d['status']?.toString().toLowerCase();
        return s == 'open' || s == 'in_progress';
      }

      setState(() {
        openTicketsCount =
            snapshot.docs.where((doc) => matches(doc.data())).length;
      });

      if (_ticketsInit) {
        _notifyNewItems(
          snapshot: snapshot,
          matches: matches,
          buildMessage: (d) =>
              'New Support Ticket Raised: "${d['subject'] ?? 'No Subject'}"',
          route: '/navigation/tickets',
        );
      }
      _ticketsInit = true;
    });

    // 💬 Community Posts → PENDING
    _postsSub = _firestore.collection('posts').snapshots().listen((snapshot) {
      if (!mounted) return;
      bool matches(Map<String, dynamic> d) =>
          (d['status']?.toString().toLowerCase() ?? 'pending') == 'pending';

      setState(() {
        pendingPostsCount =
            snapshot.docs.where((doc) => matches(doc.data())).length;
      });

      if (_postsInit) {
        _notifyNewItems(
          snapshot: snapshot,
          matches: (_) => true,
          buildMessage: (d) =>
              'New Post Pending Review from ${d['username'] ?? 'a user'}',
          route: '/navigation/community',
        );
      }
      _postsInit = true;
    });
  }

  /// Plays a sound + shows a snackbar for each newly-added doc that matches.
  void _notifyNewItems({
    required QuerySnapshot snapshot,
    required bool Function(Map<String, dynamic> data) matches,
    required String Function(Map<String, dynamic> data) buildMessage,
    required String route,
  }) {
    // 🔒 GUARD: Don't show or sound if not logged in
    if (FirebaseAuth.instance.currentUser == null) return;

    for (var change in snapshot.docChanges) {
      if (change.type != DocumentChangeType.added) continue;

      final data = change.doc.data() as Map<String, dynamic>?;
      if (data == null || !matches(data)) continue;

      _playSound();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(buildMessage(data))),
              TextButton(
                onPressed: () => context.go(route),
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
    _bookingSub?.cancel();
    _ticketsSub?.cancel();
    _postsSub?.cancel();
    _audioPlayer.dispose(); // ✅ Cleanup
    super.dispose();
  }

  // 🔔 Plays the alert sound once for a new Sessions / Bookings / Tickets /
  // Community item.
  void _playSound() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      await _audioPlayer.stop(); // restart cleanly if a previous alert is still playing
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

  // ─────────────────────────────────────────────
  // ✅ END ACTIVE SESSION ROUTINE
  // ─────────────────────────────────────────────
  void _endActiveSession(ActiveSession session) {
    if (session.sessionType == "Chat") {
      final controller = SessionsController();
      controller.finishChatSession(session.userId, session.companyId, session.fullName);
      SessionsController.activeSessionNotifier.value = null;
    } else {
      final controller = SessionsController();
      controller.updateStatus(context, session.userId, "Talk", "finished");
      FirebaseFirestore.instance.collection("sessions").doc(session.userId).update({
        "status": "finished",
        "endTime": FieldValue.serverTimestamp(),
      });
      SessionsController.activeSessionNotifier.value = null;
    }
  }

  // ─────────────────────────────────────────────
  // ✅ FLOATING WINDOW OVERLAY BUILDERS
  // ─────────────────────────────────────────────
  Widget _buildFloatingOverlay() {
    return ValueListenableBuilder<ActiveSession?>(
      valueListenable: SessionsController.activeSessionNotifier,
      builder: (context, activeSession, _) {
        if (activeSession == null) return const SizedBox.shrink();

        double width = MediaQuery.of(context).size.width;
        double height = MediaQuery.of(context).size.height;

        double overlayWidth = _isMinimized ? 70 : 400;
        double overlayHeight = _isMinimized ? 70 : 520;

        double x = _position.dx;
        double y = _position.dy;

        if (x == -1 && y == -1) {
          x = width - overlayWidth - 30;
          y = height - overlayHeight - 30;
        }

        // Clamp to screen bounds
        x = x.clamp(0.0, (width - overlayWidth).clamp(0.0, width));
        y = y.clamp(0.0, (height - overlayHeight).clamp(0.0, height));

        return Positioned(
          left: x,
          top: y,
          child: _isMinimized
              ? _buildMinimizedBubble(activeSession)
              : _buildMaximizedWindow(activeSession),
        );
      },
    );
  }

  Widget _buildMinimizedBubble(ActiveSession session) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          double x = _position.dx == -1 ? MediaQuery.of(context).size.width - 100 : _position.dx;
          double y = _position.dy == -1 ? MediaQuery.of(context).size.height - 100 : _position.dy;
          _position = Offset(x + details.delta.dx, y + details.delta.dy);
        });
      },
      onTap: () {
        setState(() {
          _isMinimized = false;
        });
      },
      child: Material(
        elevation: 10,
        shape: const CircleBorder(),
        color: session.sessionType == "Chat" ? Colors.blueAccent : Colors.green.shade600,
        child: Container(
          width: 65,
          height: 65,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                session.sessionType == "Chat" ? Icons.chat : Icons.call,
                color: Colors.white,
                size: 28,
              ),
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaximizedWindow(ActiveSession session) {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 400,
        height: 520,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Column(
            children: [
              // Draggable header
              GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    double x = _position.dx == -1 ? MediaQuery.of(context).size.width - 430 : _position.dx;
                    double y = _position.dy == -1 ? MediaQuery.of(context).size.height - 550 : _position.dy;
                    _position = Offset(x + details.delta.dx, y + details.delta.dy);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  color: session.sessionType == "Chat" ? Colors.blueAccent : Colors.green.shade600,
                  child: Row(
                    children: [
                      Icon(
                        session.sessionType == "Chat" ? Icons.chat : Icons.call,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${session.sessionType}: ${session.fullName}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.white, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _isMinimized = true;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          _confirmCloseOverlay(session);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: session.sessionType == "Chat"
                    ? _buildChatContent(session)
                    : _buildCallContent(session),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmCloseOverlay(ActiveSession session) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Close Session Window?"),
        content: const Text(
          "Do you want to put this session on hold, end it permanently, or just hide the overlay window (you can reopen it from the Sessions tab)?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              SessionsController.activeSessionNotifier.value = null; // Hide overlay
            },
            child: const Text("Hide Window", style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              final controller = SessionsController();
              await controller.putOnHold(session.userId, session.sessionType);
              SessionsController.activeSessionNotifier.value = null;
            },
            child: const Text("Put On Hold", style: TextStyle(color: Colors.orange)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              _endActiveSession(session);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("End Session"),
          ),
        ],
      ),
    );
  }

  Widget _buildChatContent(ActiveSession session) {
    final chatRoomId = "safe_talk/chat/sessions/${session.userId}/messages";
    final TextEditingController chatMsgController = TextEditingController();
    final ScrollController chatScrollController = ScrollController();

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(chatRoomId)
                .orderBy("timestamp", descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final messages = snapshot.data!.docs;

              // Auto-scroll to bottom
              Future.delayed(const Duration(milliseconds: 200), () {
                if (chatScrollController.hasClients) {
                  chatScrollController.jumpTo(chatScrollController.position.maxScrollExtent);
                }
              });

              return ListView.builder(
                controller: chatScrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final messageData = messages[index].data() as Map<String, dynamic>;
                  final isAdmin = messageData["senderId"] == FirebaseAuth.instance.currentUser?.uid;
                  final isSystem = messageData["senderId"] == "system";

                  return Align(
                    alignment: isSystem
                        ? Alignment.center
                        : isAdmin
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? Colors.blueAccent
                            : isSystem
                            ? Colors.grey.shade400
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        messageData["message"] ?? "",
                        style: TextStyle(
                          color: isAdmin || isSystem ? Colors.white : Colors.black87,
                          fontStyle: isSystem ? FontStyle.italic : FontStyle.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection("safe_talk/chat/queue")
              .doc(session.userId)
              .snapshots(),
          builder: (context, snapshot) {
            bool isFinished = false;
            bool isOnHold = false;
            if (snapshot.hasData && snapshot.data!.exists) {
              final status = snapshot.data!["status"];
              isFinished = status == "finished" || status == "cancelled";
              isOnHold = status == "on_hold";
            }

            if (isFinished) {
              return Container(
                padding: const EdgeInsets.all(12),
                color: Colors.red.shade100,
                width: double.infinity,
                child: const Text(
                  "This session has ended.",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              );
            }

            if (isOnHold) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                color: Colors.amber.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Session is on hold",
                      style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection("safe_talk/chat/queue")
                            .doc(session.userId)
                            .update({"status": "ongoing"});
                        await FirebaseFirestore.instance.collection(chatRoomId).add({
                          "senderId": "system",
                          "message": "▶️ Admin has resumed the chat.",
                          "timestamp": FieldValue.serverTimestamp(),
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text("Resume", style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: chatMsgController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        isDense: true,
                        contentPadding: const EdgeInsets.all(10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onSubmitted: (_) {
                        final text = chatMsgController.text.trim();
                        if (text.isEmpty) return;
                        FirebaseFirestore.instance.collection(chatRoomId).add({
                          "senderId": FirebaseAuth.instance.currentUser?.uid,
                          "message": text,
                          "timestamp": FieldValue.serverTimestamp(),
                        });
                        chatMsgController.clear();
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blueAccent, size: 20),
                    onPressed: () {
                      final text = chatMsgController.text.trim();
                      if (text.isEmpty) return;
                      FirebaseFirestore.instance.collection(chatRoomId).add({
                        "senderId": FirebaseAuth.instance.currentUser?.uid,
                        "message": text,
                        "timestamp": FieldValue.serverTimestamp(),
                      });
                      chatMsgController.clear();
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCallContent(ActiveSession session) {
    return CallPage(
      roomId: session.roomId,
      isCaller: false,
      sessionType: session.sessionType,
      userId: session.userId,
      fullName: session.fullName,
      companyId: session.companyId,
    );
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
      child: Stack(
        children: [
          Scaffold(
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
          // Floating Session Overlay
          _buildFloatingOverlay(),
        ],
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
        '/navigation/dataanalytics',
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

  Widget _restrictedAccessWidget() {
    return const Center(
      child: Text(
        "❌ Access Denied: You don't have permission to view this content.",
        style: TextStyle(fontSize: 18, color: Colors.red),
      ),
    );
  }

  /// Dynamic Sidebar Items Based on Role
  List<Widget> _buildSidebarItems(BuildContext context) {
    switch (userRole) {
      case 'Super Admin':
        return [
          _buildSidebarItem(context, Icons.home_outlined, 'Home', '/navigation/home'),
          _buildSidebarItem(context, Icons.people_outline, 'User Management',
              '/navigation/user-management'),
          _buildSidebarItem(context, Icons.description_outlined, 'Contents',
              '/navigation/contents'),
          _buildSidebarItem(
              context, Icons.chat_bubble_outline, 'Sessions', '/navigation/sessions',
              badgeCount: chatQueueCount + talkQueueCount),
          _buildSidebarItem(context, Icons.calendar_month_outlined, 'Bookings',
              '/navigation/bookings',
              badgeCount: bookingRequestedCount),
          _buildSidebarItem(
              context, Icons.confirmation_number_outlined, 'Tickets', '/navigation/tickets',
              badgeCount: openTicketsCount),
          _buildSidebarItem(context, Icons.sensors, 'Telemetry',
              '/navigation/user-tracking'),
          _buildSidebarItem(context, Icons.group_outlined, 'Community',
              '/navigation/community',
              badgeCount: pendingPostsCount),
          _buildSidebarItem(context, Icons.bar_chart, 'Data Analytics',
              '/navigation/dataanalytics'),
          _buildSidebarItem(context, Icons.notifications_none_outlined, 'Notifications', '/navigation/notifications'),
          _buildSidebarItem(
              context, Icons.support_agent_outlined, 'Support', '/navigation/support'),
          _buildLogoutItem(context),
          _buildVersionInfoWidget(),
        ];
      case 'Admin':
        return [
          _buildSidebarItem(context, Icons.home_outlined, 'Home', '/navigation/home'),
          _buildSidebarItem(context, Icons.description_outlined, 'Contents',
              '/navigation/contents'),
          _buildSidebarItem(
              context, Icons.chat_bubble_outline, 'Sessions', '/navigation/sessions',
              badgeCount: chatQueueCount + talkQueueCount),
          _buildSidebarItem(context, Icons.calendar_month_outlined, 'Bookings',
              '/navigation/bookings',
              badgeCount: bookingRequestedCount),
          _buildSidebarItem(
              context, Icons.confirmation_number_outlined, 'Tickets', '/navigation/tickets',
              badgeCount: openTicketsCount),
          _buildSidebarItem(context, Icons.sensors, 'Telemetry',
              '/navigation/user-tracking'),
          _buildSidebarItem(context, Icons.group_outlined, 'Community',
              '/navigation/community',
              badgeCount: pendingPostsCount),
          _buildSidebarItem(context, Icons.bar_chart, 'Data Analytics',
              '/navigation/dataanalytics'),
          _buildSidebarItem(context, Icons.notifications_none_outlined, 'Notifications', '/navigation/notifications'),
          _buildSidebarItem(
              context, Icons.support_agent_outlined, 'Support', '/navigation/support'),
          _buildLogoutItem(context),
          _buildVersionInfoWidget(),
        ];
      case 'Specialist':
        return [
          _buildSidebarItem(context, Icons.calendar_month_outlined, 'Bookings',
              '/navigation/bookings',
              badgeCount: bookingRequestedCount),
          _buildSidebarItem(
              context, Icons.chat_bubble_outline, 'Sessions', '/navigation/sessions',
              badgeCount: chatQueueCount + talkQueueCount),
          _buildLogoutItem(context),
          _buildVersionInfoWidget(),
        ];
      case 'Corporate':
        return [
          _buildSidebarItem(context, Icons.analytics, 'Data Analytics',
              '/navigation/dataanalytics'),
          _buildLogoutItem(context),
          _buildVersionInfoWidget(),
        ];
      default:
        return [
          _buildLogoutItem(context),
        ];
    }
  }

  /// Sidebar Navigation Link Item
  Widget _buildSidebarItem(
      BuildContext context, IconData icon, String title, String route,
      {int badgeCount = 0}) {
    final router = GoRouter.of(context);
    final String currentRoute =
        router.routeInformationProvider.value.uri.toString();
    final bool isSelected = currentRoute.startsWith(route);

    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? MyColors.greyDark.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: isSelected ? MyColors.color1 : Colors.grey[600]),
                const SizedBox(width: 15),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: isSelected ? MyColors.color1 : Colors.grey[800],
                  ),
                ),
              ],
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
