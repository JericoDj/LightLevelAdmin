import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ArticlesProvider extends ChangeNotifier {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  List<Map<String, dynamic>> fetchedArticles = [];
  bool isReordering = false;
  int selectedArticleIndex = 0;

  ArticlesProvider() {
    fetchFromFirestore();
  }

  Future<void> fetchFromFirestore() async {
    try {
      DocumentSnapshot doc =
          await firestore.collection('contents').doc('articles').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        final List<Map<String, dynamic>> articlesList = [];
        data.forEach((key, value) {
          if (value is Map) {
            articlesList.add({
              'thumbnail': value['thumbnail'],
              'title': value['title'],
              'paragraphs': List<String>.from(value['paragraphs'] ?? []),
              'sources': value['sources'] is List
                  ? List<String>.from(value['sources'])
                  : (value['sources'] != null && value['sources'].toString().isNotEmpty
                      ? [value['sources'].toString()]
                      : <String>[]),
              'controller': TextEditingController(text: value['title']),
              'paragraphControllers': (value['paragraphs'] as List)
                  .map<TextEditingController>(
                      (para) => TextEditingController(text: para))
                  .toList(),
              'sourcesControllers': (value['sources'] is List
                      ? List<String>.from(value['sources'])
                      : (value['sources'] != null && value['sources'].toString().isNotEmpty
                          ? [value['sources'].toString()]
                          : <String>[]))
                  .map<TextEditingController>(
                      (src) => TextEditingController(text: src))
                  .toList(),
              'order': value['order'] ?? 0,
            });
          }
        });

        fetchedArticles = articlesList;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching articles: $e");
    }
  }

  Future<void> pickImageAndAdd() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      final imageBytes = result.files.single.bytes;
      final fileName = result.files.single.name;

      final ref = storage.ref('contents/articles/$fileName');
      await ref.putData(
          imageBytes!, SettableMetadata(contentType: 'image/png'));
      final url = await ref.getDownloadURL();

      final newEntry = {
        'thumbnail': url,
        'title': fileName,
        'controller': TextEditingController(text: fileName),
        'order': fetchedArticles.length,
        'paragraphs': <String>[],
        'sources': <String>[],
        'paragraphControllers': <TextEditingController>[],
        'sourcesControllers': <TextEditingController>[],
      };

      fetchedArticles.add(newEntry);
      selectedArticleIndex = fetchedArticles.length - 1;
      notifyListeners();

      await updateFirestoreOrderAndTitles();
    }
  }

  Future<void> changeArticleImage(int index) async {
    if (index < 0 || index >= fetchedArticles.length) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      final imageBytes = result.files.single.bytes;
      final fileName = result.files.single.name;

      final ref = storage.ref('contents/articles/$fileName');
      await ref.putData(
          imageBytes!, SettableMetadata(contentType: 'image/png'));
      final url = await ref.getDownloadURL();

      fetchedArticles[index]['thumbnail'] = url;
      notifyListeners();
    }
  }

  Future<void> updateFirestoreOrderAndTitles() async {
    final updates = <String, dynamic>{};
    for (int i = 0; i < fetchedArticles.length; i++) {
      updates['article${i + 1}'] = {
        'thumbnail': fetchedArticles[i]['thumbnail'],
        'title': fetchedArticles[i]['title'],
        'order': i,
        'paragraphs': fetchedArticles[i]['paragraphs'],
        'sources': fetchedArticles[i]['sources'],
      };
    }

    await firestore.collection('contents').doc('articles').set(updates);
  }

  void disposeArticle(Map<String, dynamic> article) {
    (article['controller'] as TextEditingController).dispose();
    for (final controller
        in article['sourcesControllers'] as List<TextEditingController>) {
      controller.dispose();
    }
    for (final controller
        in article['paragraphControllers'] as List<TextEditingController>) {
      controller.dispose();
    }
  }

  Future<void> deleteArticle(int articleIndex) async {
    final removedArticle = fetchedArticles[articleIndex];
    
    fetchedArticles.removeAt(articleIndex);
    if (selectedArticleIndex == articleIndex) {
      selectedArticleIndex = 0;
    } else if (selectedArticleIndex > articleIndex) {
      selectedArticleIndex--;
    }
    notifyListeners();
    
    disposeArticle(removedArticle);
    await updateFirestoreOrderAndTitles();
  }

  void onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final movedItem = fetchedArticles.removeAt(oldIndex);
    fetchedArticles.insert(newIndex, movedItem);

    for (int i = 0; i < fetchedArticles.length; i++) {
      fetchedArticles[i]['order'] = i;
    }

    if (selectedArticleIndex == oldIndex) {
      selectedArticleIndex = newIndex;
    } else if (selectedArticleIndex > oldIndex && selectedArticleIndex <= newIndex) {
      selectedArticleIndex--;
    } else if (selectedArticleIndex < oldIndex && selectedArticleIndex >= newIndex) {
      selectedArticleIndex++;
    }

    notifyListeners();
    await updateFirestoreOrderAndTitles();
  }

  void addParagraph(int articleIndex) {
    fetchedArticles[articleIndex]['paragraphControllers']
        .add(TextEditingController());
    notifyListeners();
  }

  void removeParagraph(int articleIndex, int paragraphIndex) {
    fetchedArticles[articleIndex]['paragraphControllers']
        .removeAt(paragraphIndex);
    notifyListeners();
  }

  void moveParagraphUp(int articleIndex, int paragraphIndex) {
    if (paragraphIndex > 0) {
      final controllers = fetchedArticles[articleIndex]['paragraphControllers'] as List<TextEditingController>;
      final item = controllers.removeAt(paragraphIndex);
      controllers.insert(paragraphIndex - 1, item);
      notifyListeners();
    }
  }

  void moveParagraphDown(int articleIndex, int paragraphIndex) {
    final controllers = fetchedArticles[articleIndex]['paragraphControllers'] as List<TextEditingController>;
    if (paragraphIndex < controllers.length - 1) {
      final item = controllers.removeAt(paragraphIndex);
      controllers.insert(paragraphIndex + 1, item);
      notifyListeners();
    }
  }

  void addSource(int articleIndex) {
    fetchedArticles[articleIndex]['sourcesControllers']
        .add(TextEditingController());
    notifyListeners();
  }

  void removeSource(int articleIndex, int sourceIndex) {
    fetchedArticles[articleIndex]['sourcesControllers']
        .removeAt(sourceIndex);
    notifyListeners();
  }

  bool hasUnsavedChanges(int index) {
    if (index < 0 || index >= fetchedArticles.length) return false;
    final article = fetchedArticles[index];

    if (article['controller'].text != article['title']) return true;

    final sources = article['sources'] as List<String>;
    final sourcesControllers =
        article['sourcesControllers'] as List<TextEditingController>;

    if (sources.length != sourcesControllers.length) return true;
    for (int i = 0; i < sources.length; i++) {
      if (sources[i] != sourcesControllers[i].text) return true;
    }

    final paragraphs = article['paragraphs'] as List<String>;
    final paragraphControllers =
        article['paragraphControllers'] as List<TextEditingController>;

    if (paragraphs.length != paragraphControllers.length) return true;
    for (int i = 0; i < paragraphs.length; i++) {
      if (paragraphs[i] != paragraphControllers[i].text) return true;
    }
    return false;
  }

  void saveArticleLocally(int index) {
    if (index < 0 || index >= fetchedArticles.length) return;
    final article = fetchedArticles[index];
    article['title'] = article['controller'].text;

    final sourcesControllers =
        article['sourcesControllers'] as List<TextEditingController>;
    article['sources'] = sourcesControllers.map((c) => c.text).toList();

    final paragraphControllers =
        article['paragraphControllers'] as List<TextEditingController>;
    article['paragraphs'] = paragraphControllers.map((c) => c.text).toList();
    notifyListeners();
  }

  void discardChanges(int index) {
    if (index < 0 || index >= fetchedArticles.length) return;
    final article = fetchedArticles[index];
    article['controller'].text = article['title'] ?? '';

    final sources = article['sources'] as List<String>;
    final oldSourcesControllers =
        article['sourcesControllers'] as List<TextEditingController>;
    for (final c in oldSourcesControllers) {
      c.dispose();
    }
    article['sourcesControllers'] = sources
        .map((s) => TextEditingController(text: s))
        .toList();

    final paragraphs = article['paragraphs'] as List<String>;

    final oldControllers =
        article['paragraphControllers'] as List<TextEditingController>;
    for (final c in oldControllers) {
      c.dispose();
    }

    article['paragraphControllers'] = paragraphs
        .map((p) => TextEditingController(text: p))
        .toList();
    notifyListeners();
  }

  void selectArticle(int index) {
    selectedArticleIndex = index;
    notifyListeners();
  }

  void toggleReordering() {
    isReordering = !isReordering;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final article in fetchedArticles) {
      disposeArticle(article);
    }
    super.dispose();
  }
}
