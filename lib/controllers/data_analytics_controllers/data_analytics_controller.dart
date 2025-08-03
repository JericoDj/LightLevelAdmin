import 'package:cloud_firestore/cloud_firestore.dart';

import 'booking_session_controller.dart';
import 'call_controller.dart';
import 'chat_controller.dart';
import 'mood_controller.dart';
import 'stress_controller.dart';

class DataAnalyticsController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> companies = [];
  String? selectedCompany;
  List<String> selectedUsers = [];
  List<String> mockUsers = [];

  DateTime? startDate;
  DateTime? endDate;

  Map<String, dynamic>? moodStressReport;
  Map<String, dynamic>? bookingReport;
  List<Map<String, dynamic>>? callReport;
  List<Map<String, dynamic>>? chatReport;


  final StressController stressController = StressController();
  final MoodController moodController = MoodController();
  final BookingSessionsController bookingSessionsController = BookingSessionsController();
  final CallController callController = CallController();
  final ChatController chatController = ChatController();


  void setDateRange(DateTime start, DateTime end) {
    startDate = start;
    endDate = end;
    stressController.setDateRange(start, end);
    moodController.setDateRange(start, end);
    // Optional: propagate to others if needed
  }

  /// 📍 Fetch companies with role == "User"
  Future<void> fetchCompanies() async {
    final snapshot = await _firestore
        .collection('companies')
        .where('role', isEqualTo: 'User')
        .get();

    companies = snapshot.docs.map((doc) => doc.id).toList();

    if (companies.isNotEmpty) {
      selectedCompany = companies.first;
      await fetchUsersForCompany();
    }
  }

  /// 📍 Fetch users under the selected company
  Future<void> fetchUsersForCompany() async {
    if (selectedCompany == null) return;

    final snapshot = await _firestore
        .collection('users')
        .where('companyId', isEqualTo: selectedCompany)
        .get();

    mockUsers = snapshot.docs
        .map((doc) => doc['fullName']?.toString() ?? 'Unnamed User')
        .toList();
  }

  /// 📊 Generate only Mood Trend
  Future<void> generateMoodOnly(DateTime? startDate, DateTime? endDate) async {
    if (selectedUsers.isEmpty) return;

    if (startDate != null && endDate != null) {
      moodController.setDateRange(startDate, endDate);
    }

    final result = await moodController.generateMoodTrend(selectedUsers);
    moodStressReport ??= {};
    moodStressReport!['moodTrend'] = result;
  }
  /// 📊 Generate only Stress Trend
  Future<void> generateStressOnly(DateTime? start, DateTime? end) async {
    if (selectedUsers.isEmpty) return;

    final now = DateTime.now();
    final defaultStart = DateTime(now.year, now.month, 1);
    final startDateToUse = start ?? defaultStart;
    final endDateToUse = end ?? now;

    stressController.setDateRange(startDateToUse, endDateToUse);

    final result = await stressController.generateStressTrend(selectedUsers);
    moodStressReport ??= {};
    moodStressReport!['stressTrend'] = result;
  }

  /// 📅 Generate Booking Sessions Report
  Future<void> generateBookingSessionsReport(String status, DateTime? startDate, DateTime? endDate) async {
    bookingReport = await bookingSessionsController.generateReport(
      selectedUsers,
      status,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// 📞 Generate only Call Report
  Future<void> generateCallOnly(DateTime? startDate, DateTime? endDate) async {
    if (selectedCompany == null || selectedUsers.isEmpty) return;

    callReport = await callController.generateCallReport(
      companyId: selectedCompany!,
      users: selectedUsers,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// 💬 Generate only Chat Report
  Future<void> generateChatOnly(DateTime? startDate, DateTime? endDate) async {
    if (selectedCompany == null || selectedUsers.isEmpty) return;

    chatReport = await chatController.generateChatReport(
      companyId: selectedCompany!,
      users: selectedUsers,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
