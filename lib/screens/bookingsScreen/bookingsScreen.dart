import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:http/http.dart' as http;

import '../../controllers/notification_controller.dart';
import '../../utils/user_storage.dart';

class BookingsScreen extends StatefulWidget {
  @override
  _BookingsScreenState createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final NotificationController _notificationController = Get.put(NotificationController());
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isSpecialist = false;
  final RxList<Map<String, dynamic>> bookingsList = <Map<String, dynamic>>[].obs;
  String? fullName;

  @override
  void initState() {
    super.initState();
    final role = UserStorage.getUserRole();
    isSpecialist = role == 'Specialist';
    final userData = UserStorage.getUser();
    fullName = userData?['full_name'] ?? '';
    setState(() {});
  }

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
        'full_name': data['full_name'] ?? '',
        'phone': data['phone'] ?? '',
        'company_id': data['company_id'] ?? '',
        'result_link': data['result_link'] ?? '', // Added result link
        'lastUpdated': data['lastUpdated'] is Timestamp
            ? (data['lastUpdated'] as Timestamp).toDate()
            : DateTime(2000),
        'time': data['time'] ?? '',
        'date_requested': data['date_requested'] ?? '',
      };
    }).toList();

    sortedTickets.sort((a, b) => b['lastUpdated'].compareTo(a['lastUpdated']));
    return sortedTickets;
  }

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

  Widget _buildBookingsList(List<Map<String, dynamic>> bookings) {
    if (isSpecialist) {
      final assigned = bookings.where((b) {
        return (b['specialist']?.toString().trim() ?? '') == fullName?.trim();
      }).toList();

      final scheduled = assigned.where((b) => b['status'].toLowerCase() == 'scheduled').toList();
      final finished = assigned.where((b) => b['status'].toLowerCase() == 'finished').toList();

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusSection("SCHEDULED", scheduled, Colors.blue),
          _buildStatusSection("FINISHED", finished, Colors.green),
        ],
      );
    } else {
      final requested = bookings.where((b) => b['status'].toLowerCase() == 'requested').toList();
      final scheduled = bookings.where((b) => b['status'].toLowerCase() == 'scheduled').toList();
      final finished = bookings.where((b) => b['status'].toLowerCase() == 'finished').toList();

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusSection("REQUESTED", requested, Colors.orange),
          _buildStatusSection("SCHEDULED", scheduled, Colors.blue),
          _buildStatusSection("FINISHED", finished, Colors.green),
        ],
      );
    }
  }

  Widget _buildStatusSection(
      String title, List<Map<String, dynamic>> bookings, Color color) {
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
                final isFinished = booking['status'].toLowerCase() == 'finished';

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
                          Text('Full Name: ${booking['full_name']}'),
                          Text('Phone: ${booking['phone']}'),
                          Text('Company ID: ${booking['company_id']}'),
                          const SizedBox(height: 4),
                          Text(
                            'Specialist: ${booking['specialist'] ?? "Not Assigned"}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),

                          // Show meeting link for scheduled/finished
                          if (booking['link']?.isNotEmpty ?? false)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Meeting Link: ${booking['link']}',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),

                          // Show result link for finished
                          if (isFinished && (booking['result_link']?.isNotEmpty ?? false))
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Result Link: ${booking['result_link']}',
                                style: TextStyle(color: Colors.green),
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

  void _showBookingDetails(Map<String, dynamic> booking) async {
    print("📦 Booking passed into dialog:");
    print(booking);

    List<String> specialists = await _fetchSpecialists();
    List<String> timeOptions = _generateTimeOptions();

    String fallbackTime = '12:00 AM';

    // Get and normalize the booking time
    String? bookingTime = booking['time'];
    print(bookingTime);
    String? selectedTime = bookingTime;

    if (bookingTime != null && bookingTime
        .trim()
        .isNotEmpty) {
      final normalized = bookingTime.trim();
      selectedTime = timeOptions.firstWhere(
            (t) => t.trim().toLowerCase() == normalized.toLowerCase(),
        orElse: () {
          print("⚠️ Time '${normalized}' not found in list. Falling back.");
          return fallbackTime;
        },
      );
    }

    print("⏰ Selected time initialized to: $selectedTime");

    // Prepare specialists list with fallback
    final specialistList = {'Not Assigned', ...specialists}.toSet().toList();

    TextEditingController linkController =
    TextEditingController(text: booking['link'] ?? '');


    String? selectedSpecialist = booking['specialist'];
    if (selectedSpecialist == null ||
        !specialistList.contains(selectedSpecialist)) {
      selectedSpecialist = 'Not Assigned';
    }

    DateTime selectedDate =
        DateTime.tryParse(booking['date_requested'] ?? '') ?? DateTime.now();

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

                // Specialist Picker
                DropdownButtonFormField<String>(
                  value: selectedSpecialist,
                  decoration: const InputDecoration(
                      labelText: "Assign Specialist"),
                  items: specialistList.map((specialist) {
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
              onPressed: () async {
                String? consultationId = booking['consultation_id'];
                if (consultationId == null) {
                  print("❌ consultation_id is missing");
                  return;
                }

                String? fullName = booking['full_name'];
                if (fullName == null) {
                  print("❌ full_name is missing");
                  return;
                }

                // Get FCM token from users collection
                String? userFcmToken;
                try {
                  final querySnapshot = await FirebaseFirestore.instance
                      .collection('users')
                      .where('fullName', isEqualTo: fullName)
                      .limit(1)
                      .get();

                  if (querySnapshot.docs.isNotEmpty) {
                    final userDoc = querySnapshot.docs.first;
                    userFcmToken = userDoc.data()['fcmToken'];
                  }
                } catch (e) {
                  print("❌ Error fetching user: $e");
                }

                if (userFcmToken != null) {
                  await _notificationController.sendNotificationToToken(
                    userFcmToken,
                    "Booking Scheduled",
                    "Your booking has been successfully scheduled.",
                  );
                }

                await _updateBookingDetails(
                  consultationId,
                  'Scheduled',
                  selectedSpecialist ?? '',
                  selectedTime ?? "",
                  selectedDate.toIso8601String().split('T')[0],
                  linkController.text.trim(),
                );

                Navigator.pop(context);
              },
              child: const Text("Schedule"),
            ),
          ],
        );
      },
    );
  }


  Future<void> _updateBookingDetails(
      String consultationId,
      String status,
      String specialist,
      String time,
      String dateRequested,
      String link, {
        String? resultLink,
      }) async {
    try {
      Map<String, dynamic> updateData = {
        'status': status,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (specialist.isNotEmpty) updateData['specialist'] = specialist;
      if (time.isNotEmpty) updateData['time'] = time;
      if (dateRequested.isNotEmpty) updateData['date_requested'] = dateRequested;
      if (link.isNotEmpty) updateData['meeting_link'] = link;
      if (resultLink != null && resultLink.isNotEmpty) updateData['result_link'] = resultLink;

      await _firestore.collection('bookings').doc(consultationId).update(updateData);
      print("✅ Booking updated: $consultationId");
    } catch (e) {
      print("❌ Update error: $e");
    }
  }

  void _showScheduledBookingActions(Map<String, dynamic> booking) async {
    String consultationId = booking['consultation_id'];
    String? date = booking['date_requested'];
    String? time = booking['time'];

    // Fetch from Firestore if missing locally
    if (date == null || time == null || date.isEmpty || time.isEmpty) {
      try {
        DocumentSnapshot doc = await _firestore.collection('bookings').doc(consultationId).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          date = data['date_requested'] ?? '';
          time = data['time'] ?? '';
        }
      } catch (e) {
        print("❌ Firestore fetch error: $e");
      }
    }

    String formattedDateTime = date != null && time != null ? "$date at $time" : 'N/A';
    TextEditingController resultLinkController = TextEditingController(text: booking['result_link'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
            title: const Text("Manage Booking"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("👤 Full Name: ${booking['full_name'] ?? 'N/A'}"),
                  Text("📱 Phone: ${booking['phone'] ?? 'N/A'}"),
                  Text("🏢 Company ID: ${booking['company_id'] ?? 'N/A'}"),
                  Text("📅 Scheduled For: $formattedDateTime"),
                  Text("💬 Consultation Type: ${booking['consultation_type'] ?? 'N/A'}"),

                  // Display meeting link
                  if (booking['link']?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "🔗 Meeting Link: ${booking['link']}",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),

                  const SizedBox(height: 12),
                  const Text("📁 Drive Result Link"),
                  TextField(
                    controller: resultLinkController,
                    decoration: const InputDecoration(
                      hintText: "Paste Google Drive result link here...",
                    ),
                  ),
                ],
              ),
            ),
            actions: [
        // Mark as Finished button
        Row(
          children: [
            ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
            _updateBookingDetails(
            consultationId,
            'Finished',
            booking['specialist'] ?? 'Not Assigned',
            time ?? '',
            date ?? '',
            booking['link'] ?? '',
            resultLink: resultLinkController.text.trim(),
            );
            Navigator.pop(context);
            },
            child: const Text("Mark as Finished", style: TextStyle(color: Colors.white)),

            // Reschedule button
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
                // _updateBookingDetails(
                //   consultationId,
                //   'Cancelled',
                //   booking['specialist'] ?? 'Not Assigned',
                //   time ?? '',
                //   date ?? '',
                //   booking['meeting_link'] ?? '',
                //   resultLink: resultLinkController.text.trim(), // ✅ New param
                // );
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
          ],
        )
        ],
        );
      },
    );
  }

  Widget _buildStatusTag(String status) {
    Color tagColor = Colors.grey;

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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBar(
          title:  Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Booking Management',
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
        stream: _firestore.collection('bookings').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No bookings available"));
          }

          bookingsList.value = _sortTickets(snapshot.data!.docs);
          return Obx(() => _buildBookingsList(bookingsList));
        },
      ),
    );
  }
}