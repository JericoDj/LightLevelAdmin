import 'package:flutter/material.dart';
import '../../../models/quiz_model.dart';

void showPositivityQuizDialog(BuildContext context, Quiz quiz) {
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // **Header**
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${quiz.title} Quiz',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 20),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // **List of Quiz Questions**
                  Expanded(
                    child: quiz.questions.isEmpty
                        ? Center(child: Text("No questions added yet.", style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                      itemCount: quiz.questions.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text(quiz.questions[index].question),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  quiz.questions.removeAt(index);
                                });
                              },
                            ),
                            onTap: () {
                              showQuestionDialog(context, quiz, quiz.questions[index]);
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // **Footer Buttons**
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          showQuestionDialog(context, quiz, null);
                        },
                        icon: Icon(Icons.add, color: Colors.white),
                        label: Text("Add Question"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          print("Saving Positivity Boost Quiz...");
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.save, color: Colors.white),
                        label: Text("Save Quiz"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.close, color: Colors.white),
                        label: Text("Close"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// **Dialog to Add or Edit a Question**
void showQuestionDialog(BuildContext context, Quiz quiz, QuizQuestion? questionToEdit) {
  final TextEditingController questionController = TextEditingController(text: questionToEdit?.question);
  List<QuizAnswer> answers = questionToEdit?.answers ?? [];

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.5,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: questionController,
                    decoration: InputDecoration(labelText: 'Question'),
                  ),

                  const SizedBox(height: 16),

                  // **List of Answers**
                  ...answers.asMap().entries.map((entry) {
                    int index = entry.key;
                    QuizAnswer answer = entry.value;

                    return Column(
                      children: [
                        ListTile(
                          title: TextField(
                            decoration: InputDecoration(labelText: 'Answer ${index + 1}'),
                            onChanged: (value) {
                              answers[index] = QuizAnswer(
                                text: value,
                                score: quiz.isPersonalityBased ? answer.score : null,
                                isCorrect: !quiz.isPersonalityBased ? answer.isCorrect : null,
                              );
                            },
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                answers.removeAt(index);
                              });
                            },
                          ),
                        ),
                        if (quiz.isPersonalityBased)
                        // **Dropdown for Selecting Scores (0-3)**
                          Row(
                            children: [
                              Text("Score: "),
                              DropdownButton<int>(
                                value: answer.score,
                                onChanged: (value) {
                                  setState(() {
                                    answers[index] = QuizAnswer(
                                      text: answer.text,
                                      score: value,
                                    );
                                  });
                                },
                                items: [0, 1, 2, 3].map((score) {
                                  return DropdownMenuItem(
                                    value: score,
                                    child: Text(score.toString()),
                                  );
                                }).toList(),
                              ),
                            ],
                          )
                        else
                        // **Checkbox for Marking Correct Answer (for knowledge quizzes)**
                          CheckboxListTile(
                            title: Text("Mark as Correct"),
                            value: answer.isCorrect ?? false,
                            onChanged: (value) {
                              setState(() {
                                answers[index] = QuizAnswer(
                                  text: answer.text,
                                  isCorrect: value,
                                );
                              });
                            },
                          ),
                      ],
                    );
                  }).toList(),

                  const SizedBox(height: 16),

                  // **Add Answer Button**
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        answers.add(QuizAnswer(
                          text: "",
                          score: quiz.isPersonalityBased ? 0 : null,
                          isCorrect: !quiz.isPersonalityBased ? false : null,
                        ));
                      });
                    },
                    icon: Icon(Icons.add, color: Colors.white),
                    label: Text("Add Answer"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),

                  const SizedBox(height: 16),

                  // **Save & Cancel Buttons**
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (questionController.text.isNotEmpty) {
                            final newQuestion = QuizQuestion(
                              question: questionController.text,
                              answers: answers,
                            );

                            if (questionToEdit == null) {
                              quiz.questions.add(newQuestion);
                            } else {
                              final index = quiz.questions.indexOf(questionToEdit);
                              quiz.questions[index] = newQuestion;
                            }
                          }

                          Navigator.pop(context);
                          showPositivityQuizDialog(context, quiz);
                        },
                        child: Text(questionToEdit == null ? "Add Question" : "Save"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
