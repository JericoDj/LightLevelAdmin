import 'package:cloud_firestore/cloud_firestore.dart';
class MoodController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _allTrackedMoods = [];

  DateTime? _startDate;
  DateTime? _endDate;

  void setDateRange(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
  }

  Future<String> generateMoodTrend(List<String> fullNames) async {
    print('🧑‍🤝‍🧑 Processing fullNames: $fullNames');
    final moodCounts = <String, int>{};
    _allTrackedMoods.clear();

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
      print('✅ Found userId "$userId" for fullName "$name"');

      final moodCollection = _firestore
          .collection('users')
          .doc(userId)
          .collection('moodTracking');

      final snapshot = await moodCollection.get();

      for (final doc in snapshot.docs) {
        final mood = doc.data()['mood']?.toString() ?? '';
        final docId = doc.id;

        // ✅ Parse Firestore document ID to DateTime
        final parsedDate = DateTime.tryParse(docId);
        if (parsedDate == null) continue;

        // ✅ Filter by date range if provided
        if (_startDate != null && _endDate != null) {
          if (parsedDate.isBefore(_startDate!) || parsedDate.isAfter(_endDate!)) {
            continue;
          }
        }

        print('📅 $docId → 😌 Mood: $mood');

        if (mood.isNotEmpty) {
          moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
          _allTrackedMoods.add(mood);
        }
      }
    }

    print('📊 Final Mood Count: $moodCounts');

    if (moodCounts.isEmpty) return 'No data available';

    final total = moodCounts.values.reduce((a, b) => a + b);
    final sorted = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topMood = sorted.first;
    final percentage = (topMood.value / total) * 100;

    print('🏆 Top Mood: ${topMood.key} (${percentage.toStringAsFixed(2)}%)');

    if (percentage >= 60) {
      return 'Mostly ${topMood.key}';
    } else if (percentage >= 30) {
      return 'Mixed, leaning ${topMood.key}';
    } else {
      return 'Highly varied moods';
    }
  }

  /// 📈 Mood counts for bar chart
  Map<String, int> getMoodCounts() {
    final counts = <String, int>{};
    for (final mood in _allTrackedMoods) {
      counts[mood] = (counts[mood] ?? 0) + 1;
    }
    return counts;
  }
}
