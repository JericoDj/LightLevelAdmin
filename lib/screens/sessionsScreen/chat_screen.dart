import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  String? currentAdminUid;

  @override
  void initState() {
    super.initState();
    chatRoomId = "safe_talk/chat/sessions/${widget.userId}/messages";
    _getCurrentAdminUid();
  }

  void _getCurrentAdminUid() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentAdminUid = user.uid;
      });
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || currentAdminUid == null) return;

    final sessionRef = FirebaseFirestore.instance.collection("safe_talk/chat/queue").doc(widget.userId);
    final sessionSnapshot = await sessionRef.get();

    // Check if chat is finished/cancelled
    if (sessionSnapshot.exists) {
      final status = sessionSnapshot.data()?['status'];
      if (status == "finished" || status == "cancelled") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ This chat session is closed. No more messages allowed.")),
        );
        return;
      }
    }

    await FirebaseFirestore.instance.collection(chatRoomId).add({
      "senderId": currentAdminUid,
      "message": _messageController.text.trim(),
      "timestamp": FieldValue.serverTimestamp(),
    });

    _messageController.clear();
    _scrollToBottom();
  }

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

  void _finishChat() async {
    final sessionRef = FirebaseFirestore.instance.collection("safe_talk/chat/queue").doc(widget.userId);

    try {
      await sessionRef.update({"status": "finished"});

      await FirebaseFirestore.instance.collection(chatRoomId).add({
        "senderId": "system",
        "message": "✅ This chat session has been marked as finished.",
        "timestamp": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Chat session marked as finished.")),
      );

      await Future.delayed(const Duration(seconds: 2));
      _closeWindow();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error finishing chat: $e")),
      );
    }
  }

  void _cancelChat() async {
    final sessionRef = FirebaseFirestore.instance.collection("safe_talk/chat/queue").doc(widget.userId);

    try {
      await sessionRef.update({"status": "cancelled"});

      await FirebaseFirestore.instance.collection(chatRoomId).add({
        "senderId": "system",
        "message": "❌ This chat session has been cancelled.",
        "timestamp": FieldValue.serverTimestamp(),
      });

      _closeWindow();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error cancelling chat: $e")),
      );
    }
  }

  void _closeWindow() {
    GoRouter.of(context).go('/navigation/sessions');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat Session with ${widget.userId}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: _closeWindow,
          ),
        ],
      ),
      body: Column(
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

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index].data() as Map<String, dynamic>;
                    final isAdmin = messageData["senderId"] == currentAdminUid;
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
                .doc(widget.userId)
                .snapshots(),
            builder: (context, snapshot) {
              bool isFinished = false;
              if (snapshot.hasData && snapshot.data!.exists) {
                final status = snapshot.data!["status"];
                isFinished = status == "finished" || status == "cancelled";
              }

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: isFinished
                    ? Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "✅ This chat session has ended. You cannot send messages.",
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                )
                    : Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blueAccent),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
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
        ],
      ),
    );
  }
}
