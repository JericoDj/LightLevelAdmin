import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../controllers/data_analytics_controllers/data_analytics_controller.dart';
import 'BookingSessionsReportWidget.dart';
import 'CallReportWidget.dart';
import 'ChatReportWidget.dart';
import 'MoodReportWidget.dart';
import 'StressReportWidget.dart';
import 'UserSelectionDialog.dart';

enum ReportType { mood, stress, booking, call, chat }

class DataAnalyticsReportScreen extends StatefulWidget {
  const DataAnalyticsReportScreen({super.key});

  @override
  State<DataAnalyticsReportScreen> createState() => _DataAnalyticsReportScreenState();
}

class _DataAnalyticsReportScreenState extends State<DataAnalyticsReportScreen> {
  final controller = DataAnalyticsController();
  ReportType? currentReportType;

  @override
  void initState() {
    super.initState();
    controller.fetchCompanies().then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasDateRange = controller.startDate != null && controller.endDate != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Analytics Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // 📁 Select Company
            _buildDropdown(
              'Select Company',
              controller.selectedCompany,
              controller.companies,
                  (val) async {
                setState(() {
                  controller.selectedCompany = val;
                  controller.selectedUsers = [];
                  controller.mockUsers = [];
                });
                await controller.fetchUsersForCompany();
                setState(() {});
              },
            ),

            const SizedBox(height: 16),

            // 👤 Select Users
            _buildUserSelectorDialogButton('Select Users', controller.selectedUsers),

            const SizedBox(height: 16),

            // 📅 Select Date Range
            ElevatedButton(
              onPressed: () async {
                final start = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().subtract(const Duration(days: 7)),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );

                if (start == null) return;

                final end = await showDatePicker(
                  context: context,
                  initialDate: start,
                  firstDate: start,
                  lastDate: DateTime.now(),
                );

                if (end != null) {
                  controller.setDateRange(start, end);
                  setState(() {});
                }
              },
              child: const Text('Select Date Range'),
            ),

            if (hasDateRange)
              Text(
                '📆 From ${DateFormat('yyyy-MM-dd').format(controller.startDate!)} '
                    'to ${DateFormat('yyyy-MM-dd').format(controller.endDate!)}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),

            const SizedBox(height: 24),

            // 🎯 Generate Buttons
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await controller.generateMoodOnly(controller.startDate, controller.endDate);
                    setState(() {
                      currentReportType = ReportType.mood;
                    });
                  },
                  child: const Text('Generate Mood'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await controller.generateStressOnly(controller.startDate, controller.endDate);
                    setState(() {
                      currentReportType = ReportType.stress;
                    });
                  },
                  child: const Text('Generate Stress'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final status = await showDialog<String>(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Select Booking Status'),
                        children: [
                          for (var s in ['Requested', 'Scheduled', 'Finished', 'Cancelled'])
                            SimpleDialogOption(
                              onPressed: () => Navigator.pop(context, s),
                              child: Text(s),
                            ),
                        ],
                      ),
                    );

                    if (status != null) {
                      await controller.generateBookingSessionsReport(
                        status,
                        controller.startDate,
                        controller.endDate,
                      );
                      setState(() {
                        currentReportType = ReportType.booking;
                      });
                    }
                  },
                  child: const Text('Generate Booking Sessions'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await controller.generateCallOnly(controller.startDate, controller.endDate);
                    setState(() {
                      currentReportType = ReportType.call;
                    });
                  },
                  child: const Text('Generate Calls'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await controller.generateChatOnly(controller.startDate, controller.endDate);
                    setState(() {
                      currentReportType = ReportType.chat;
                    });
                  },
                  child: const Text('Generate Chats'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 🧠 Mood Report
            if (currentReportType == ReportType.mood &&
                controller.moodStressReport?['moodTrend'] != null)
              MoodReportWidget(
                moodTrend: controller.moodStressReport!['moodTrend'],
                moodCounts: controller.moodController.getMoodCounts(),
              ),

            // 💢 Stress Report
            if (currentReportType == ReportType.stress &&
                controller.moodStressReport?['stressTrend'] != null)
              StressReportWidget(
                stressTrend: controller.moodStressReport!['stressTrend'],
                stressCounts: controller.stressController.getStressLevelCounts(),
                company: controller.selectedCompany ?? 'Unknown',
                selectedUsers: controller.selectedUsers,
              ),

            // 📅 Booking
            if (currentReportType == ReportType.booking && controller.bookingReport != null)
              BookingSessionsReportWidget(data: controller.bookingReport!),

            // 📞 Call Report
            if (currentReportType == ReportType.call && controller.callReport != null)
              CallReportWidget(data: controller.callReport!),

            // 💬 Chat Report
            if (currentReportType == ReportType.chat && controller.chatReport != null)
              ChatReportWidget(data: controller.chatReport!),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
      String label,
      String? value,
      List<String> items,
      void Function(String?) onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _buildUserSelectorDialogButton(String label, List<String> selectedUsers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            final selected = await showDialog<List<String>>(
              context: context,
              builder: (context) => UserSelectionDialog(
                allUsers: controller.mockUsers,
                initiallySelected: controller.selectedUsers,
              ),
            );

            if (selected != null) {
              setState(() {
                controller.selectedUsers = selected;
              });
            }
          },
          child: const Text('Choose Users'),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          children: selectedUsers.map((user) {
            return Chip(
              label: Text(user),
              onDeleted: () {
                setState(() {
                  controller.selectedUsers.remove(user);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
