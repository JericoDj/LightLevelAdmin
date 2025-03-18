import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TicketsScreen extends StatefulWidget {
  @override
  _TicketsScreenState createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, List<Map<String, dynamic>>> tickets = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  // ✅ Fetch tickets from Firestore
  Future<void> _fetchTickets() async {
    try {
      final snapshot = await _firestore.collectionGroup('tickets').get();

      final fetchedTickets = <String, List<Map<String, dynamic>>>{};

      for (var doc in snapshot.docs) {
        final ticket = doc.data();
        final ticketType = ticket['type'] ?? 'normal';

        if (!fetchedTickets.containsKey(ticketType)) {
          fetchedTickets[ticketType] = [];
        }

        fetchedTickets[ticketType]?.add({
          "id": ticket['ticketId'],
          "user": ticket['userId'],
          "subject": ticket['title'],
          "status": ticket['status'],
          "created_at": ticket['created_at'],
          "type": ticketType,
        });
      }

      setState(() {
        tickets = fetchedTickets;
        isLoading = false;
      });

    } catch (e) {
      print("❌ Error fetching tickets: $e");
      setState(() => isLoading = false);
    }
  }

  // ✅ Fetch Messages for a specific ticket
  Future<List<Map<String, dynamic>>> _fetchMessages(String ticketId) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('messages')
          .where('ticketId', isEqualTo: ticketId)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print("❌ Error fetching messages: $e");
      return [];
    }
  }

  void _viewTicketDetails(Map<String, dynamic> ticket) async {
    final messages = await _fetchMessages(ticket['id']);

    TextEditingController replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Ticket #${ticket['id']}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 8),
                Text(ticket['subject'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    )),
                const Divider(thickness: 1.5),
                Expanded(
                  child: messages.isEmpty
                      ? const Center(child: Text("No messages yet"))
                      : ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _buildMessageTile(
                          message['sender'], message['message'], message['sender'] == "Support Agent");
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: replyController,
                  decoration: InputDecoration(
                    hintText: "Type your response...",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: () => _sendReply(ticket['id'], replyController.text),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ Send reply and add it to Firestore
  Future<void> _sendReply(String ticketId, String message) async {
    if (message.isEmpty) return;

    try {
      await _firestore
          .collection('support')
          .doc(ticketId)
          .collection('messages')
          .add({
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'sender': 'Support Agent',
      });

      print("✅ Reply sent successfully");
      Navigator.pop(context); // Close the dialog after sending
    } catch (e) {
      print("❌ Error sending reply: $e");
    }
  }

  Widget _buildMessageTile(String sender, String message, bool isSupport) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: isSupport ? Colors.blue[100] : Colors.grey[200],
            child: Icon(isSupport ? Icons.support_agent : Icons.person, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sender, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSupport ? Colors.blue[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(message),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketSection(String title, String status, {bool isImmediate = false}) {
    final filteredTickets = tickets[isImmediate ? 'immediate' : 'normal'] ?? [];

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Chip(
                    label: Text(filteredTickets.length.toString()),
                    backgroundColor: Colors.grey[200],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: filteredTickets.isEmpty
                  ? const Center(child: Text("No tickets available"))
                  : ListView.builder(
                itemCount: filteredTickets.length,
                itemBuilder: (context, index) {
                  final ticket = filteredTickets[index];
                  return ListTile(
                    title: Text(ticket['user']),
                    subtitle: Text(ticket['subject']),
                    onTap: () => _viewTicketDetails(ticket),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Tickets Management'),
        backgroundColor: Colors.blue[800],
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: Row(
              children: [
                _buildTicketSection("Pending", "pending"),
                _buildTicketSection("In Progress", "in-progress"),
                _buildTicketSection("Resolved", "resolved"),
                _buildTicketSection("Cancelled", "cancelled"),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _buildTicketSection("Emergency Queue", "queue", isImmediate: true),
                _buildTicketSection("Active Emergency", "ongoing", isImmediate: true),
                _buildTicketSection("Resolved Emergency", "finished", isImmediate: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _getStatusColor(String status) {
  switch (status) {
    case 'pending': return Colors.orange;
    case 'in-progress': return Colors.blue;
    case 'resolved': return Colors.green;
    case 'cancelled': return Colors.red;
    case 'queue': return Colors.purple;
    case 'ongoing': return Colors.blueAccent;
    case 'finished': return Colors.teal;
    default: return Colors.grey;
  }
}