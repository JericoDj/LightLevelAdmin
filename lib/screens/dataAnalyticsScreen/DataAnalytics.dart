import 'dart:ui' as ui;



import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:lightlevelpsychosolutionsadmin/utils/colors.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;


import '../../controllers/data_analytics_controllers/data_analytics_controller.dart';
import 'BookingSessionsReportWidget.dart';
import 'CallReportWidget.dart';
import 'ChatReportWidget.dart';
import 'MoodReportWidget.dart';
import 'StressReportWidget.dart';
import 'UserSelectionDialog.dart';
import 'dart:html' as html;

enum ReportType { mood, stress, booking, call, chat, all }

class DataAnalyticsReportScreen extends StatefulWidget {


  const DataAnalyticsReportScreen({super.key});



  @override
  State<DataAnalyticsReportScreen> createState() => _DataAnalyticsReportScreenState();
}

class _DataAnalyticsReportScreenState extends State<DataAnalyticsReportScreen> {
  final GlobalKey _reportKey = GlobalKey();
  final controller = DataAnalyticsController();
  ReportType? currentReportType;

  @override
  void initState() {
    super.initState();
    controller.fetchCompanies().then((_) {
      setState(() {});
    });
  }

  /// Ensures fallback to first of month and today if null
  DateTimeRange _resolveDateRange() {
    final now = DateTime.now();
    final start = controller.startDate ?? DateTime(now.year, now.month, 1);
    final end = controller.endDate ?? now;
    return DateTimeRange(start: start, end: end);
  }

