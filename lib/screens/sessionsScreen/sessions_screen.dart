import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/session_controller.dart';

class SessionsScreen extends StatefulWidget {
  @override
  _SessionsScreenState createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  final SessionsController controller = SessionsController();

  late AudioPlayer _player;


  @override
  void initState() {
    super.initState();

    _player = AudioPlayer();
    _listenForQueueAlerts();
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  /// --------------------------
  /// 🔔 PLAY ALERT SOUND
  /// --------------------------
  Future<void> _playAlertSound() async {
    try {
      await _player.stop(); // prevent overlap
      await _player.play(
        AssetSource('notify.mp3'),
        volume: 1.0,
      );
    } catch (e) {
      debugPrint("Sound error → $e");
    }
  }

  /// --------------------------
  /// 🔍 LISTEN FOR NEW QUEUE USERS
  /// --------------------------
  void _listenForQueueAlerts() {
    // CHAT QUEUE
    controller.getConsultationsStream("queue", "Chat").listen((snapshot) {
      if (!_isOnSessionsRoute) return; // 🔒 guard

      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _playAlertSound();
          break;
        }
      }
    });

    // TALK QUEUE
    controller.getConsultationsStream("queue", "Talk").listen((snapshot) {
      if (!_isOnSessionsRoute) return; // 🔒 guard

      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _playAlertSound();
          break;
        }
      }
    });
  }


  // -----------------------------------------------------------
  // Your UI Components (UNCHANGED)
  // -----------------------------------------------------------

  void _showStatusDialog(
      BuildContext context, String userId, String sessionType) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Update Session Status"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ["Queue", "Ongoing", "Finished", "Cancelled"]
                .map((status) => ListTile(
                      title: Text(status),
                      onTap: () {
                        controller.updateStatus(
                          context,
                          userId,
                          sessionType,
                          status.toLowerCase(),
                        );
                        Navigator.pop(dialogContext);
                      },
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Cancel")),
          ],
        );
      },
    );
  }

  Widget _buildConsultationSection(
      String title, String status, String sessionType, Color headerColor) {
    return Expanded(
      child: SizedBox(
        height: 320,
        child: Card(
          elevation: 2,
          margin: const EdgeInsets.all(8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                color: headerColor,
                child: Text(
                  "$title ($sessionType)",
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      controller.getConsultationsStream(status, sessionType),
                  builder: (context, snapshot) {
                    if (snapshot.hasError)
                      return const Center(child: Text("Error loading data"));
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No consultations"));
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var data = snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;
                        return _buildSessionCard(context, status, data);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(
      BuildContext context, String status, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("User: ${data["fullName"] ?? "Unknown"}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("Company: ${data["companyId"] ?? "Unknown"}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("Session: ${data["sessionType"] ?? "Unknown"}",
                        style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _buildActionButtons(
              context,
              status,
              data["userId"],
              data["sessionType"],
              data["fullName"] ?? "Unknown",
              data["companyId"] ?? "Unknown",
            ),
          ),
        ],
      ),
    );
  }

  bool get _isOnSessionsRoute {
    final router = GoRouter.of(context);
    final currentRoute =
    router.routeInformationProvider.value.uri.toString();

    return currentRoute.startsWith('/navigation/sessions');
  }

  List<Widget> _buildActionButtons(BuildContext context, String status,
      String userId, String sessionType, String fullName, String companyId) {
    if (status == "queue") {
      return [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text("Admit", style: TextStyle(color: Colors.white)),
          onPressed: () async {
            await controller.admitUser(
                context, userId, sessionType, fullName, companyId);
            controller.openSession(userId, sessionType, fullName, companyId);
          },
        ),
      ];
    }

    if (status == "ongoing" || status == "finished") {
      return [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          onPressed: () => _showStatusDialog(context, userId, sessionType),
          child: const Text("Change Status",
              style: TextStyle(color: Colors.white)),
        ),
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Text("Session Management",
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.012,
                  color: Colors.white,
                )),
          ),
        ),
        backgroundColor: Colors.green[800],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Text("Chat Sessions",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Row(
              children: [
                _buildConsultationSection(
                    "Queue", "queue", "Chat", Colors.blueAccent),
                _buildConsultationSection(
                    "Ongoing", "ongoing", "Chat", Colors.green),
                _buildConsultationSection(
                    "Finished", "finished", "Chat", Colors.orange),
                _buildConsultationSection(
                    "Cancelled", "cancelled", "Chat", Colors.red),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Talk Sessions",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Row(
              children: [
                _buildConsultationSection(
                    "Queue", "queue", "Talk", Colors.blueAccent),
                _buildConsultationSection(
                    "Ongoing", "ongoing", "Talk", Colors.green),
                _buildConsultationSection(
                    "Finished", "finished", "Talk", Colors.orange),
                _buildConsultationSection(
                    "Cancelled", "cancelled", "Talk", Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }



}


