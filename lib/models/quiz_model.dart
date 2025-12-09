// quiz_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Quiz {
  final String id;
  final String category;
  final String title;
  final String description;
  final bool isPersonalityBased;
  final List<QuizQuestion> questions;
  final DateTime createdAt;
  final DateTime updatedAt;

  Quiz({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.isPersonalityBased,
    required this.questions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Quiz.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final questions = (data['questions'] as List<dynamic>?)?.map((q) {
      return QuizQuestion.fromMap(q as Map<String, dynamic>);
    }).toList() ?? [];

    return Quiz(
      id: doc.id,
      category: data['category'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      isPersonalityBased: data['isPersonalityBased'] ?? false,
      questions: questions,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'category': category,
      'title': title,
      'description': description,
      'isPersonalityBased': isPersonalityBased,
      'questions': questions.map((q) => q.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class QuizQuestion {
  final String id;
  final String questionText;
  final List<QuizAnswer> answers;
  final int order;

  QuizQuestion({
    required this.id,
    required this.questionText,
    required this.answers,
    required this.order,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'] ?? '',
      questionText: map['questionText'] ?? '',
      answers: (map['answers'] as List<dynamic>).map((a) {
        return QuizAnswer.fromMap(a as Map<String, dynamic>);
      }).toList(),
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questionText': questionText,
      'answers': answers.map((a) => a.toMap()).toList(),
      'order': order,
    };
  }
}

class QuizAnswer {
  final String text;
  final int? score;
  final bool? isCorrect;

  QuizAnswer({
    required this.text,
    this.score,
    this.isCorrect,
  });

  factory QuizAnswer.fromMap(Map<String, dynamic> map) {
    return QuizAnswer(
      text: map['text'] ?? '',
      score: map['score'],
      isCorrect: map['isCorrect'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      if (score != null) 'score': score,
      if (isCorrect != null) 'isCorrect': isCorrect,
    };
  }
}