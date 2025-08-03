import 'package:flutter/material.dart';

class MoodReportWidget extends StatelessWidget {
  final String moodTrend;
  final Map<String, int> moodCounts;

  const MoodReportWidget({
    super.key,
    required this.moodTrend,
    required this.moodCounts,
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
    // Ensure all 5 moods are included
    final Map<String, int> completeCounts = {
      for (var mood in fixedMoods) mood: moodCounts[mood] ?? 0,
    };

    final int maxCount = completeCounts.isNotEmpty
        ? completeCounts.values.reduce((a, b) => a > b ? a : b)
        : 1;

    return Container(
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
    );
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
}
