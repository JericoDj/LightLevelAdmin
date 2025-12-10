import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../utils/colors.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String fullName;
  final String companyId;

  const ChatScreen({Key? key, required this.userId ,required this.fullName , required this.companyId}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}
// relay1.expressturn.com:3480

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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentAdminUid == null) return;

    final sessionRef = FirebaseFirestore.instance
        .collection("safe_talk/chat/queue")
        .doc(widget.userId);

    final sessionSnapshot = await sessionRef.get();

    if (!mounted) return; // ✅ important

    // Check if chat is finished/cancelled
    if (sessionSnapshot.exists) {
      final status = sessionSnapshot.data()?['status'];
      if (status == "finished" || status == "cancelled") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ This chat session is closed. No more messages allowed."),
          ),
        );
        return;
      }
    }

    // ✅ Cache message before await
    await FirebaseFirestore.instance.collection(chatRoomId).add({
      "senderId": currentAdminUid,
      "message": text,
      "timestamp": FieldValue.serverTimestamp(),
    });

    if (!mounted) return; // ✅ protect UI calls

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
      // Update the queue status
      await sessionRef.update({"status": "finished"});

      // Add system message
      await FirebaseFirestore.instance.collection(chatRoomId).add({
        "senderId": "system",
        "message": "✅ This chat session has been marked as finished.",
        "timestamp": FieldValue.serverTimestamp(),
      });

      // Fetch all messages
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection(chatRoomId)
          .orderBy("timestamp", descending: false)
          .get();

      List<Map<String, dynamic>> messages = messagesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "senderId": data["senderId"],
          "message": data["message"],
          "timestamp": (data["timestamp"] as Timestamp?)?.toDate().toIso8601String() ?? "",
        };
      }).toList();

      // Save to report
      final timestamp = DateTime.now();
      final reportRef = FirebaseFirestore.instance
          .collection("reports")
          .doc("chatSessions")
          .collection(widget.companyId)
          .doc("chats")
          .collection(widget.fullName)
          .doc(timestamp.toIso8601String());

      await reportRef.set({
        "companyId": widget.companyId,
        "userId": widget.userId,
        "fullName": widget.fullName,
        "adminId": currentAdminUid,
        "status": "finished",
        "timestamp": timestamp,
        "messages": messages, // 🔥 full message list
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
    final sessionRef = FirebaseFirestore.instance
        .collection("safe_talk/chat/queue")
        .doc(widget.userId);

    try {
      // Update the queue status
      await sessionRef.update({"status": "cancelled"});

      // Add system message
      await FirebaseFirestore.instance.collection(chatRoomId).add({
        "senderId": "system",
        "message": "❌ This chat session has been cancelled.",
        "timestamp": FieldValue.serverTimestamp(),
      });

      // Fetch all messages
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection(chatRoomId)
          .orderBy("timestamp", descending: false)
          .get();

      List<Map<String, dynamic>> messages = messagesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "senderId": data["senderId"],
          "message": data["message"],
          "timestamp": (data["timestamp"] as Timestamp?)?.toDate().toIso8601String() ?? "",
        };
      }).toList();

      // Save to report
      final timestamp = DateTime.now();
      final reportRef = FirebaseFirestore.instance
          .collection("reports")
          .doc("sessions")
          .collection(widget.companyId)
          .doc("chats")
          .collection(widget.fullName)
          .doc(timestamp.toIso8601String());

      await reportRef.set({
        "companyId": widget.companyId,
        "userId": widget.userId,
        "fullName": widget.fullName,
        "adminId": currentAdminUid,
        "status": "cancelled",
        "timestamp": timestamp,
        "messages": messages,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Chat session cancelled and saved.")),
      );

      await Future.delayed(const Duration(seconds: 1));
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

        title:


        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

        Container(child: Text("Chat Session with ${widget.fullName}")),
          Container(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _finishChat,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("Finish Chat", style: TextStyle(color: Colors.white),),
                ),
                const SizedBox(width: 10,),
                ElevatedButton(
                  onPressed: _cancelChat,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Cancel Chat", style: TextStyle(color: Colors.white),),
                ),
              ],
            ),
          ),)


        ],),
        automaticallyImplyLeading: false,

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
                        maxLines: 3, // ✅ REQUIRED FOR WEB
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) =>{
                          _sendMessage()
                        }, // ✅ Enter triggers
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: MyColors.color2),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              );
            },
          ),

        ],
      ),
    );
  }
}
