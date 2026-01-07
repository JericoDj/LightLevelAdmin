// main_contents_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/contentsScreen/popups/mindHubContentScreen.dart';
import 'package:lightlevelpsychosolutionsadmin/utils/colors.dart';

import 'homepagecontents.dart';
import 'insightquest.dart';

class ContentsScreen extends StatelessWidget {
  const ContentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50), // <-- set your desired height here
        child: AppBar(
          title: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child:  Text(
                'Contents Management',
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            Row(
              spacing: 30,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildSectionButton(
                  context,
                  title: 'Home Page',
                  onTap: () => context.go('/navigation/contents/homepage'),
                ),
                _buildSectionButton(
                  context,
                  title: 'MindHub',
                  onTap: () => context.go('/navigation/contents/mindhub'),
                ),
                _buildSectionButton(
                  context,
                  title: 'InsightQuest',
                  onTap: () => context.go('/navigation/contents/insightquest'),
                ),
              ],
            ),
          ],
        )

      ),
    );
  }

  Widget _buildSectionButton(BuildContext context,
      {required String title, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:MyColors.color2,
          foregroundColor: MyColors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        onPressed: onTap,
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}