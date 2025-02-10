class Quiz {
  String title;
  bool isPersonalityBased;
  List<QuizQuestion> questions;

  Quiz({
    required this.title,
    required this.isPersonalityBased,
    required this.questions,
  });
}

class QuizQuestion {
  String question;
  List<QuizAnswer> answers;

  QuizQuestion({
    required this.question,
    required this.answers,
  });
}

class QuizAnswer {
  String text;
  int? score; // Used for personality-based quizzes
  bool? isCorrect; // Used for knowledge-based quizzes

  QuizAnswer({
    required this.text,
    this.score,
    this.isCorrect,
  });
}
