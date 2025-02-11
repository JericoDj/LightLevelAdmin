import 'package:flutter/material.dart';
import 'package:lightlevelpsychosolutionsadmin/utils/colors.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white10,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Section
            const Text(
              textAlign: TextAlign.center,
              "Admin Dashboard",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: MyColors.color1),
            ),
            const SizedBox(height: 20),

            // Grid Layout for Dashboard Cards
            Expanded(
              child: GridView.count(
                crossAxisCount: 3, // 3 columns
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _buildDashboardCard("📊 Average Mood", "Neutral (3.5/5)", Colors.blueAccent),
                  _buildDashboardCard("⚡ Average Stress Level", "Moderate (2.8/5)", Colors.orangeAccent),
                  _buildDashboardCard("📅 Safe Space Pending Sessions", "12 Sessions", Colors.redAccent),
                  _buildDashboardCard("🕒 24/7 Safe Space Queue", "8 Users", Colors.purpleAccent),
                  _buildDashboardCard("📞 Customer Support Queue", "5 Tickets", Colors.greenAccent),
                  _buildDashboardCard("🌍 Community Pending Posts", "15 Posts", Colors.tealAccent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper function to create dashboard cards
  Widget _buildDashboardCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
