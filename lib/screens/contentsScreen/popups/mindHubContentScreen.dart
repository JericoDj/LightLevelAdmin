

// mindhub_content_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/contentsScreen/popups/mind_hub_articles_popup.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/contentsScreen/popups/mind_hub_videos_popup.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/contentsScreen/popups/mind_hub_ebooks_popup.dart';

import '../../../models/articles_model.dart';
import '../../../models/ebooks_model.dart';
import '../../../models/videos_models.dart';
import '../../../utils/colors.dart';

class MindHubContentScreen extends StatelessWidget {
  final List<Article> articles;
  final List<Video> videos;
  final List<Ebook> ebooks;

  const MindHubContentScreen({Key? key, required this.articles, required this.videos, required this.ebooks}) : super(key: key);

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
                'Mindhub Contents',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: MediaQuery.of(context).size.width * 0.012  ,
                ),
              ),
            ),
          ),
          backgroundColor: Colors.green[800],
          elevation: 0,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSectionButton(
              context,
              title: 'Upload MindHub Articles',
              onTap: () => context.go('/articles-content', extra: articles),
            ),
            const SizedBox(width: 30), // spacing between buttons
            _buildSectionButton(
              context,
              title: 'Upload MindHub Videos',
              onTap: () => context.go('/videos-content', extra: videos),
            ),
            const SizedBox(width: 30),
            _buildSectionButton(
              context,
              title: 'Upload MindHub Ebooks',
              onTap: () => context.go('/ebooks-content', extra: ebooks),
            ),
          ],
        ),

      ),
    );


  }
}


Widget _buildSectionButton(
    BuildContext context, {
      required String title,
      required VoidCallback onTap,
    }) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10.0),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: MyColors.color2,
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