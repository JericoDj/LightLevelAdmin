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
  // Selected users, keyed by email (unique) instead of name, because two users
  // can share the same display name. Users without an email use a synthetic
  // 'no-email:{docId}' key.
  Set<String> selectedUserKeys = {};
  DateTime selectedDate = DateTime.now();

  List<Map<String, dynamic>> companies = [];
  // Each user's 'name' is users/{uid}.fullName — the exact name the app uses
  // for the user_tracking/{companyId}/{fullName} path, so logs are found.
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> trackingLogs = [];
  List<String> availableDates = [];

  // Top-level user_tracking docs per selected user (date folders + old flat
  // logs), fetched once per selection and reused when switching dates.
  Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> rootDocsByUser = {};

  bool isLoadingCompanies = true;
  bool isLoadingUsers = false;
  bool isLoadingLogs = false;
  bool isLoadingDates = false;

  // Guards against slower, outdated requests overwriting newer results
  int _selectionRequestId = 0;
  int _logsRequestId = 0;

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  List<Map<String, dynamic>> get _selectedUsers =>
      users.where((u) => selectedUserKeys.contains(u['key'])).toList();

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
    _selectionRequestId++;
    _logsRequestId++;
    setState(() {
      selectedCompanyId = companyId;
      selectedCompanyName = companies.firstWhere((c) => c['id'] == companyId)['name'];
      selectedUserKeys = {};
      users = [];
      trackingLogs = [];
      availableDates = [];
      rootDocsByUser = {};
      isLoadingUsers = true;
      isLoadingDates = false;
      isLoadingLogs = false;
    });

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('companyId', isEqualTo: companyId)
          .get();

      setState(() {
        // Dedupe by email so each user appears once.
        final Map<String, Map<String, dynamic>> byEmail = {};
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final email = (data['email'] ?? '').toString();
          final key = email.isNotEmpty ? email : 'no-email:${doc.id}';
          byEmail.putIfAbsent(
            key,
            () => {
              'id': doc.id,
              'name': data['fullName'] ?? data['name'] ?? 'Unknown User',
              'email': email,
              'key': key,
            },
          );
        }
        users = byEmail.values.toList()
          ..sort((a, b) => a['name'].toString().toLowerCase().compareTo(b['name'].toString().toLowerCase()));
        isLoadingUsers = false;
      });
    } catch (e) {
      debugPrint("Error fetching users: $e");
      setState(() => isLoadingUsers = false);
    }
  }

  // Loads the available dates for every selected user (union of all dates),
  // then loads the logs for the newest date.
  Future<void> _applyUserSelection(Set<String> keys) async {
    final requestId = ++_selectionRequestId;
    _logsRequestId++;

    setState(() {
      selectedUserKeys = keys;
      availableDates = [];
      trackingLogs = [];
      rootDocsByUser = {};
      isLoadingLogs = false;
      isLoadingDates = keys.isNotEmpty;
    });

    if (keys.isEmpty || selectedCompanyId == null) return;

    final results = await Future.wait(_selectedUsers.map((user) async {
      try {
        final snapshot = await _firestore
            .collection('user_tracking')
            .doc(selectedCompanyId)
            .collection(user['name'].toString())
            .get();
        return MapEntry(user['key'] as String, snapshot.docs);
      } catch (e) {
        debugPrint("Error fetching tracking dates for ${user['name']}: $e");
        return MapEntry(user['key'] as String, <QueryDocumentSnapshot<Map<String, dynamic>>>[]);
      }
    }));

    if (!mounted || requestId != _selectionRequestId) return;

    final docsByUser = Map.fromEntries(results);
    final Set<String> dateSet = {};

    for (final docs in docsByUser.values) {
      for (final doc in docs) {
        final id = doc.id;
        // 1. New date folder (yyyy-MM-dd)
        if (DateTime.tryParse(id) != null && id.length == 10) {
          dateSet.add(id);
        } else {
          // 2. Old flat log (random ID) — get the date from its timestamp
          final ts = doc.data()['timestamp'];
          if (ts is Timestamp) {
            dateSet.add(DateFormat('yyyy-MM-dd').format(ts.toDate()));
          }
        }
      }
    }

    final dates = dateSet.toList()..sort((a, b) => b.compareTo(a)); // Newest first

    setState(() {
      rootDocsByUser = docsByUser;
      availableDates = dates;
      isLoadingDates = false;
    });

    if (dates.isNotEmpty) _fetchTrackingLogs(dates.first);
  }

  Future<void> _fetchTrackingLogs(String dateStr) async {
    final requestId = ++_logsRequestId;
    setState(() {
      isLoadingLogs = true;
      trackingLogs = [];
      selectedDate = DateTime.parse(dateStr);
    });

    if (selectedCompanyId == null || selectedUserKeys.isEmpty) {
      setState(() => isLoadingLogs = false);
      return;
    }

    final perUserLogs = await Future.wait(_selectedUsers.map((user) async {
      final userKey = user['key'] as String;
      final userName = user['name'].toString();
      final List<Map<String, dynamic>> logs = [];

      try {
        // 1. NEW grouped logs
        final newSnapshot = await _firestore
            .collection('user_tracking')
            .doc(selectedCompanyId)
            .collection(userName)
            .doc(dateStr)
            .collection('logs')
            .orderBy('timestamp', descending: true)
            .get();
        logs.addAll(newSnapshot.docs.map((doc) => doc.data()));
      } catch (e) {
        debugPrint("Error fetching tracking logs for $userName: $e");
      }

      // 2. OLD flat logs (filtered by date)
      for (final doc in rootDocsByUser[userKey] ?? []) {
        final data = doc.data();
        final ts = data['timestamp'];
        if (ts is! Timestamp || !data.containsKey('feature')) continue;
        if (DateFormat('yyyy-MM-dd').format(ts.toDate()) == dateStr) logs.add(data);
      }

      // Tag each log with its user for the combined view
      return logs.map((log) => {...log, '_userKey': userKey, '_userName': userName}).toList();
    }));

    if (!mounted || requestId != _logsRequestId) return;

    final combinedLogs = perUserLogs.expand((logs) => logs).toList()
      ..sort((a, b) {
        final tsA = a['timestamp'] as Timestamp?;
        final tsB = b['timestamp'] as Timestamp?;
        if (tsA == null || tsB == null) return 0;
        return tsB.compareTo(tsA);
      });

    setState(() {
      trackingLogs = combinedLogs;
      isLoadingLogs = false;
    });
  }

  int _durationOf(Map<String, dynamic> log) {
    final value = log['durationSeconds'];
    return value is num ? value.toInt() : 0;
  }

  String _topKey(Map<String, int> counts) {
    String top = 'N/A';
    int maxCount = 0;
    counts.forEach((key, count) {
      if (count > maxCount) {
        maxCount = count;
        top = key;
      }
    });
    return top;
  }

  Map<String, dynamic> _calculateMetrics() {
    int totalTimeSpent = 0;
    final Map<String, int> featureCounts = {};
    final Set<String> activeUsers = {};

    for (final log in trackingLogs) {
      totalTimeSpent += _durationOf(log);
      final feature = (log['feature'] ?? 'Unknown').toString();
      featureCounts[feature] = (featureCounts[feature] ?? 0) + 1;
      activeUsers.add(log['_userKey'].toString());
    }

    return {
      'totalInteractions': trackingLogs.length,
      'totalTimeSpent': totalTimeSpent,
      'mostActiveFeature': _topKey(featureCounts),
      'activeUsers': activeUsers.length,
    };
  }

  // Per-user contribution to the selected day's activity. Every selected user
  // is included (with zeros if inactive), sorted by interactions.
  List<Map<String, dynamic>> _calculateUserContributions() {
    final Map<String, Map<String, dynamic>> stats = {
      for (final user in _selectedUsers)
        user['key']: {
          'name': user['name'],
          'email': user['email'],
          'interactions': 0,
          'timeSpent': 0,
          'features': <String, int>{},
        },
    };

    for (final log in trackingLogs) {
      final entry = stats[log['_userKey']];
      if (entry == null) continue;
      entry['interactions'] += 1;
      entry['timeSpent'] += _durationOf(log);
      final features = entry['features'] as Map<String, int>;
      final feature = (log['feature'] ?? 'Unknown').toString();
      features[feature] = (features[feature] ?? 0) + 1;
    }

    final total = trackingLogs.length;
    final list = stats.values.map((entry) {
      return {
        ...entry,
        'topFeature': _topKey(entry['features'] as Map<String, int>),
        'share': total == 0 ? 0.0 : (entry['interactions'] as int) / total,
      };
    }).toList();

    list.sort((a, b) => (b['interactions'] as int).compareTo(a['interactions'] as int));
    return list;
  }

  // Activity per feature across all selected users
  List<Map<String, dynamic>> _calculateFeatureBreakdown() {
    final Map<String, Map<String, dynamic>> stats = {};

    for (final log in trackingLogs) {
      final feature = (log['feature'] ?? 'Unknown').toString();
      final entry = stats.putIfAbsent(
        feature,
        () => {'feature': feature, 'interactions': 0, 'timeSpent': 0, 'users': <String>{}},
      );
      entry['interactions'] += 1;
      entry['timeSpent'] += _durationOf(log);
      (entry['users'] as Set<String>).add(log['_userKey'].toString());
    }

    final total = trackingLogs.length;
    final list = stats.values.map((entry) {
      return {
        ...entry,
        'userCount': (entry['users'] as Set<String>).length,
        'share': total == 0 ? 0.0 : (entry['interactions'] as int) / total,
      };
    }).toList();

    list.sort((a, b) => (b['interactions'] as int).compareTo(a['interactions'] as int));
    return list;
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
            "Telemetry & Interactions",
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
              Expanded(child: _buildUserSelector()),
            ],
          ),
          const SizedBox(height: 16),

          // Date selector row
          if (selectedUserKeys.isNotEmpty && availableDates.isNotEmpty)
            _buildDateSelector(),

          const SizedBox(height: 20),

          if (isLoadingLogs || isLoadingDates)
            const Center(child: CircularProgressIndicator())
          else if (selectedUserKeys.isNotEmpty && availableDates.isEmpty)
            const Expanded(
              child: Center(child: Text("No tracking logs found for the selected users.")),
            )
          else if (selectedUserKeys.isNotEmpty)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetricsRow(),
                  const SizedBox(height: 20),
                  Expanded(child: _buildAnalyticsTabs()),
                ],
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Text("Select a company and user(s) to view tracking logs."),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTabs() {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: MyColors.color1,
                  indicatorColor: MyColors.color1,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: "Interaction Logs"),
                    Tab(text: "User Contributions"),
                    Tab(text: "By Feature"),
                  ],
                ),
              ),
              Text(
                "${DateFormat('MMMM dd, yyyy').format(selectedDate)}  •  ${trackingLogs.length} events",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: TabBarView(
              children: [
                _buildLogsTable(),
                _buildContributionsTable(),
                _buildFeatureTable(),
              ],
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

  InputDecoration _selectorDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: MyColors.color1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: MyColors.color1, width: 2),
      ),
    );
  }

  Widget _buildCompanyDropdown() {
    if (isLoadingCompanies) return const CircularProgressIndicator();

    return DropdownButtonFormField<String>(
      decoration: _selectorDecoration("Select Company"),
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

  String _userLabel(Map<String, dynamic> user) {
    final email = (user['email'] ?? '').toString();
    return email.isNotEmpty ? "${user['name']} ($email)" : "${user['name']}";
  }

  String _selectionSummary() {
    if (selectedUserKeys.isEmpty) return "Select user(s)";
    if (users.isNotEmpty && selectedUserKeys.length == users.length) {
      return "All users (${users.length})";
    }
    if (selectedUserKeys.length == 1) return _userLabel(_selectedUsers.first);
    return "${selectedUserKeys.length} users selected";
  }

  Widget _buildUserSelector() {
    if (isLoadingUsers) return const CircularProgressIndicator();

    final enabled = selectedCompanyId != null && users.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: enabled ? _openUserPicker : null,
      child: InputDecorator(
        decoration: _selectorDecoration("Select User(s)").copyWith(
          enabled: enabled,
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          selectedCompanyId == null
              ? ""
              : users.isEmpty
                  ? "No users in this company"
                  : _selectionSummary(),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Future<void> _openUserPicker() async {
    final Set<String> tempSelection = {...selectedUserKeys};
    String search = "";

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = users.where((u) {
              final q = search.toLowerCase();
              return u['name'].toString().toLowerCase().contains(q) ||
                  u['email'].toString().toLowerCase().contains(q);
            }).toList();

            final filteredKeys = filtered.map((u) => u['key'] as String).toSet();
            final allFilteredSelected =
                filteredKeys.isNotEmpty && filteredKeys.every(tempSelection.contains);
            final someFilteredSelected = filteredKeys.any(tempSelection.contains);

            return AlertDialog(
              title: Text("Select Users — ${selectedCompanyName ?? ''}"),
              content: SizedBox(
                width: 500,
                height: 450,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Search user...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                      onChanged: (value) => setDialogState(() => search = value),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      tristate: true,
                      value: allFilteredSelected ? true : (someFilteredSelected ? null : false),
                      activeColor: MyColors.color1,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        search.isEmpty ? "Select All (${filtered.length})" : "Select All Matching (${filtered.length})",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onChanged: (_) {
                        setDialogState(() {
                          if (allFilteredSelected) {
                            tempSelection.removeAll(filteredKeys);
                          } else {
                            tempSelection.addAll(filteredKeys);
                          }
                        });
                      },
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text("No users found."))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final user = filtered[index];
                                final key = user['key'] as String;
                                return CheckboxListTile(
                                  value: tempSelection.contains(key),
                                  activeColor: MyColors.color1,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  dense: true,
                                  title: Text(user['name'].toString()),
                                  subtitle: Text(user['email'].toString()),
                                  onChanged: (checked) {
                                    setDialogState(() {
                                      if (checked == true) {
                                        tempSelection.add(key);
                                      } else {
                                        tempSelection.remove(key);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                Text("${tempSelection.length} selected", style: TextStyle(color: Colors.grey[600])),
                TextButton(
                  onPressed: () => setDialogState(tempSelection.clear),
                  child: const Text("Clear"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: MyColors.color1),
                  onPressed: () => Navigator.pop(dialogContext, tempSelection),
                  child: const Text("Apply", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) _applyUserSelection(result);
  }

  Widget _buildMetricsRow() {
    final metrics = _calculateMetrics();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMetricCard("Total Interactions", "${metrics['totalInteractions']}", Icons.touch_app),
        _buildMetricCard("Total Time Spent", _formatDuration(metrics['totalTimeSpent']), Icons.timer),
        _buildMetricCard("Most Active Feature", metrics['mostActiveFeature'], Icons.star),
        _buildMetricCard("Active Users", "${metrics['activeUsers']} / ${selectedUserKeys.length}", Icons.people),
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
              Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: MyColors.color1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareBar(double share) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              color: MyColors.color2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          child: Text("${(share * 100).toStringAsFixed(1)}%", textAlign: TextAlign.right),
        ),
      ],
    );
  }

  Widget _buildContributionsTable() {
    final contributions = _calculateUserContributions();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        itemCount: contributions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = contributions[index];
          final interactions = entry['interactions'] as int;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: MyColors.color1.withValues(alpha: 0.1),
              child: Text("${index + 1}", style: const TextStyle(color: MyColors.color1, fontWeight: FontWeight.bold)),
            ),
            title: Text(entry['name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  interactions == 0
                      ? "No activity on this date"
                      : "$interactions interactions • ${_formatDuration(entry['timeSpent'] as int)} • Top: ${entry['topFeature']}",
                ),
                const SizedBox(height: 6),
                _buildShareBar(entry['share'] as double),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureTable() {
    final features = _calculateFeatureBreakdown();
    if (features.isEmpty) {
      return const Center(child: Text("No tracking logs found for this date."));
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        itemCount: features.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = features[index];
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0x1A2196F3),
              child: Icon(Icons.widgets, color: Colors.blue),
            ),
            title: Text(entry['feature'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${entry['interactions']} interactions • ${_formatDuration(entry['timeSpent'] as int)} • "
                  "${entry['userCount']} user${entry['userCount'] == 1 ? '' : 's'}",
                ),
                const SizedBox(height: 6),
                _buildShareBar(entry['share'] as double),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogsTable() {
    if (trackingLogs.isEmpty) {
      return const Center(child: Text("No tracking logs found for this date."));
    }

    final showUser = selectedUserKeys.length > 1;

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
              "${showUser ? 'User: ${log['_userName']} • ' : ''}"
              "Action: $action${duration is num ? ' • Duration: ${_formatDuration(duration.toInt())}' : ''}",
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
