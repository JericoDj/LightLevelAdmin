import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MoodController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _allTrackedMoods = [];
  final Map<String, List<Map<String, dynamic>>> _moodTrackingData = {};

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
    _moodTrackingData.clear();

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

      final moodCollection = _firestore
          .collection('users')
          .doc(userId)
          .collection('moodTracking');

      final snapshot = await moodCollection.get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final mood = data['mood']?.toString() ?? '';
        final docId = doc.id;

        final parsedDate = DateTime.tryParse(docId);
        if (parsedDate == null) continue;

        if (_startDate != null && _endDate != null) {
          if (parsedDate.isBefore(_startDate!) || parsedDate.isAfter(_endDate!)) {
            continue;
          }
        }

        if (mood.isNotEmpty) {
          moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
          _allTrackedMoods.add(mood);

          _moodTrackingData.putIfAbsent(name, () => []).add({
            'mood': mood,
            'date': DateFormat('MMMM d').format(parsedDate),
          });
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

    if (percentage >= 60) {
      return 'Mostly ${topMood.key}';
    } else if (percentage >= 30) {
      return 'Mixed, leaning ${topMood.key}';
    } else {
      return 'Highly varied moods';
    }
  }

  Map<String, int> getMoodCounts() {
    final counts = <String, int>{};
    for (final mood in _allTrackedMoods) {
      counts[mood] = (counts[mood] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, Map<String, dynamic>> getUserMoodContributions() {
    final result = <String, Map<String, dynamic>>{};

    _moodTrackingData.forEach((user, entries) {
      result[user] = {
        'count': entries.length,
        'entries': entries,
      };
    });

    return result;
  }
}
