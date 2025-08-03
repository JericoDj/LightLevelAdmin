import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class StressReportWidget extends StatelessWidget {
  final String stressTrend;
  final Map<String, int> stressCounts;
  final String company;
  final List<String> selectedUsers;
  final Map<String, Map<String, dynamic>> userContributions;

  const StressReportWidget({
    super.key,
    required this.stressTrend,
    required this.stressCounts,
    required this.company,
    required this.selectedUsers,
    required this.userContributions,
  });

  @override
  Widget build(BuildContext context) {
    final total = stressCounts.values.fold<int>(0, (sum, val) => sum + val);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔥 Stress Summary',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _getGeneratedForText(),
            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
          Text(
            'Trend: $stressTrend',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),

          // ✅ Pie Chart
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 40,
                sectionsSpace: 6,
                sections: _buildPieChartSections(total),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ✅ Color Legend
          _buildLegend(),
          const SizedBox(height: 24),
          _buildUserBreakdown(userContributions),
        ],
      ),
    );
  }
  Widget _buildUserBreakdown(Map<String, Map<String, dynamic>> userContributions) {
    if (userContributions.isEmpty) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '👥 User Contributions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          ...userContributions.entries.map((entry) {
            final user = entry.key;
            final data = entry.value;
            final average = (data['average'] as double).toStringAsFixed(1);
            final entries = data['entries'] as List;

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
                  Text(
                    '👤 $user',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '📊 Average Stress Level: $average',
                    style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 10),
                  ...entries.map<Widget>((entry) {
                    final dateStr = entry['date'] ?? '';
                    final displayDate = _formatDate(dateStr);
                    final value = entry['value'];
                    final label = _getStressLabel(value);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.black54),
                          const SizedBox(width: 6),
                          Text('$displayDate — Stress Level: $value ($label)'),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
  String _getStressLabel(int value) {
    if (value <= 40) return 'Low';
    if (value <= 70) return 'Moderate';
    return 'High';
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMMM d').format(date); // e.g. August 2
    } catch (_) {
      return dateStr; // fallback to raw string if parsing fails
    }
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

  List<PieChartSectionData> _buildPieChartSections(int total) {
    return stressCounts.entries.map((entry) {
      final value = entry.value.toDouble();
      final percentage = total > 0 ? (value / total) * 100 : 0.0;

      return PieChartSectionData(
        color: _getSectionColor(entry.key),
        value: value,
        title: '${percentage.toStringAsFixed(1)}%',
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
        radius: 60,
      );
    }).toList();
  }

  Color _getSectionColor(String level) {
    switch (level) {
      case "Low":
        return Colors.greenAccent;
      case "Moderate":
        return Colors.orangeAccent;
      case "High":
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Color Guide:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6),
        Row(
          children: [
            _LegendItem(color: Colors.greenAccent, label: 'Low (10–40)'),
            SizedBox(width: 12),
            _LegendItem(color: Colors.orangeAccent, label: 'Moderate (50–70)'),
            SizedBox(width: 12),
            _LegendItem(color: Colors.redAccent, label: 'High (80–100)'),
          ],
        ),



      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 14, height: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
