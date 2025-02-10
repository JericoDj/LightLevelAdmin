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
import '../../models/quiz_model.dart';
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
// Sample Quiz Data - Mindfulness (Personality-Based)
    Quiz mindfulnessQuiz = Quiz(
      title: "Mindfulness",
      isPersonalityBased: true,
      questions: [
        QuizQuestion(
          question: "How often do you take a moment to breathe and be present?",
          answers: [
            QuizAnswer(text: "Very often", score: 3),
            QuizAnswer(text: "Sometimes", score: 2),
            QuizAnswer(text: "Rarely", score: 1),
            QuizAnswer(text: "Almost never", score: 0),
          ],
        ),
        QuizQuestion(
          question: "Do you often catch yourself overthinking?",
          answers: [
            QuizAnswer(text: "Rarely", score: 3),
            QuizAnswer(text: "Occasionally", score: 2),
            QuizAnswer(text: "Often", score: 1),
            QuizAnswer(text: "Always", score: 0),
          ],
        ),
      ],
    );

    Quiz emotionalQuiz = Quiz(
      title: "Emotional Intelligence",
      isPersonalityBased: true,
      questions: [
        QuizQuestion(
          question: "How well do you recognize emotions in yourself and others?",
          answers: [
            QuizAnswer(text: "Very well", score: 3),
            QuizAnswer(text: "Sometimes", score: 2),
            QuizAnswer(text: "Rarely", score: 1),
            QuizAnswer(text: "Not at all", score: 0),
          ],
        ),
      ],
    );

// Sample Quiz Data - Cognitive Skills (Knowledge-Based)
    Quiz cognitiveQuiz = Quiz(
      title: "Cognitive Skills",
      isPersonalityBased: false,
      questions: [
        QuizQuestion(
          question: "Which part of the brain is responsible for problem-solving?",
          answers: [
            QuizAnswer(text: "Frontal lobe", isCorrect: true),
            QuizAnswer(text: "Occipital lobe", isCorrect: false),
            QuizAnswer(text: "Temporal lobe", isCorrect: false),
            QuizAnswer(text: "Parietal lobe", isCorrect: false),
          ],
        ),
        QuizQuestion(
          question: "What is 15 + 27?",
          answers: [
            QuizAnswer(text: "42", isCorrect: true),
            QuizAnswer(text: "39", isCorrect: false),
            QuizAnswer(text: "47", isCorrect: false),
            QuizAnswer(text: "41", isCorrect: false),
          ],
        ),
        QuizQuestion(
          question: "What does CPU stand for?",
          answers: [
            QuizAnswer(text: "Central Processing Unit", isCorrect: true),
            QuizAnswer(text: "Computer Power Unit", isCorrect: false),
            QuizAnswer(text: "Central Program Unit", isCorrect: false),
            QuizAnswer(text: "Central Processing Utility", isCorrect: false),
          ],
        ),
        QuizQuestion(
          question: "Which of the following is a prime number?",
          answers: [
            QuizAnswer(text: "17", isCorrect: true),
            QuizAnswer(text: "21", isCorrect: false),
            QuizAnswer(text: "33", isCorrect: false),
            QuizAnswer(text: "44", isCorrect: false),
          ],
        ),
      ],
    );

    Quiz resilienceQuiz = Quiz(
      title: "Resilience",
      isPersonalityBased: true, // Score-based
      questions: [
        QuizQuestion(
          question: "How well do you handle stressful situations?",
          answers: [
            QuizAnswer(text: "Very well", score: 3),
            QuizAnswer(text: "Sometimes well", score: 2),
            QuizAnswer(text: "Not very well", score: 1),
            QuizAnswer(text: "I often struggle", score: 0),
          ],
        ),
      ],
    );


    Quiz deepFocusQuiz = Quiz(
      title: "Deep Focus",
      isPersonalityBased: true, // Score-based
      questions: [
        QuizQuestion(
          question: "Do you find it easy to concentrate for long periods?",
          answers: [
            QuizAnswer(text: "Yes, very easy", score: 3),
            QuizAnswer(text: "Sometimes", score: 2),
            QuizAnswer(text: "Rarely", score: 1),
            QuizAnswer(text: "No, I get distracted often", score: 0),
          ],
        ),
      ],
    );

    Quiz mentalClarityQuiz = Quiz(
      title: "Mental Clarity",
      isPersonalityBased: true, // Score-based
      questions: [
        QuizQuestion(
          question: "How well do you maintain focus throughout the day?",
          answers: [
            QuizAnswer(text: "Very well", score: 3),
            QuizAnswer(text: "Somewhat well", score: 2),
            QuizAnswer(text: "Not very well", score: 1),
            QuizAnswer(text: "I get distracted easily", score: 0),
          ],
        ),
      ],
    );


    Quiz positivityQuiz = Quiz(
      title: "Positivity Boost",
      isPersonalityBased: true, // Score-based
      questions: [
        QuizQuestion(
          question: "How often do you practice gratitude?",
          answers: [
            QuizAnswer(text: "Daily", score: 3),
            QuizAnswer(text: "A few times a week", score: 2),
            QuizAnswer(text: "Rarely", score: 1),
            QuizAnswer(text: "Never", score: 0),
          ],
        ),
      ],
    );









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
              {'title': 'Mindfulness Quiz', 'dialog': () => showMindfulnessQuizDialog(context, mindfulnessQuiz)},
              {'title': 'Cognitive Quiz', 'dialog': () => showCognitiveQuizDialog(context, cognitiveQuiz)},
              {'title': 'Emotional Intelligence Quiz', 'dialog': () => showEmotionalQuizDialog(context,emotionalQuiz)},
              {'title': 'Resilience Quiz', 'dialog': () => showResilienceQuizDialog(context,resilienceQuiz)},
              {'title': 'Deep Focus Quiz', 'dialog': () => showDeepFocusQuizDialog(context,deepFocusQuiz)},
              {'title': 'Mental Clarity Quiz', 'dialog': () => showMentalClarityQuizDialog(context, mentalClarityQuiz)},
              {'title': 'Positivity Boost Quiz', 'dialog': () => showPositivityQuizDialog(context,positivityQuiz)},
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
