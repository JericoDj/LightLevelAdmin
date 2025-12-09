import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lightlevelpsychosolutionsadmin/utils/colors.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _safeSpaceQueueCount = 0;
  int _safeSpace247QueueCount = 0;
  int _supportTicketCount = 0;
  int _communityPendingPostsCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchSafeSpaceQueueCount();
    _fetch247SafeSpaceQueueCount();
    _fetchSupportTicketCount();
    _fetchCommunityPendingPostsCount();
  }

  Future<void> _fetchCommunityPendingPostsCount() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('safeSpace')
          .doc('posts')
          .collection('userPosts')
          .where('status', isEqualTo: 'pending')
          .get();

      setState(() {
        _communityPendingPostsCount = query.docs.length;
      });
    } catch (e) {
      print('Error fetching community posts: $e');
    }
  }

  Future<void> _fetchSupportTicketCount() async {
    try {
      final ticketQuery = await FirebaseFirestore.instance
          .collectionGroup('tickets')
          .get();

      setState(() {
        _supportTicketCount = ticketQuery.docs.length;
      });
    } catch (e) {
      print('Error fetching support tickets: $e');
    }
  }

  Future<void> _fetch247SafeSpaceQueueCount() async {
    try {
      final bookingsQuery = await FirebaseFirestore.instance
          .collection('bookings')
          .where('status', isEqualTo: 'Requested')
          .get();

      setState(() {
        _safeSpace247QueueCount = bookingsQuery.docs.length;
      });
    } catch (e) {
      print('Error fetching 24/7 Safe Space queue: $e');
    }
  }

  Future<void> _fetchSafeSpaceQueueCount() async {
    try {
      final chatQuery = await FirebaseFirestore.instance
          .collection('safe_talk')
          .doc('chat')
          .collection('queue')
          .where('status', isEqualTo: 'queue')
          .get();

      final talkQuery = await FirebaseFirestore.instance
          .collection('safe_talk')
          .doc('talk')
          .collection('queue')
          .where('status', isEqualTo: 'queue')
          .get();

      setState(() {
        _safeSpaceQueueCount = chatQuery.docs.length + talkQuery.docs.length;
      });
    } catch (e) {
      print('Error fetching queue count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (same AppBar and padding)

    return Scaffold(
      backgroundColor: Colors.white10,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBar(
          title: Align(
            alignment: AlignmentDirectional.centerStart,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Admin Dashboard',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
          ),
          backgroundColor: Colors.green[800],
          elevation: 0,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  // _buildDashboardCard("📊 Average Mood", "Neutral (3.5/5)", Colors.blueAccent),
                  // _buildDashboardCard("⚡ Average Stress Level", "Moderate (2.8/5)", Colors.orangeAccent),
                  _buildDashboardCard("📅 Safe Space Queue Sessions", "$_safeSpaceQueueCount Sessions", MyColors.color2),
                  _buildDashboardCard("🕒 24/7 Safe Space Queue", "$_safeSpace247QueueCount Users", MyColors.color2),
                  _buildDashboardCard("📞 Customer Support Queue", "$_supportTicketCount Tickets", MyColors.color2),
                  _buildDashboardCard("🌍 Community Queue Posts", "$_communityPendingPostsCount Posts", MyColors.color2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
