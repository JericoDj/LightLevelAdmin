import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StressController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, double> _stressTrackingData = {}; // key: date-user, value: stressLevel
  final Map<String, List<double>> _perUserStress = {}; // key: fullName, value: list of stress levels

  DateTime? startDate;
  DateTime? endDate;

  void setDateRange(DateTime start, DateTime end) {
    startDate = start;
    endDate = end;
  }

  /// 📊 Generates the stress trend (High, Moderate, Low) based on filtered data
  Future<String> generateStressTrend(List<String> fullNames) async {
    print('🧑‍🤝‍🧑 Processing fullNames for stress: $fullNames');
    _stressTrackingData.clear();
    _perUserStress.clear();

    for (final name in fullNames) {
      final userQuery = await _firestore
          .collection('users')
          .where('fullName', isEqualTo: name)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        print('⚠️ No user found for fullName: $name');
        continue;
      }

      final userId = userQuery.docs.first.id;
      final stressCollection = _firestore
          .collection('users')
          .doc(userId)
          .collection('moodTracking');

      final snapshot = await stressCollection.get();

      for (final doc in snapshot.docs) {
        final stressValue = doc.data()['stressLevel'];
        final dateKey = doc.id;

        if (stressValue == null || stressValue is! num) continue;

        final parsedDate = DateTime.tryParse(dateKey);
        if (parsedDate == null) continue;

        // 🗓️ Filter by selected date range
        if (startDate != null && endDate != null) {
          if (parsedDate.isBefore(startDate!) || parsedDate.isAfter(endDate!)) continue;
        }

        final level = stressValue.toDouble();
        final key = "$dateKey-$userId";

        _stressTrackingData[key] = level;
        _perUserStress.putIfAbsent(name, () => []).add(level);
      }
    }

    final allValues = _stressTrackingData.values.toList();
    if (allValues.isEmpty) return 'No data available';

    final avg = allValues.reduce((a, b) => a + b) / allValues.length;

    if (avg >= 80) return 'High Stress';
    if (avg >= 50) return 'Moderate Stress';
    return 'Low Stress';
  }

  /// 📈 Returns categorized stress counts for pie chart
  Map<String, int> getStressLevelCounts() {
    final counts = {'Low': 0, 'Moderate': 0, 'High': 0};

    for (final level in _stressTrackingData.values) {
      if (level <= 40) {
        counts['Low'] = counts['Low']! + 1; // no space here ✅
      } else if (level <= 70) {
        counts['Moderate'] = counts['Moderate']! + 1;
      } else {
        counts['High'] = counts['High']! + 1;
      }
    }

    return counts;
  }

  /// 📋 Returns average stress level per user
  Map<String, double> getPerUserAverages() {
    final averages = <String, double>{};

    _perUserStress.forEach((user, levels) {
      if (levels.isNotEmpty) {
        final avg = levels.reduce((a, b) => a + b) / levels.length;
        averages[user] = avg;
      }
    });

    return averages;
  }

  /// 👤 Alias for UI breakdown
  Map<String, double> getUserContributions() {
    return getPerUserAverages();
  }

  Map<String, Map<String, dynamic>> getUserContributionsDetailed() {
    final details = <String, Map<String, dynamic>>{};

    final Map<String, List<Map<String, dynamic>>> userEntries = {};

    // Parse _stressTrackingData which uses keys like "2025-08-01-userId"
    _stressTrackingData.forEach((key, value) {
      final parts = key.split('-');
      if (parts.length < 2) return;

      final date = parts.take(3).join('-');
      final userId = parts.sublist(3).join('-');

      final user = _perUserStress.keys.firstWhere(
            (u) => _perUserStress[u]!.any((v) => v == value),
        orElse: () => userId,
      );

      userEntries.putIfAbsent(user, () => []).add({
        'date': date,
        'value': value,
      });
    });

    userEntries.forEach((user, entries) {
      final values = entries.map((e) => e['value'] as double).toList();
      final avg = values.reduce((a, b) => a + b) / values.length;

      details[user] = {
        'average': avg,
        'count': values.length,
        'entries': entries,
      };
    });

    print(details);

    return details;
  }

}

