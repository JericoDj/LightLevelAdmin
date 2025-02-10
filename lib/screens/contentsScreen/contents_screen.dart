import 'package:flutter/material.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/contentsScreen/popups/home_page_image_popup.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/contentsScreen/popups/insightquest_cognitive_quiz_dialog.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/contentsScreen/popups/insightquest_deepfocus_quiz_dialog.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/contentsScreen/popups/insightquest_emotional_quiz_dialog.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/contentsScreen/popups/insightquest_mentalclarity_quiz_dialog.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/contentsScreen/popups/insightquest_mindfulness_quiz_dialog.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/contentsScreen/popups/insightquest_positivity_quiz_dialog.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/contentsScreen/popups/insightquest_resilience_quiz_dialog.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/contentsScreen/popups/mind_hub_articles_popup.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/contentsScreen/popups/mind_hub_ebooks_popup.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/contentsScreen/popups/mind_hub_videos_popup.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/contentsScreen/popups/mindhub_videos_popup.dart';

import '../../models/articles_model.dart';
import '../../models/ebooks_model.dart';
import '../../models/videos_models.dart';

class ContentsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<Article> articles = [
      Article(title: "Article 1", body: "Body 1", sources: "Source 1", thumbnail: "thumbnail1.png"),
      Article(title: "Article 2", body: "Body 2", sources: "Source 2", thumbnail: "thumbnail2.png"),
    ];

    List<Video> videos = [
      Video(title: "Video 1", description: "Educational Video 1", thumbnail: "video_thumbnail1.png", videoFile: "video1.mp4"),
      Video(title: "Video 2", description: "Educational Video 2", thumbnail: "video_thumbnail2.png", videoFile: "video2.mp4"),
    ];

    List<Ebook> ebooks = [
      Ebook(
        id: "1",
        title: "Mindfulness for Beginners",
        description: "An introductory guide to mindfulness and meditation.",
        cover: "ebook_cover1.png",
        ebookFile: "mindfulness_for_beginners.pdf",
      ),
      Ebook(
        id: "2",
        title: "The Science of Positivity",
        description: "A deep dive into how positive thinking affects mental health.",
        cover: "ebook_cover2.png",
        ebookFile: "science_of_positivity.pdf",
      ),
    ];




    return Scaffold(
      appBar: AppBar(
        title: const Text('Contents Section'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSectionTitle('Home Page'),
            _buildOptionsRow(context, [
              {'title': 'Home Page Images', 'dialog': () => showHomePageImagesDialog(context)},
            ]),

            _buildSectionTitle('MindHub'),
            _buildOptionsRow(context, [
              {'title': 'MindHub Articles', 'dialog': () => showMindHubArticlesDialog(context, articles)},
              {'title': 'MindHub Videos', 'dialog': () => showMindHubVideosDialog(context, videos)},
              {'title': 'MindHub Ebooks', 'dialog': () => showMindHubEbooksDialog(context, ebooks)},
            ]),

            _buildSectionTitle('InsightQuest'),
            _buildOptionsRow(context, [
              {'title': 'Mindfulness Quiz', 'dialog': () => showMindfulnessQuizDialog(context)},
              {'title': 'Cognitive Quiz', 'dialog': () => showCognitiveQuizDialog(context)},
              {'title': 'Emotional Intelligence Quiz', 'dialog': () => showEmotionalQuizDialog(context)},
              {'title': 'Resilience Quiz', 'dialog': () => showResilienceQuizDialog(context)},
              {'title': 'Deep Focus Quiz', 'dialog': () => showDeepFocusQuizDialog(context)},
              {'title': 'Mental Clarity Quiz', 'dialog': () => showMentalClarityQuizDialog(context)},
              {'title': 'Positivity Boost Quiz', 'dialog': () => showPositivityQuizDialog(context)},
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    );
  }

  Widget _buildOptionsRow(BuildContext context, List<Map<String, dynamic>> options) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options
            .map(
              (option) => GestureDetector(
            onTap: option['dialog'],
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.blue[50],
                ),
                child: Center(
                  child: Text(
                    option['title']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
              ),
            ),
          ),
        )
            .toList(),
      ),
    );
  }
}
