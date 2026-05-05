import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lightlevelpsychosolutionsadmin/utils/colors.dart';

class UserTrackingScreen extends StatefulWidget {
  const UserTrackingScreen({Key? key}) : super(key: key);

  @override
  _UserTrackingScreenState createState() => _UserTrackingScreenState();
}

class _UserTrackingScreenState extends State<UserTrackingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? selectedCompanyId;
  String? selectedCompanyName;
  String? selectedUserName;
  DateTime selectedDate = DateTime.now();

  List<Map<String, dynamic>> companies = [];
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> trackingLogs = [];
  List<String> availableDates = [];

  bool isLoadingCompanies = true;
  bool isLoadingUsers = false;
  bool isLoadingLogs = false;
  bool isLoadingDates = false;

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    setState(() => isLoadingCompanies = true);
    try {
      final snapshot = await _firestore.collection('companies').get();
      setState(() {
        companies = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Unknown Company',
          };
        }).toList();
        isLoadingCompanies = false;
      });
    } catch (e) {
      debugPrint("Error fetching companies: $e");
      setState(() => isLoadingCompanies = false);
    }
  }

  Future<void> _fetchUsers(String companyId) async {
    setState(() {
      selectedCompanyId = companyId;
      selectedCompanyName = companies.firstWhere((c) => c['id'] == companyId)['name'];
      selectedUserName = null;
      users = [];
      trackingLogs = [];
      availableDates = [];
      isLoadingUsers = true;
    });

    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('users')
          .get();

      setState(() {
        users = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Unknown User',
            'email': data['email'] ?? '',
          };
        }).toList();
        isLoadingUsers = false;
      });
    } catch (e) {
      debugPrint("Error fetching users: $e");
      setState(() => isLoadingUsers = false);
    }
  }

  Future<void> _fetchAvailableDates(String userName) async {
    setState(() {
      selectedUserName = userName;
      isLoadingDates = true;
      availableDates = [];
      trackingLogs = [];
    });

    if (selectedCompanyId == null) return;

    try {
      // Fetch everything under this user to discover dates
      final snapshot = await _firestore
          .collection('user_tracking')
          .doc(selectedCompanyId)
          .collection(userName)
          .get();

      Set<String> dateSet = {};

      for (var doc in snapshot.docs) {
        final id = doc.id;
        final data = doc.data();

        // 1. Check if it's a new date folder (yyyy-MM-dd)
        if (DateTime.tryParse(id) != null && id.length == 10) {
          dateSet.add(id);
        } else {
          // 2. Check if it's an old flat log (random ID) and get date from timestamp
          final ts = data['timestamp'] as Timestamp?;
          if (ts != null) {
            final dateStr = DateFormat('yyyy-MM-dd').format(ts.toDate());
            dateSet.add(dateStr);
          }
        }
      }

      final dates = dateSet.toList();
      dates.sort((a, b) => b.compareTo(a)); // Newest first

      setState(() {
        availableDates = dates;
        isLoadingDates = false;
        if (dates.isNotEmpty) {
          final firstDate = dates.first;
          selectedDate = DateTime.parse(firstDate);
          _fetchTrackingLogs(firstDate);
        }
      });
    } catch (e) {
      debugPrint("Error fetching available dates: $e");
      setState(() => isLoadingDates = false);
    }
  }

  Future<void> _fetchTrackingLogs(String dateStr) async {
    setState(() {
      isLoadingLogs = true;
      trackingLogs = [];
      selectedDate = DateTime.parse(dateStr);
    });

    if (selectedCompanyId == null || selectedUserName == null) return;

    try {
      List<Map<String, dynamic>> combinedLogs = [];

      // 1. Fetch NEW grouped logs
      final newSnapshot = await _firestore
          .collection('user_tracking')
          .doc(selectedCompanyId)
          .collection(selectedUserName!)
          .doc(dateStr)
          .collection('logs')
          .orderBy('timestamp', descending: true)
          .get();
      
      combinedLogs.addAll(newSnapshot.docs.map((doc) => doc.data()));

      // 2. Fetch OLD flat logs (filtered by date)
      final oldSnapshot = await _firestore
          .collection('user_tracking')
          .doc(selectedCompanyId)
          .collection(selectedUserName!)
          .get();

      final oldFilteredLogs = oldSnapshot.docs
          .where((doc) {
            final data = doc.data();
            final ts = data['timestamp'] as Timestamp?;
            if (ts == null || !data.containsKey('feature')) return false;

            final logDate = DateFormat('yyyy-MM-dd').format(ts.toDate());
            return logDate == dateStr;
          })
          .map((doc) => doc.data())
          .toList();

      combinedLogs.addAll(oldFilteredLogs);

      // Sort by timestamp descending
      combinedLogs.sort((a, b) {
        final tsA = a['timestamp'] as Timestamp?;
        final tsB = b['timestamp'] as Timestamp?;
        if (tsA == null || tsB == null) return 0;
        return tsB.compareTo(tsA);
      });

      setState(() {
        trackingLogs = combinedLogs;
        isLoadingLogs = false;
      });
    } catch (e) {
      debugPrint("Error fetching tracking logs: $e");
      setState(() => isLoadingLogs = false);
    }
  }

  Map<String, dynamic> _calculateMetrics() {
    if (trackingLogs.isEmpty) {
      return {
        'totalInteractions': 0,
        'totalTimeSpent': 0,
        'mostActiveFeature': 'N/A',
      };
    }

    int totalInteractions = trackingLogs.length;
    int totalTimeSpent = 0;
    Map<String, int> featureCounts = {};

    for (var log in trackingLogs) {
      int duration = log['durationSeconds'] ?? 0;
      totalTimeSpent += duration;

      String feature = log['feature'] ?? 'Unknown';
      featureCounts[feature] = (featureCounts[feature] ?? 0) + 1;
    }

    String mostActiveFeature = 'N/A';
    int maxCount = 0;
    featureCounts.forEach((feature, count) {
      if (count > maxCount) {
        maxCount = count;
        mostActiveFeature = feature;
      }
    });

    return {
      'totalInteractions': totalInteractions,
      'totalTimeSpent': totalTimeSpent,
      'mostActiveFeature': mostActiveFeature,
    };
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}m ${seconds % 60}s';
    return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: MyColors.color1,
              onPrimary: Colors.white,
              onSurface: MyColors.color1,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: MyColors.color1,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(picked);
      _fetchTrackingLogs(dateStr);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "User Tracking & Interactions",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: MyColors.color1,
            ),
          ),
          const SizedBox(height: 20),

          // Selectors Row
          Row(
            children: [
              Expanded(child: _buildCompanyDropdown()),
              const SizedBox(width: 20),
              Expanded(child: _buildUserDropdown()),
            ],
          ),
          const SizedBox(height: 16),

          // Date selector row
          if (selectedUserName != null && availableDates.isNotEmpty)
            _buildDateSelector(),

          const SizedBox(height: 20),

          if (isLoadingLogs || isLoadingDates)
            const Center(child: CircularProgressIndicator())
          else if (selectedUserName != null)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetricsRow(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text(
                        "Interaction Logs",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "— ${DateFormat('MMMM dd, yyyy').format(selectedDate)}",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      Text(
                        "${trackingLogs.length} events",
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(child: _buildLogsTable()),
                ],
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Text("Select a company and user to view tracking logs."),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: MyColors.color1),
            onPressed: () => _selectDate(context),
            tooltip: 'Pick a date',
          ),
          const SizedBox(width: 5),
          const Text("Date:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: availableDates.length,
              itemBuilder: (context, index) {
                final dateStr = availableDates[index];
                final date = DateTime.parse(dateStr);
                final isSelected = DateFormat('yyyy-MM-dd').format(selectedDate) == dateStr;
                final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateStr;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(
                      isToday ? "Today" : DateFormat('MMM dd').format(date),
                      style: TextStyle(
                        color: isSelected ? Colors.white : MyColors.color1,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: MyColors.color1,
                    backgroundColor: Colors.grey[100],
                    onSelected: (selected) {
                      if (selected) {
                        _fetchTrackingLogs(dateStr);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyDropdown() {
    if (isLoadingCompanies) return const CircularProgressIndicator();

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: "Select Company",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      value: selectedCompanyId,
      items: companies.map((company) {
        return DropdownMenuItem<String>(
          value: company['id'],
          child: Text(company['name']),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) _fetchUsers(value);
      },
    );
  }

  Widget _buildUserDropdown() {
    if (selectedCompanyId == null) {
      return DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: "Select User",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: const [],
        onChanged: null,
      );
    }

    if (isLoadingUsers) return const CircularProgressIndicator();

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: "Select User",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      value: selectedUserName,
      items: users.map((user) {
        return DropdownMenuItem<String>(
          value: user['name'],
          child: Text("${user['name']} (${user['email']})"),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) _fetchAvailableDates(value);
      },
    );
  }

  Widget _buildMetricsRow() {
    final metrics = _calculateMetrics();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMetricCard("Total Interactions", "${metrics['totalInteractions']}", Icons.touch_app),
        _buildMetricCard("Total Time Spent", _formatDuration(metrics['totalTimeSpent']), Icons.timer),
        _buildMetricCard("Most Active Feature", metrics['mostActiveFeature'], Icons.star),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(icon, size: 40, color: MyColors.color2),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 5),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: MyColors.color1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogsTable() {
    if (trackingLogs.isEmpty) {
      return const Center(child: Text("No tracking logs found for this date."));
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        itemCount: trackingLogs.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final log = trackingLogs[index];
          final timestamp = log['timestamp'] as Timestamp?;
          final timeStr = timestamp != null
              ? DateFormat('hh:mm:ss a').format(timestamp.toDate())
              : 'N/A';
          final action = log['action'] ?? 'unknown';
          final duration = log['durationSeconds'];

          // Color-code by action type
          Color actionColor;
          IconData actionIcon;
          switch (action) {
            case 'time_spent':
              actionColor = Colors.blue;
              actionIcon = Icons.timer;
              break;
            case 'click':
              actionColor = Colors.green;
              actionIcon = Icons.touch_app;
              break;
            case 'tab_switch':
              actionColor = Colors.orange;
              actionIcon = Icons.swap_horiz;
              break;
            default:
              actionColor = Colors.grey;
              actionIcon = Icons.history;
          }

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: actionColor.withValues(alpha: 0.1),
              child: Icon(actionIcon, color: actionColor),
            ),
            title: Text(
              "${log['feature']} — ${log['itemName']}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Action: $action${duration != null ? ' • Duration: ${_formatDuration(duration)}' : ''}",
            ),
            trailing: Text(
              timeStr,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          );
        },
      ),
    );
  }
}
