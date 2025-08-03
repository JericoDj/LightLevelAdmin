import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StressReportWidget extends StatelessWidget {
  final String stressTrend;
  final Map<String, int> stressCounts;
  final String company;
  final List<String> selectedUsers;

  const StressReportWidget({
    super.key,
    required this.stressTrend,
    required this.stressCounts,
    required this.company,
    required this.selectedUsers,
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
        ],
      ),
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
