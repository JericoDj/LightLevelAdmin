import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import '../../../models/articles_model.dart';
import '../../utils/colors.dart';  // Ensure this import is correct

class ArticlesContentScreen extends StatefulWidget {
  const ArticlesContentScreen({Key? key, required List<Article> articles}) : super(key: key);

  @override
  _ArticlesContentScreenState createState() => _ArticlesContentScreenState();
}

class _ArticlesContentScreenState extends State<ArticlesContentScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  List<Map<String, dynamic>> fetchedArticles = [];
  bool isReordering = false;

  @override
  void initState() {
    super.initState();
    _fetchFromFirestore();  // Fetch data when the screen initializes
  }

  Future<void> _fetchFromFirestore() async {
    try {
      DocumentSnapshot doc = await firestore.collection('contents').doc('articles').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        final List<Map<String, dynamic>> articlesList = [];
        data.forEach((key, value) {
          if (value is Map) {
            // Map the fetched Firestore data to your custom format
            articlesList.add({
              'thumbnail': value['thumbnail'],
              'title': value['title'],
              'paragraphs': List<String>.from(value['paragraphs'] ?? []),
              'sources': value['sources'] ?? '',
              'controller': TextEditingController(text: value['title']),
              'paragraphControllers': (value['paragraphs'] as List)
                  .map<TextEditingController>((para) => TextEditingController(text: para))
                  .toList(),

              'sourcesController': TextEditingController(text: value['sources'] ?? ''),
              'order': value['order'] ?? 0,
            });
          }
        });

        setState(() {
          fetchedArticles = articlesList;
        });
      }
    } catch (e) {
      print("Error fetching articles: $e");
    }
  }

  Future<void> _pickImageAndAdd() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      final imageBytes = result.files.single.bytes;
      final fileName = result.files.single.name;

      final ref = storage.ref('contents/articles/$fileName');
      await ref.putData(imageBytes!, SettableMetadata(contentType: 'image/png'));
      final url = await ref.getDownloadURL();

      final newEntry = {
        'thumbnail': url,
        'title': fileName,
        'controller': TextEditingController(text: fileName),
        'order': fetchedArticles.length,
        'paragraphs': [],
        'sources': '',
        'paragraphControllers': <TextEditingController>[], // Initialize empty paragraph controllers
        'sourcesController': TextEditingController(text: ''), // Initialize sources controller
      };

      setState(() {
        fetchedArticles.add(newEntry);
      });

      await _updateFirestoreOrderAndTitles();
    }
  }

  Future<void> _updateFirestoreOrderAndTitles() async {
    final updates = <String, dynamic>{};
    for (int i = 0; i < fetchedArticles.length; i++) {
      updates['article${i + 1}'] = {
        'thumbnail': fetchedArticles[i]['thumbnail'],
        'title': fetchedArticles[i]['controller'].text,
        'order': i,
        'paragraphs': fetchedArticles[i]['paragraphs'],
        'sources': fetchedArticles[i]['sourcesController'].text,
      };
    }

    await firestore.collection('contents').doc('articles').set(updates);
  }

  void _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final movedItem = fetchedArticles.removeAt(oldIndex);
    fetchedArticles.insert(newIndex, movedItem);

    for (int i = 0; i < fetchedArticles.length; i++) {
      fetchedArticles[i]['order'] = i;
    }

    await _updateFirestoreOrderAndTitles();
    setState(() {});
  }

  // Method to add a new paragraph for the specific article
  void _addParagraph(int articleIndex) {
    setState(() {
      fetchedArticles[articleIndex]['paragraphControllers'].add(TextEditingController());
      fetchedArticles[articleIndex]['paragraphs'].add(''); // Add an empty paragraph initially
    });
  }

  // Method to remove a paragraph from a specific article
  void _removeParagraph(int articleIndex, int paragraphIndex) {
    setState(() {
      fetchedArticles[articleIndex]['paragraphControllers'].removeAt(paragraphIndex);
      fetchedArticles[articleIndex]['paragraphs'].removeAt(paragraphIndex); // Remove paragraph from list
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBar(
          backgroundColor: Colors.green[800],
          elevation: 0,
          title: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Mindhub Article Contents',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: MediaQuery.of(context).size.width * 0.012,
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: _pickImageAndAdd,
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Divider(height: 20),
              Container(
                height: 250,
                child: fetchedArticles.isEmpty
                    ? Center(child: Text('No uploaded articles found.'))
                    : isReordering
                    ? ReorderableListView(
                  scrollDirection: Axis.horizontal,
                  onReorder: _onReorder,
                  children: [
                    ...fetchedArticles.map((article) {
                      return Container(
                        key: ValueKey(article['thumbnail']),
                        width: 200,
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    article['thumbnail'],
                                    height: 160,
                                    width: 200,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Icon(Icons.drag_handle, color: Colors.grey[600], size: 20),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: article['controller'],
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(vertical: 6),
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (_) => _updateFirestoreOrderAndTitles(),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                )
                    : ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ...fetchedArticles.map((article) {
                      return Container(
                        height: 100,
                        width: 200,
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  article['thumbnail'],
                                  height: 113,
                                  width: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            TextField(
                              controller: article['controller'],
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (_) =>
                                  _updateFirestoreOrderAndTitles(),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Add Paragraph Button for each article
              for (int i = 0; i < fetchedArticles.length; i++) ...[
                ElevatedButton(
                  onPressed: () => _addParagraph(i),
                  child: Text('Add Paragraph to Article ${i + 1}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyColors.color2, // consistent green
                    foregroundColor: MyColors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                SizedBox(height: 20),
                // Display paragraph fields for each article
                for (int j = 0; j < fetchedArticles[i]['paragraphControllers'].length; j++) ...[
                  TextField(
                    controller: fetchedArticles[i]['paragraphControllers'][j],
                    decoration: InputDecoration(
                      labelText: 'Paragraph ${j + 1} for Article ${i + 1}',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () => _removeParagraph(i, j), // Remove paragraph button
                  ),
                ],
                SizedBox(height: 20),

                // Sources Field
                TextField(
                  controller: fetchedArticles[i]['sourcesController'],
                  decoration: InputDecoration(
                    labelText: 'Sources for Article ${i + 1}',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _updateFirestoreOrderAndTitles(),
                ),
              ],

              SizedBox(height: 12),
              ElevatedButton.icon(
                icon: Icon(Icons.save, color: MyColors.color2),
                label: const Text('Save All Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColors.greyLight,
                  foregroundColor: MyColors.color2,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: MyColors.color2, width: 1), // 👈 border added
                  ),
                  elevation: 4,
                ),
                onPressed: () async {
                  for (int i = 0; i < fetchedArticles.length; i++) {
                    final article = fetchedArticles[i];
                    final title = article['controller'].text;
                    final sources = article['sourcesController'].text;

                    final paragraphControllers =
                    article['paragraphControllers'] as List<TextEditingController>;
                    final paragraphs = paragraphControllers.map((c) => c.text).toList();

                    article['title'] = title;
                    article['sources'] = sources;
                    article['paragraphs'] = paragraphs;
                  }

                  await _updateFirestoreOrderAndTitles();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All changes saved to Firestore ✅')),
                  );
                },
              ),

              SizedBox(height: 20),


              GestureDetector(
                onTap: () {
                  setState(() {
                    isReordering = !isReordering;
                  });
                },
                child: Container(
                  height: 40,
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: MyColors.color2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isReordering ? Icons.check : Icons.swap_vert,
                        color: MyColors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isReordering ? 'Done' : 'Rearrange',
                        style: const TextStyle(
                          color: MyColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
