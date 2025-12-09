import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lightlevelpsychosolutionsadmin/models/quiz_model.dart';

import '../../utils/colors.dart';

class AdminQuizManagementScreen extends StatefulWidget {
  const AdminQuizManagementScreen({super.key});

  @override
  _AdminQuizManagementScreenState createState() => _AdminQuizManagementScreenState();
}

class _AdminQuizManagementScreenState extends State<AdminQuizManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _categories = [
    'Mindfulness',
    'Cognitive Skills',
    'Emotional Intelligence',
    'Resilience',
    'Deep Focus',
    'Mental Clarity',
    'Positivity Boost'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage InsightQuest Quizzes'),
        backgroundColor: MyColors.color1,
        foregroundColor: MyColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: MyColors.white),
            tooltip: 'Add New Quiz Category',
            onPressed: _showAddQuizDialog,
          ),
        ],
      ),

      body: ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('quizzes').doc(category).collection('quizzes').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListTile(
                  title: Text('Loading...'),
                  leading: CircularProgressIndicator(),
                );
              }

              final quizDocs = snapshot.data?.docs ?? [];

              return ExpansionTile(
                title: Text('$category (${quizDocs.length} quizzes)'),
                leading: const Icon(
                  Icons.folder,
                  color: MyColors.color2, // or any theme color you'd like
                ),
                children: [
                  for (final doc in quizDocs)
                    _buildQuizTile(Quiz.fromFirestore(doc), category),
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline, color: Colors.green),
                    title: const Text('Add New Quiz'),
                    onTap: () => _createNewQuiz(category),
                  ),
                ],
              );
            },
          );
        },
      ),

    );
  }

  Widget _buildQuizTile(Quiz quiz, String category) {
    return Card(
      color: MyColors.greyLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          quiz.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${quiz.questions.length} questions'),
        leading: Icon(
          _isPersonalityBasedCategory(category) ? Icons.psychology : Icons.lightbulb_outline,
          color: MyColors.color2,
        ),
        children: [
          ...quiz.questions.map((question) => ListTile(
            title: Text(question.questionText),
            subtitle: Text('${question.answers.length} options'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon:  Icon(Icons.edit, color: MyColors.black),
                  onPressed: () => _editQuestionDialog(quiz, question),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteQuestion(quiz, question),
                ),
              ],
            ),
          )),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: MyColors.color1),
            title: const Text('Add New Question'),
            onTap: () => _addQuestionDialog(quiz),
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Entire Quiz'),
            onTap: () => _confirmDeleteQuiz(quiz),
          ),
        ],
      ),
    );
  }



  Future<void> _createNewQuiz(String category) async {
    try {
      final newQuiz = {
        'category': category,
        'title': '$category Quiz ${DateTime.now().millisecondsSinceEpoch}',
        'description': 'Take this quiz to assess your $category skills',
        'isPersonalityBased': _isPersonalityBasedCategory(category),
        'questions': [],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      // Create the parent doc if it doesn’t exist
      final categoryDocRef = _firestore.collection('quizzes').doc(category);
      await categoryDocRef.set({'lastUpdated': Timestamp.now()}, SetOptions(merge: true));

      // Add a new quiz under the category
      await categoryDocRef.collection('quizzes').add(newQuiz);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('New quiz added under $category')),
      );

      setState(() {}); // Refresh
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating quiz: ${e.toString()}')),
      );
    }
  }


  bool _isPersonalityBasedCategory(String category) {
    return category != 'Cognitive Skills';
  }

  Future<void> _addQuestionDialog(Quiz quiz) async {
    final TextEditingController questionController = TextEditingController();
    final List<Map<String, dynamic>> answers = [];
    bool isPersonality = quiz.isPersonalityBased;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Question'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: questionController,
                      decoration: const InputDecoration(labelText: 'Question Text'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    const Text('Answers:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...answers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final answer = entry.value;
                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: TextEditingController(text: answer['text']),
                              onChanged: (value) => answers[index]['text'] = value,
                              decoration: const InputDecoration(labelText: 'Answer text'),
                            ),
                          ),
                          if (isPersonality) ...[
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: TextEditingController(text: answer['score']?.toString()),
                                keyboardType: TextInputType.number,
                                onChanged: (value) => answers[index]['score'] = int.tryParse(value) ?? 0,
                                decoration: const InputDecoration(labelText: 'Score'),
                              ),
                            ),
                          ] else ...[
                            Checkbox(
                              value: answer['isCorrect'] ?? false,
                              onChanged: (value) => setState(() {
                                answers[index]['isCorrect'] = value;
                              }),
                            ),
                          ],
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => setState(() => answers.removeAt(index)),
                          ),
                        ],
                      );
                    }).toList(),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        answers.add({
                          'text': '',
                          if (isPersonality) 'score': 0,
                          if (!isPersonality) 'isCorrect': false,
                        });
                      }),
                      child: const Text('Add Answer Option'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (questionController.text.isEmpty || answers.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter question and at least one answer')),
                      );
                      return;
                    }

                    try {
                      final newQuestion = {
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'questionText': questionController.text,
                        'answers': answers,
                        'order': quiz.questions.length + 1,
                      };

                      await _firestore
                          .collection('quizzes')
                          .doc(quiz.category)
                          .collection('quizzes')
                          .doc(quiz.id)
                          .update({
                        'questions': FieldValue.arrayUnion([newQuestion]),
                        'updatedAt': Timestamp.now(),
                      });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Question added successfully!')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error adding question: ${e.toString()}')),
                      );
                    }
                  },
                  child: const Text('Save Question'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _editQuestionDialog(Quiz quiz, QuizQuestion question) async {
    final TextEditingController questionController = TextEditingController(text: question.questionText);
    List<Map<String, dynamic>> answers = question.answers.map((a) => a.toMap()).toList();
    bool isPersonality = quiz.isPersonalityBased;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Question'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: questionController,
                      decoration: const InputDecoration(labelText: 'Question Text'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    const Text('Answers:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...answers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final answer = entry.value;
                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: TextEditingController(text: answer['text']),
                              onChanged: (value) => answers[index]['text'] = value,
                              decoration: const InputDecoration(labelText: 'Answer text'),
                            ),
                          ),
                          if (isPersonality) ...[
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: TextEditingController(text: answer['score']?.toString()),
                                keyboardType: TextInputType.number,
                                onChanged: (value) => answers[index]['score'] = int.tryParse(value) ?? 0,
                                decoration: const InputDecoration(labelText: 'Score'),
                              ),
                            ),
                          ] else ...[
                            Checkbox(
                              value: answer['isCorrect'] ?? false,
                              onChanged: (value) => setState(() {
                                answers[index]['isCorrect'] = value;
                              }),
                            ),
                          ],
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => setState(() => answers.removeAt(index)),
                          ),
                        ],
                      );
                    }).toList(),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        answers.add({
                          'text': '',
                          if (isPersonality) 'score': 0,
                          if (!isPersonality) 'isCorrect': false,
                        });
                      }),
                      child: const Text('Add Answer Option'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (questionController.text.isEmpty || answers.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter question and at least one answer')),
                      );
                      return;
                    }

                    try {
                      // First remove the old question
                      await _firestore.collection('contents/quizzes').doc(quiz.category).update({
                        'questions': FieldValue.arrayRemove([question.toMap()]),
                      });

                      // Add the updated question
                      final updatedQuestion = {
                        'id': question.id,
                        'questionText': questionController.text,
                        'answers': answers,
                        'order': question.order,
                      };

                      await _firestore.collection('contents/quizzes').doc(quiz.category).update({
                        'questions': FieldValue.arrayUnion([updatedQuestion]),
                        'updatedAt': Timestamp.now(),
                      });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Question updated successfully!')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating question: ${e.toString()}')),
                      );
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteQuestion(Quiz quiz, QuizQuestion question) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question?'),
        content: Text('Are you sure you want to delete: "${question.questionText}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Make sure you’re removing the exact map
        final questionMap = {
          'id': question.id,
          'questionText': question.questionText,
          'answers': question.answers.map((a) => a.toMap()).toList(),
          'order': question.order,
        };

        await _firestore
            .collection('quizzes')
            .doc(quiz.category)
            .collection('quizzes')
            .doc(quiz.id)
            .update({
          'questions': FieldValue.arrayRemove([questionMap]),
          'updatedAt': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question deleted successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting question: ${e.toString()}')),
        );
      }
    }
  }



  Future<void> _confirmDeleteQuiz(Quiz quiz) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entire Quiz?'),
        content: Text('Are you sure you want to delete the "${quiz.title}" quiz with ${quiz.questions.length} questions?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore
            .collection('quizzes')                  // top-level
            .doc(quiz.category)                     // e.g., "Mindfulness"
            .collection('quizzes')                  // subcollection under category
            .doc(quiz.id)                           // the actual quiz document
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz deleted successfully!')),
        );

        setState(() {}); // Refresh UI
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting quiz: ${e.toString()}')),
        );
      }
    }
  }


  void _showAddQuizDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Quiz Category'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return ListTile(
                  title: Text(category),
                  onTap: () {
                    Navigator.pop(context);
                    _createNewQuiz(category);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}