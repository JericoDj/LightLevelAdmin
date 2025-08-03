import 'package:flutter/material.dart';

class MoodReportWidget extends StatelessWidget {
  final String moodTrend;
  final Map<String, int> moodCounts;
  final String company;
  final List<String> selectedUsers;
  final Map<String, Map<String, dynamic>>? userMoodData; // 👈 Added optional contributions

  const MoodReportWidget({
    super.key,
    required this.moodTrend,
    required this.moodCounts,
    required this.company,
    required this.selectedUsers,
    this.userMoodData,
  });

  static const List<String> fixedMoods = [
    "Happy",
    "Neutral",
    "Sad",
    "Angry",
    "Anxious",
  ];

  @override
  Widget build(BuildContext context) {
    final Map<String, int> completeCounts = {
      for (var mood in fixedMoods) mood: moodCounts[mood] ?? 0,
    };

    final int maxCount = completeCounts.isNotEmpty
        ? completeCounts.values.reduce((a, b) => a > b ? a : b)
        : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🧠 Mood Summary',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _getGeneratedForText(),
                style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              Text(
                'Trend: $moodTrend',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: completeCounts.entries.map((entry) {
                    double rawFactor = maxCount > 0 ? (entry.value / maxCount).toDouble() : 0.0;
                    double heightFactor = entry.value == 0 ? 0.0 : rawFactor.clamp(0.1, 1.0);

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text("${entry.value}", style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 6),
                        Container(
                          height: 100,
                          width: 30,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: heightFactor,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _getBarColor(entry.key),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.key,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // 👇 Mood Contributions Section
        if (userMoodData != null) buildMoodContributionsWithDates(userMoodData!),
      ],
    );
  }

  String _getGeneratedForText() {
    if (selectedUsers.length == 1) {
      return 'Generated for: ${selectedUsers.first}';
    } else if (selectedUsers.length <= 5) {
      return 'Generated for: ${selectedUsers.join(", ")}';
    } else {
      return 'Generated for: Multiple users in $company';
    }
  }

  Color _getBarColor(String mood) {
    return {
      "Happy": Colors.green,
      "Neutral": Colors.amber,
      "Sad": Colors.redAccent,
      "Angry": Colors.deepOrange,
      "Anxious": Colors.blue,
    }[mood] ?? Colors.grey;
  }

  Widget buildMoodContributionsWithDates(Map<String, Map<String, dynamic>> userMoodData) {
    if (userMoodData.isEmpty) return const SizedBox();

    const moodEmojis = {
      "Happy": "😃",
      "Neutral": "😐",
      "Sad": "😢",
      "Angry": "😠",
      "Anxious": "😰",
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🧑‍🤝‍🧑 Mood Contributions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          ...userMoodData.entries.map((entry) {
            final name = entry.key;
            final entries = entry.value['entries'] as List;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('👤 $name (${entries.length} entries)',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  ...entries.map((item) {
                    final mood = item['mood'];
                    final date = item['date'];
                    final emoji = moodEmojis[mood] ?? '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Text("📅 $date", style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 12),
                          Text('$emoji $mood', style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

}
