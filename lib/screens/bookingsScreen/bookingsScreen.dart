import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BookingsScreen extends StatefulWidget {
  @override
  _BookingsScreenState createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Initialize FirebaseAuth
  bool isSpecialist = false; // To store if the current user is a specialist

  // ✅ Sorting Function for Better Control
  List<Map<String, dynamic>> _sortTickets(List<QueryDocumentSnapshot> docs) {
    final sortedTickets = docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'consultation_id': data['consultation_id'] ?? 'Unknown ID',
        'service': data['service'] ?? 'Unknown Service',
        'consultation_type': data['consultation_type'] ?? 'Unknown Type',
        'status': data['status'] ?? 'Requested',
        'specialist': data['specialist'] ?? 'Not Assigned',
        'link': data['meeting_link'] ?? '',
        'lastUpdated': data['lastUpdated'] is Timestamp
            ? (data['lastUpdated'] as Timestamp).toDate()
            : DateTime(2000), // Fallback for null timestamps
      };
    }).toList();

    sortedTickets.sort((a, b) => b['lastUpdated'].compareTo(a['lastUpdated']));

    return sortedTickets;
  }


  // ✅ Check if the current user is a Specialist
  Future<void> _checkIfSpecialist() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('admins').doc(user.uid).get();
        if (userDoc.exists && userDoc['role'] == 'Specialist') {
          setState(() {
            isSpecialist = true; // User is a specialist
          });
        }
      }
    } catch (e) {
      print("❌ Error checking user role: $e");
    }
  }

  // ✅ Fetch Specialists from Admins Collection
  Future<List<String>> _fetchSpecialists() async {
    try {
      final snapshot = await _firestore
          .collection('admins')
          .where('role', isEqualTo: 'Specialist')
          .get();

      return snapshot.docs.map((doc) => doc['fullName'] as String).toList();
    } catch (e) {
      print("❌ Error fetching specialists: $e");
      return [];
    }
  }


  // ✅ Generate Time Options in 5-Minute Increments
  List<String> _generateTimeOptions() {
    List<String> times = [];
    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += 5) {
        final formattedTime =
            '${hour % 12 == 0 ? 12 : hour % 12}:${minute.toString().padLeft(2, '0')} ${hour < 12 ? 'AM' : 'PM'}';
        times.add(formattedTime);
      }
    }
    return times;
  }


  // ✅ Build the Bookings List based on whether the user is a Specialist or not
  Widget _buildBookingsList(List<Map<String, dynamic>> bookings) {
    final requestedBookings = bookings
        .where((booking) => booking['status'].toLowerCase() == 'requested')
        .toList();

    final scheduledBookings = bookings
        .where((booking) => booking['status'].toLowerCase() == 'scheduled')
        .toList();

    final finishedBookings = bookings
        .where((booking) => booking['status'].toLowerCase() == 'finished')
        .toList();

    // If the user is a Specialist, filter only assigned bookings
    if (isSpecialist) {
      final assignedBookings = bookings.where((booking) {
        return booking['specialist'] == _auth.currentUser?.displayName; // Compare with the user's name
      }).toList();

      return Column(
        children: [
          _buildStatusSection("SCHEDULED", assignedBookings, Colors.blue),
          _buildStatusSection("FINISHED", assignedBookings, Colors.green),
        ],
      );
    } else {
      // Regular view for all bookings (including requested)
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusSection("REQUESTED", requestedBookings, Colors.orange),
          _buildStatusSection("SCHEDULED", scheduledBookings, Colors.blue),
          _buildStatusSection("FINISHED", finishedBookings, Colors.green),
        ],
      );
    }
  }

  // ✅ Build Each Status Section
  Widget _buildStatusSection(String title, List<Map<String, dynamic>> bookings, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];

                return GestureDetector(
                  onTap: () => booking['status'].toLowerCase() == 'scheduled'
                      ? _showScheduledBookingActions(booking)
                      : _showBookingDetails(booking),
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    elevation: 3,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      title: Text(booking['service'] ?? 'No Service'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Consultation Type: ${booking['consultation_type']}'),
                          Text(
                            'Specialist: ${booking['specialist'] ?? "Not Assigned"}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildStatusTag(booking['status']),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Dialog to Manage Booking Details
  void _showBookingDetails(Map<String, dynamic> booking) async {
    List<String> specialists = await _fetchSpecialists();
    List<String> timeOptions = _generateTimeOptions();

    TextEditingController linkController = TextEditingController();

    String? selectedSpecialist = booking['specialist'];
    String selectedTime = booking['time'] ?? '12:00 AM';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Booking Details"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Service: ${booking['service']}"),
                Text("Consultation Type: ${booking['consultation_type']}"),
                const SizedBox(height: 10),

                // Specialist Dropdown
                DropdownButtonFormField<String>(
                  value: selectedSpecialist,
                  decoration: const InputDecoration(labelText: "Assign Specialist"),
                  items: specialists.map((specialist) {
                    return DropdownMenuItem<String>(
                      value: specialist,
                      child: Text(specialist),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedSpecialist = value;
                  },
                ),

                // Time Picker
                DropdownButtonFormField<String>(
                  value: selectedTime,
                  decoration: const InputDecoration(labelText: "Select Time"),
                  items: timeOptions.map((time) {
                    return DropdownMenuItem<String>(
                      value: time,
                      child: Text(time),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedTime = value;
                    }
                  },
                ),

                // Date Picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Select Date"),
                  subtitle: Text("${selectedDate.toLocal()}".split(' ')[0]),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      setState(() => selectedDate = pickedDate);
                    }
                  },
                ),

                // Meeting Link
                TextField(
                  controller: linkController,
                  decoration: const InputDecoration(
                    labelText: "Add Meet/Zoom/Teams Link",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _updateBookingDetails(
                  booking['consultation_id'],   // Consultation ID
                  'Scheduled',                  // ✅ Added Status (e.g., 'Scheduled')
                  selectedSpecialist ?? '',     // Specialist
                  selectedTime,                 // Time
                  selectedDate.toIso8601String().split('T')[0],  // Date
                  linkController.text.trim(),   // Meeting Link
                );
                Navigator.pop(context);
              },

              child: const Text("Schedule"), // 🔥 Changed to 'Schedule'
            ),
          ],
        );
      },
    );
  }



  // ✅ Dialog for Scheduled Booking Actions
  void _showScheduledBookingActions(Map<String, dynamic> booking) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Manage Booking"),
          content: const Text("Choose an action:"),
          actions: [
            TextButton(
              onPressed: () {
                _updateBookingDetails(
                  booking['consultation_id'],
                  'Finished',
                  booking['specialist'] ?? 'Not Assigned',
                  booking['time'] ?? '',
                  booking['date_requested'] ?? '',
                  booking['meeting_link'] ?? '',
                );
                Navigator.pop(context);
              },
              child: const Text("Mark as Finished"),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showBookingDetails(booking);
              },
              child: const Text("Reschedule"),
            ),

            TextButton(
              onPressed: () {
                _updateBookingDetails(
                  booking['consultation_id'],
                  'Cancelled',
                  booking['specialist'] ?? 'Not Assigned',
                  booking['time'] ?? '',
                  booking['date_requested'] ?? '',
                  booking['meeting_link'] ?? '',
                );
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }



  // ✅ Update Booking Details in Firestore
  Future<void> _updateBookingDetails(
      String consultationId,
      String status,
      String specialist,
      String time,
      String dateRequested,
      String link,
      ) async {
    try {
      await _firestore.collection('bookings').doc(consultationId).update({
        'status': status,
        if (specialist.isNotEmpty) 'specialist': specialist,
        if (time.isNotEmpty) 'time': time,
        if (dateRequested.isNotEmpty) 'date_requested': dateRequested,
        if (link.isNotEmpty) 'meeting_link': link,
      });

      print("✅ Booking updated successfully");
    } catch (e) {
      print("❌ Error updating booking details: $e");
    }
  }

  // ✅ Status Tag UI
  Widget _buildStatusTag(String status) {
    Color tagColor;

    switch (status.toLowerCase()) {
      case 'requested':
        tagColor = Colors.orange;
        break;
      case 'scheduled':
        tagColor = Colors.blue;
        break;
      case 'finished':
        tagColor = Colors.green;
        break;
      default:
        tagColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tagColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings Management'),
        backgroundColor: Colors.blue[800],
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('bookings').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No bookings available"));
          }

          final sortedBookings = _sortTickets(snapshot.data!.docs);

          return _buildBookingsList(sortedBookings);
        },
      ),
    );
  }
}
