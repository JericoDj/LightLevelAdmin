import 'package:flutter/material.dart';

class TicketsScreen extends StatefulWidget {
  @override
  _TicketsScreenState createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  List<Map<String, dynamic>> tickets = [
    // Normal Tickets
    {"id": "1", "user": "John Doe", "subject": "App Not Working", "status": "pending", "type": "normal"},
    {"id": "2", "user": "Jane Smith", "subject": "Billing Issue", "status": "in-progress", "type": "normal"},
    {"id": "3", "user": "Michael Brown", "subject": "Feature Request", "status": "resolved", "type": "normal"},
    {"id": "4", "user": "Alice Johnson", "subject": "Login Problem", "status": "cancelled", "type": "normal"},

    // Immediate Concern Tickets
    {"id": "5", "user": "Emily Davis", "subject": "Urgent Payment Issue", "status": "queue", "type": "immediate"},
    {"id": "6", "user": "Daniel Moore", "subject": "Account Compromised", "status": "ongoing", "type": "immediate"},
    {"id": "7", "user": "Sarah Wilson", "subject": "System Outage", "status": "finished", "type": "immediate"},
    {"id": "8", "user": "Chris Lee", "subject": "Security Breach", "status": "finished", "type": "immediate"},
  ];

  void _updateStatus(String ticketId, String newStatus) {
    setState(() {
      tickets.firstWhere((ticket) => ticket["id"] == ticketId)["status"] = newStatus;
    });
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

  void _viewTicketDetails(Map<String, dynamic> ticket) {
    TextEditingController replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: EdgeInsets.all(20),
          child: Container(
            padding: EdgeInsets.all(24),
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Ticket #${ticket['id']}",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  ticket['subject'],
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 16),
                Divider(thickness: 1.5),
                SizedBox(height: 16),

                Expanded(
                  child: ListView(
                    children: [
                      _buildMessageTile("User: ${ticket['user']}", "I'm experiencing an issue with...", false),
                      _buildMessageTile("Support Agent", "Could you please provide more details?", true),
                    ],
                  ),
                ),

                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: replyController,
                        decoration: InputDecoration(
                          hintText: "Type your response...",
                          border: OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.send, color: Colors.blue),
                            onPressed: () => _sendReply(replyController.text),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                        "In Progress",
                        Icons.hourglass_top,
                        Colors.orange,
                            () => _updateStatus(ticket["id"], "in-progress")
                    ),
                    _buildActionButton(
                        "Resolve",
                        Icons.check_circle,
                        Colors.green,
                            () => _updateStatus(ticket["id"], "resolved")
                    ),
                    _buildActionButton(
                        "Cancel",
                        Icons.cancel,
                        Colors.red,
                            () => _updateStatus(ticket["id"], "cancelled")
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageTile(String sender, String message, bool isSupport) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: isSupport ? Colors.blue[100] : Colors.grey[200],
            child: Icon(isSupport ? Icons.support_agent : Icons.person, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sender, style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.all(12),
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

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(text),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _admitImmediateConcern(Map<String, dynamic> ticket) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: EdgeInsets.all(24),
            width: MediaQuery.of(context).size.width * 0.5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Emergency Call",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 24),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blue[100],
                  child: Icon(Icons.emergency, size: 40, color: Colors.red),
                ),
                SizedBox(height: 24),
                Text(
                  "Connecting to ${ticket['user']}...",
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _updateStatus(ticket["id"], "finished");
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: Text("Resolve Issue", style: TextStyle(color: Colors.white)),
                    ),
                    SizedBox(width: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTicketSection(String title, String status, {bool isImmediate = false}) {
    final filteredTickets = tickets.where((t) => t["status"] == status && t["type"] == (isImmediate ? "immediate" : "normal")).toList();

    return Expanded(
      child: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(12),
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
                  SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  Spacer(),
                  Chip(
                    label: Text(filteredTickets.length.toString()),
                    backgroundColor: Colors.grey[200],
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            Expanded(
              child: filteredTickets.isEmpty
                  ? Center(child: Text("No tickets available", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                itemCount: filteredTickets.length,
                itemBuilder: (context, index) {
                  final ticket = filteredTickets[index];
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.grey[200]!, blurRadius: 2)],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      leading: Icon(
                        isImmediate ? Icons.warning_amber : Icons.support_agent,
                        color: isImmediate ? Colors.orange : Colors.blue,
                      ),
                      title: Text(ticket["user"], style: TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(ticket["subject"], overflow: TextOverflow.ellipsis),
                      trailing: isImmediate && ticket["status"] == "queue"
                          ? IconButton(
                        icon: Icon(Icons.emergency, color: Colors.red),
                        onPressed: () => _admitImmediateConcern(ticket),
                      )
                          : null,
                      onTap: !isImmediate ? () => _viewTicketDetails(ticket) : null,
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

  void _sendReply(String message) {
    // Implement reply sending logic
    print("Reply sent: $message");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Support Tickets Management'),
        backgroundColor: Colors.blue[800],
        elevation: 0,
      ),
      body: Column(
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