  Widget _buildUserSelectorButton(String label) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
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
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: MyColors.color2,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: MyColors.color2.withOpacity(0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.group_add, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Select Users',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: controller.selectedUsers.map((user) {
              return Chip(
                label: Text(user),
                backgroundColor: Colors.grey.shade200,
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    controller.selectedUsers.remove(user);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  Widget _buildActionButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: MyColors.color1,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: MyColors.color1.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }



  Widget _buildDateButton(String label, DateTime? date, void Function(DateTime?) onPicked) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: MyColors.color2,    // Header background and selected date
                        onPrimary: Colors.white,     // Header text
                        onSurface: Colors.black,     // Calendar text
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black87, // Text color
                          side: BorderSide(color: MyColors.color2, width: 2), // Border
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                      dialogBackgroundColor: Colors.white,
                    ),
                    child: child!,
                  );
                },
              );

              onPicked(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MyColors.color2, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    date != null ? DateFormat('yyyy-MM-dd').format(date) : 'Select Date',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    final range = _resolveDateRange();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50), // <-- set your desired height here
        child: AppBar(
          title: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child:  Text(
                'Data Analytics',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // 📁 Select Company
            Wrap(
              children: [

              ],
            ),
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


            Wrap(
              children: [


              ],
            ),


            const SizedBox(height: 16),

            // 👤 Choose Users + 📅 Dates in a single row
            Wrap(

              children: [
                Container(
                  width: 160,
                  child: _buildUserSelectorButton('Choose Users'),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 160,
                  child: _buildDateButton('Start Date', controller.startDate, (picked) {
                    if (picked != null) {
                      setState(() => controller.startDate = picked);
                    }
                  }),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 160,
                  child: _buildDateButton('End Date', controller.endDate, (picked) {
                    setState(() {
                      controller.endDate = picked ?? DateTime.now();
                    });
                  }),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Text(
              '📆 From ${DateFormat('yyyy-MM-dd').format(range.start)} to ${DateFormat('yyyy-MM-dd').format(range.end)}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),

            const SizedBox(height: 24),

            // 🎯 Generate Buttons
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [

                _buildActionButton(
                  label: 'Generate All Data Analytics',
                  onTap: () async {
                    await controller.generateMoodOnly(range.start, range.end);
                    await controller.generateStressOnly(range.start, range.end);

                    // Loop through all statuses instead of showing a dialog
                    final allStatuses = ['Requested', 'Scheduled', 'Finished', 'Cancelled'];
                    for (final status in allStatuses) {
                      await controller.generateBookingSessionsReport(status, range.start, range.end);
                    }

                    await controller.generateCallOnly(range.start, range.end);
                    await controller.generateChatOnly(range.start, range.end);

                    setState(() => currentReportType = ReportType.all);
                  },
                ),

                _buildActionButton(
                  label: 'Generate Mood',
                  onTap: () async {
                    await controller.generateMoodOnly(range.start, range.end);
                    setState(() => currentReportType = ReportType.mood);
                  },
                ),
                _buildActionButton(
                  label: 'Generate Stress',
                  onTap: () async {
                    await controller.generateStressOnly(range.start, range.end);
                    setState(() => currentReportType = ReportType.stress);
                  },
                ),
                _buildActionButton(
                  label: 'Generate Booking Sessions',
                  onTap: () async {
                    final status = await showDialog<String>(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Select Booking Status'),
                        children: ['Requested', 'Scheduled', 'Finished', 'Cancelled']
                            .map((s) => SimpleDialogOption(
                          onPressed: () => Navigator.pop(context, s),
                          child: Text(s),
                        ))
                            .toList(),
                      ),
                    );
                    if (status != null) {
                      await controller.generateBookingSessionsReport(status, range.start, range.end);
                      setState(() => currentReportType = ReportType.booking);
                    }
                  },
                ),
                _buildActionButton(
                  label: 'Generate Calls',
                  onTap: () async {
                    await controller.generateCallOnly(range.start, range.end);
                    setState(() => currentReportType = ReportType.call);
                  },
                ),
                _buildActionButton(
                  label: 'Generate Chats',
                  onTap: () async {
                    await controller.generateChatOnly(range.start, range.end);
                    setState(() => currentReportType = ReportType.chat);
                  },
                ),
              ],
            ),


            const SizedBox(height: 24),

            RepaintBoundary(
              key: _reportKey,
              child: Builder(
                builder: (_) {
                  if (currentReportType == ReportType.mood &&
                      controller.moodStressReport?['moodTrend'] != null) {
                    return MoodReportWidget(
                      moodTrend: controller.moodStressReport!['moodTrend'],
                      moodCounts: controller.moodController.getMoodCounts(),
                      company: controller.selectedCompany ?? 'Unknown',
                      selectedUsers: controller.selectedUsers,
                      userMoodData: controller.moodController.getUserMoodContributions(), // ✅ Add this line
                    );
                  }


                  if (currentReportType == ReportType.stress &&
                      controller.moodStressReport?['stressTrend'] != null) {
                    return StressReportWidget(
                      stressTrend: controller.moodStressReport!['stressTrend'],
                      stressCounts: controller.stressController.getStressLevelCounts(),
                      company: controller.selectedCompany ?? 'Unknown',
                      selectedUsers: controller.selectedUsers,
                      userContributions: controller.stressController.getUserContributionsDetailed(),

                    );
                  }

                  if (currentReportType == ReportType.booking && controller.bookingReport != null) {
                    return BookingSessionsReportWidget(
                      data: controller.bookingReport!,
                      company: controller.selectedCompany ?? 'Unknown',
                      selectedUsers: controller.selectedUsers,
                    );
                  }
                  if (currentReportType == ReportType.call && controller.callReport != null) {
                    return CallReportWidget(
                      data: controller.callReport!,
                      company: controller.selectedCompany ?? 'Unknown',
                      selectedUsers: controller.selectedUsers,
                    );
                  }

                  if (currentReportType == ReportType.chat && controller.chatReport != null) {
                    return ChatReportWidget(
                      data: controller.chatReport!,
                      company: controller.selectedCompany ?? 'Unknown',
                      selectedUsers: controller.selectedUsers,
                    );
                  }

                  if (currentReportType == ReportType.all) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (controller.moodStressReport?['moodTrend'] != null)
                          MoodReportWidget(
                            moodTrend: controller.moodStressReport!['moodTrend'],
                            moodCounts: controller.moodController.getMoodCounts(),
                            company: controller.selectedCompany ?? 'Unknown',
                            selectedUsers: controller.selectedUsers,
                            userMoodData: controller.moodController.getUserMoodContributions(),
                          ),
                        const SizedBox(height: 20),
                        if (controller.moodStressReport?['stressTrend'] != null)
                          StressReportWidget(
                            stressTrend: controller.moodStressReport!['stressTrend'],
                            stressCounts: controller.stressController.getStressLevelCounts(),
                            company: controller.selectedCompany ?? 'Unknown',
                            selectedUsers: controller.selectedUsers,
                            userContributions: controller.stressController.getUserContributionsDetailed(),
                          ),
                        const SizedBox(height: 20),
                        if (controller.bookingReport != null)
                          BookingSessionsReportWidget(
                            data: controller.bookingReport!,
                            company: controller.selectedCompany ?? 'Unknown',
                            selectedUsers: controller.selectedUsers,
                          ),
                        const SizedBox(height: 20),
                        if (controller.callReport != null)
                          CallReportWidget(
                            data: controller.callReport!,
                            company: controller.selectedCompany ?? 'Unknown',
                            selectedUsers: controller.selectedUsers,
                          ),
                        const SizedBox(height: 20),
                        if (controller.chatReport != null)
                          ChatReportWidget(
                            data: controller.chatReport!,
                            company: controller.selectedCompany ?? 'Unknown',
                            selectedUsers: controller.selectedUsers,
                          ),
                      ],
                    );
                  }


                  return const SizedBox.shrink();
                },
              ),
            ),

            if (currentReportType != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: GestureDetector(
                  onTap: () => _exportReportAsImage(context, _reportKey),
                  child: Container(
                    width: 600,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: MyColors.color1, // Use your defined primary color
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: MyColors.color1.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.save_alt, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Export Current Report',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )

          ],
        ),
      ),
    );
  }


  Future<void> _exportReportAsImage(BuildContext context, GlobalKey _reportKey) async {
    try {
      final boundary = _reportKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not capture report view')),
        );
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to convert image to bytes')),
        );
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();

      // Use Builder to get the inner dialog context for safe Navigator.pop
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            actionsPadding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            title: const Text(
              'Export Report',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Save the report?',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              // PNG
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.image, color: Colors.white),
                  label: const Text('Save as PNG', style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyColors.color2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    if (kIsWeb) {
                      final blob = html.Blob([pngBytes]);
                      final url = html.Url.createObjectUrlFromBlob(blob);
                      final anchor = html.AnchorElement(href: url)
                        ..setAttribute("download", "report.png")
                        ..click();
                      html.Url.revokeObjectUrl(url);
                    } else {
                      await Printing.sharePdf(bytes: pngBytes, filename: 'report.png');
                    }
                  },
                ),
              ),

              const SizedBox(height: 8),


              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.table_chart, color: Colors.white),
                  label: const Text('Export as Excel', style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await _exportAsExcel();
                  },
                ),
              ),

              const SizedBox(height: 8),

              // PDF


              const SizedBox(height: 8),

              // Cancel
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  child: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ),
            ],
          );
        },
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please Select User'/s and Generate a Report Before Exporting!")),
      );
    }
  }


  Future<void> _exportAsExcel() async {
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Report';

    final selectedUsers = controller.selectedUsers;
    final selectedCompany = controller.selectedCompany;

    int row = 1;

    // ================= COVER SECTION =================
    if (selectedCompany != null && selectedUsers != null && selectedUsers.isNotEmpty) {
      sheet.getRangeByIndex(row, 1).setText('Company:');
      sheet.getRangeByIndex(row, 2).setText(selectedCompany);
      row++;
      sheet.getRangeByIndex(row, 1).setText('Generated for users:');
      row++;
      for (final user in selectedUsers) {
        sheet.getRangeByIndex(row, 1).setText(user);
        row++;
      }
    } else if (selectedCompany != null) {
      sheet.getRangeByIndex(row, 1).setText('Company:');
      sheet.getRangeByIndex(row, 2).setText(selectedCompany);
      row++;
    } else if (selectedUsers != null && selectedUsers.isNotEmpty) {
      if (selectedUsers.length == 1) {
        sheet.getRangeByIndex(row, 1).setText('Name:');
        sheet.getRangeByIndex(row, 2).setText(selectedUsers.first);
        row++;
      } else {
        sheet.getRangeByIndex(row, 1).setText('Generated for users:');
        row++;
        for (final user in selectedUsers) {
          sheet.getRangeByIndex(row, 1).setText(user);
          row++;
        }
      }
    } else {
      sheet.getRangeByIndex(row, 1).setText('Generated for: All Data');
      row++;
    }

    // Totals
    sheet.getRangeByIndex(row, 1).setText('Total Bookings:');
    sheet.getRangeByIndex(row, 2).setText('${controller.bookingReport?['total'] ?? 0}');
    row++;
    sheet.getRangeByIndex(row, 1).setText('Total Calls:');
    sheet.getRangeByIndex(row, 2).setText('${controller.callReport?.length ?? 0}');
    row++;
    sheet.getRangeByIndex(row, 1).setText('Total Chats:');
    sheet.getRangeByIndex(row, 2).setText('${controller.chatReport?.length ?? 0}');
    row++;
    sheet.getRangeByIndex(row, 1).setText('Mood Tracking Trend:');
    sheet.getRangeByIndex(row, 2).setText(controller.moodStressReport?['moodTrend']?.toString() ?? '-');
    row++;
    sheet.getRangeByIndex(row, 1).setText('Stress Tracking Trend:');
    sheet.getRangeByIndex(row, 2).setText(controller.moodStressReport?['stressTrend']?.toString() ?? '-');
    row += 2;

    sheet.getRangeByIndex(row, 1).setText('================ Overall Report ================');
    row += 2;

    // ================= SECTION 1: Mood =================
    sheet.getRangeByIndex(row, 1).setText('1. Mood Trend Data');
    row++;
    final moodCounts = controller.moodController.getMoodCounts();
    moodCounts.forEach((mood, count) {
      sheet.getRangeByIndex(row, 1).setText(mood.toString());
      sheet.getRangeByIndex(row, 2).setText(count.toString());
      row++;
    });
    row++;

    // ================= SECTION 2: Stress =================
    sheet.getRangeByIndex(row, 1).setText('2. Stress Categories (Pie Chart Data)');
    row++;
    final stressCounts = controller.stressController.getStressLevelCounts();
    stressCounts.forEach((level, avg) {
      sheet.getRangeByIndex(row, 1).setText(level.toString());
      sheet.getRangeByIndex(row, 2).setText(avg.toString());
      row++;
    });
    row++;

    // ================= SECTION 3: Booking Sessions =================
    sheet.getRangeByIndex(row, 1).setText('3. Booking Sessions & Services Completed');
    row++;
    sheet.getRangeByIndex(row, 1).setText('Full Name');
    sheet.getRangeByIndex(row, 2).setText('Service');
    sheet.getRangeByIndex(row, 3).setText('Status');
    sheet.getRangeByIndex(row, 4).setText('Date Requested');
    row++;
    final bookings = controller.bookingReport?['bookings'] as List<Map<String, dynamic>>? ?? [];
    for (final session in bookings) {
      sheet.getRangeByIndex(row, 1).setText(session['full_name']?.toString() ?? '');
      sheet.getRangeByIndex(row, 2).setText(session['serviceAvailed']?.toString() ?? '');
      sheet.getRangeByIndex(row, 3).setText(session['status']?.toString() ?? '');
      sheet.getRangeByIndex(row, 4).setText(session['date_requested']?.toString() ?? '');
      row++;
    }
    row++;

    // ================= SECTION 4: Calls =================
    sheet.getRangeByIndex(row, 1).setText('4. 24/7 Call Data');
    row++;
    sheet.getRangeByIndex(row, 1).setText('Full Name');
    sheet.getRangeByIndex(row, 2).setText('Duration');
    sheet.getRangeByIndex(row, 3).setText('Started At');
    row++;
    controller.callReport?.forEach((call) {
      sheet.getRangeByIndex(row, 1).setText(call['fullName']?.toString() ?? '');
      sheet.getRangeByIndex(row, 2).setText(call['durationFormatted']?.toString() ?? '');
      sheet.getRangeByIndex(row, 3).setText(call['timestampStarted']?.toString() ?? '');
      row++;
    });
    row++;

    // ================= SECTION 5: Chats =================
    sheet.getRangeByIndex(row, 1).setText('5. 24/7 Chat Data');
    row++;
    sheet.getRangeByIndex(row, 1).setText('Full Name');
    sheet.getRangeByIndex(row, 2).setText('Timestamp');
    sheet.getRangeByIndex(row, 3).setText('Message Count');
    row++;
    controller.chatReport?.forEach((chat) {
      sheet.getRangeByIndex(row, 1).setText(chat['fullName']?.toString() ?? '');
      sheet.getRangeByIndex(row, 2).setText(chat['timestamp']?.toString() ?? '');
      sheet.getRangeByIndex(row, 3).setText('${chat['messages']?.length ?? 0}');
      row++;
    });

    // ================= SAVE FILE =================
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "report.xlsx")
      ..click();
    html.Url.revokeObjectUrl(url);
  }



  Widget _buildDropdown(
      String label,
      String? value,
      List<String> items,
      ValueChanged<String?> onChanged,
      ) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Container(
                width: 400,
                child: DropdownButtonFormField<String>(
                  value: value,
                  isExpanded: true,
                  items: items
                      .map((e) => DropdownMenuItem<String>(
                    value: e,
                    child: Text(e),
                  ))
                      .toList(),
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    enabledBorder: OutlineInputBorder(

                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: MyColors.color2, width: 1.5),
                    ),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  dropdownColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


}
