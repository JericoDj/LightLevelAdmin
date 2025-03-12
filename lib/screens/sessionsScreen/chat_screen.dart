import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ FirebaseAuth for UID

class ChatScreen extends StatefulWidget {
  final String userId;

  const ChatScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String chatRoomId;
  String? currentAdminUid; // ✅ Store admin's UID

  @override
  void initState() {
    super.initState();
    chatRoomId = "safe_talk/chat/sessions/${widget.userId}/messages"; // Firestore path
    _getCurrentAdminUid(); // ✅ Fetch admin's UID
  }

  // ✅ Get the current admin's UID
  void _getCurrentAdminUid() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentAdminUid = user.uid;
      });
      print("✅ Admin UID: $currentAdminUid");
    } else {
      print("❌ ERROR: Admin not logged in!");
    }
  }

  // ✅ Send Message to Firestore (Admin as Sender)
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || currentAdminUid == null) {
      print("❌ ERROR: Message is empty or UID is null");
      return;
    }

    try {
      await FirebaseFirestore.instance.collection(chatRoomId).add({
        "senderId": currentAdminUid, // ✅ Admin UID as sender
        "message": _messageController.text.trim(),
        "timestamp": FieldValue.serverTimestamp(),
      });

      print("✅ Message sent by $currentAdminUid: ${_messageController.text}");
      _messageController.clear();
      _scrollToBottom(); // Scroll down to latest message
    } catch (e) {
      print("❌ ERROR sending message: $e");
    }
  }

  // ✅ Scroll to the latest message
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ✅ Finish Chat - Update Firestore & Close Window
  void _finishChat() async {
    try {
      await FirebaseFirestore.instance.collection("safe_talk/chat/queue").doc(widget.userId).update({
        "status": "finished",
      });

      print("✅ Chat finished for user ${widget.userId}");
      _closeWindow();
    } catch (e) {
      print("❌ ERROR finishing chat: $e");
    }
  }

  // ✅ Cancel Chat - Update Firestore & Close Window
  void _cancelChat() async {
    try {
      await FirebaseFirestore.instance.collection("safe_talk/chat/queue").doc(widget.userId).update({
        "status": "cancelled",
      });

      print("❌ Chat cancelled for user ${widget.userId}");
      _closeWindow();
    } catch (e) {
      print("❌ ERROR cancelling chat: $e");
    }
  }

  // ✅ Close Chat Window
  void _closeWindow() {
    GoRouter.of(context).go('/navigation/sessions'); // Navigate back to Sessions
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat Session with ${widget.userId}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: _closeWindow, // Exit chat
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ Messages List (Real-time updates from Firestore)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(chatRoomId)
                  .orderBy("timestamp", descending: false) // Oldest messages first
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var messageData = messages[index].data() as Map<String, dynamic>;
                    bool isAdmin = messageData["senderId"] == currentAdminUid; // ✅ Check if admin is the sender

                    return Align(
                      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isAdmin ? Colors.blueAccent : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          messageData["message"] ?? "",
                          style: TextStyle(
                            color: isAdmin ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ✅ Chat Action Buttons
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _finishChat,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("Finish Chat"),
                ),
                ElevatedButton(
                  onPressed: _cancelChat,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Cancel Chat"),
                ),
              ],
            ),
          ),

          // ✅ Message Input Field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
