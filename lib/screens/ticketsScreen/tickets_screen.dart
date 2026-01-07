import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../utils/colors.dart';

class TicketsScreen extends StatefulWidget {
  @override
  _TicketsScreenState createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _viewTicketDetails(Map<String, dynamic> ticket) {
    TextEditingController replyController = TextEditingController();
    String currentStatus = ticket['status'] ?? 'Open';

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
                Text("Ticket ID: ${ticket['ticketId']}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 8),
                Text("Title: ${ticket['title']}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    )),
                const SizedBox(height: 8),

                Text("Full Name: ${ticket['fullName'] ?? 'N/A'}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    )),
                const SizedBox(height: 8),
                Text("Company Id: ${ticket['companyId'] ?? 'N/A'}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    )),

                Text("Last Updated: ${_formatTimestamp(ticket['lastUpdated'])}",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    )),
                const SizedBox(height: 8),
                Text("User ID: ${ticket['userId']}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    )),
                const SizedBox(height: 8),

                // Status Dropdown
                Row(
                  children: [
                    const Text("Status: "),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: currentStatus,
                      icon: const Icon(Icons.arrow_drop_down),
                      items: ['Open', 'In Progress', 'Resolved', 'Closed']
                          .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ))
                          .toList(),
                      onChanged: (newStatus) {
                        if (newStatus != null) {
                          _updateTicketStatus(
                              ticket['ticketId'], ticket['userId'], newStatus);
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),

                const Divider(thickness: 1.5),

                // Messages Stream
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('support')
                        .doc(ticket['userId'])
                        .collection('tickets')
                        .doc(ticket['ticketId'])
                        .collection('messages')
                        .orderBy('timestamp', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("No messages yet"));
                      }

                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final data = snapshot.data!.docs[index].data()
                          as Map<String, dynamic>;
                          final isSupportAgent = data['sender'] == 'Support Agent';

                          return Align(
                            alignment: isSupportAgent
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSupportAgent
                                    ? Colors.blue[200]
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: isSupportAgent
                                      ? const Radius.circular(12)
                                      : const Radius.circular(0),
                                  bottomRight: isSupportAgent
                                      ? const Radius.circular(0)
                                      : const Radius.circular(12),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['message'] ?? 'No content',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['timestamp'] != null
                                        ? _formatTimestamp(data['timestamp'])
                                        : '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
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
                      onPressed: () => _sendReply(
                          ticket['ticketId'], ticket['userId'], replyController.text),
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

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    final date = (timestamp as Timestamp).toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _sendReply(String ticketId, String userId, String message) async {
    if (message.isEmpty) return;

    try {
      await _firestore
          .collection('support')
          .doc(userId)
          .collection('tickets')
          .doc(ticketId)
          .collection('messages')
          .add({
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'sender': 'Support Agent',
      });

      // Update lastUpdated when sending reply
      await _firestore
          .collection('support')
          .doc(userId)
          .collection('tickets')
          .doc(ticketId)
          .update({'lastUpdated': FieldValue.serverTimestamp()});

      if (mounted) setState(() {});
      if (Navigator.canPop(context)) Navigator.pop(context);
    } catch (e) {
      print("❌ Error sending reply: $e");
    }
  }

  Future<void> _updateTicketStatus(String ticketId, String userId, String newStatus) async {
    try {
      await _firestore
          .collection('support')
          .doc(userId)
          .collection('tickets')
          .doc(ticketId)
          .update({
        'status': newStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("❌ Error updating status: $e");
    }
  }

  Widget _buildTicketColumn(String status, List<Map<String, dynamic>> tickets) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: _getStatusColor(status),
              child: Text(
                status.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Expanded(
              child: tickets.isEmpty
                  ? const Center(child: Text("No tickets available"))
                  : ListView.builder(
                itemCount: tickets.length,
                itemBuilder: (context, index) {
                  final ticket = tickets[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      title: Text(
                        ticket['title'] ?? 'No Title',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(ticket['status']),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  ticket['status'] ?? 'N/A',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Concern: ${ticket['concern'] ?? 'N/A'}',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Name: ${ticket['fullName'] ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          Text(
                            'Updated: ${_formatTimestamp(ticket['lastUpdated'])}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[600]),
                      onTap: () => _viewTicketDetails(ticket),
                    ),
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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50), // <-- set your desired height here
        child: AppBar(
          title: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Tickets Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: MediaQuery.of(context).size.width * 0.012,
                ),
              ),
            ),
          ),
          backgroundColor: Colors.green[800],
          elevation: 0,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collectionGroup('tickets').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No tickets available"));
          }

          // ✅ Collect and sort tickets
          final sortedTickets = _sortTickets(snapshot.data!.docs);

          // Group tickets by status
          final ticketsByStatus = {
            'Open': <Map<String, dynamic>>[],
            'In Progress': <Map<String, dynamic>>[],
            'Resolved': <Map<String, dynamic>>[],
            'Closed': <Map<String, dynamic>>[],
          };

          for (var ticket in sortedTickets) {
            final status = ticket['status']?.toString() ?? 'Open';
            ticketsByStatus[status]?.add(ticket);
          }

          return Row(
            children: [
              _buildTicketColumn('Open', ticketsByStatus['Open']!),
              _buildTicketColumn('In Progress', ticketsByStatus['In Progress']!),
              _buildTicketColumn('Resolved', ticketsByStatus['Resolved']!),
              _buildTicketColumn('Closed', ticketsByStatus['Closed']!),
            ],
          );
        },
      ),
    );
  }

  // ✅ Sorting Function for Better Control
  List<Map<String, dynamic>> _sortTickets(List<QueryDocumentSnapshot> docs) {
    final sortedTickets = docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    sortedTickets.sort((a, b) {
      final aTime = a['lastUpdated'] is Timestamp
          ? (a['lastUpdated'] as Timestamp).toDate()
          : DateTime(2000); // Default fallback
      final bTime = b['lastUpdated'] is Timestamp
          ? (b['lastUpdated'] as Timestamp).toDate()
          : DateTime(2000); // Default fallback

      return bTime.compareTo(aTime); // ✅ Latest first
    });

    return sortedTickets;
  }


}
Color _getStatusColor(String? status) {
  switch (status?.toLowerCase()) {
    case 'open': return Colors.orange;
    case 'in progress': return Colors.blue;
    case 'resolved': return Colors.green;
    case 'closed': return Colors.red;
    default: return Colors.grey;
  }
}