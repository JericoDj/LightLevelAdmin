import 'dart:typed_data'; // ✅ Correct import for Uint8List
import 'dart:io'; // File handling for mobile
import 'dart:html' as html; // Web file handling

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/articles_model.dart';
import '../../screens/contentsScreen/popups/mind_hub_articles_popup.dart';



Future<void> showArticleDialog(BuildContext context, List<Article> articles, Article? articleToEdit) async {
  final TextEditingController titleController = TextEditingController(text: articleToEdit?.title);
  List<TextEditingController> paragraphControllers = [];
  if (articleToEdit != null) {
    paragraphControllers = articleToEdit.paragraphs
        .map((paragraph) => TextEditingController(text: paragraph))
        .toList();
  }
  final TextEditingController sourcesController = TextEditingController(text: articleToEdit?.sources);
  final TextEditingController thumbnailController = TextEditingController(text: articleToEdit?.thumbnail);

  File? pickedImage;
  Uint8List? webImageBytes;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(articleToEdit == null ? "Add New Article" : "Edit Article"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            // Display multiple paragraph fields
            ...paragraphControllers.map((controller) {
              return TextField(
                controller: controller,
                decoration: InputDecoration(labelText: 'Paragraph'),
              );
            }).toList(),
            TextField(
              controller: sourcesController,
              decoration: InputDecoration(labelText: 'Sources'),
            ),

            // **Image Picker for both Web & Mobile**
            GestureDetector(
              onTap: () async {
                try {
                  if (kIsWeb) {
                    // **Web-specific file picking**
                    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
                    uploadInput.accept = 'image/*';
                    uploadInput.click();

                    uploadInput.onChange.listen((event) async {
                      final html.File? file = uploadInput.files?.first;
                      if (file != null) {
                        final reader = html.FileReader();
                        reader.readAsArrayBuffer(file);

                        reader.onLoadEnd.listen((event) async {
                          webImageBytes = reader.result as Uint8List?;
                          if (webImageBytes != null) {
                            final imageUrl = await _uploadToFirebaseStorage(webImageBytes!, file.name);
                            thumbnailController.text = imageUrl;
                          }
                        });
                      }
                    });
                  } else {
                    // **Mobile Image Picker**
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 70,
                      maxHeight: 512,
                      maxWidth: 512,
                    );

                    if (image != null) {
                      pickedImage = File(image.path);
                      final imageUrl = await _uploadToFirebaseStorage(pickedImage!);
                      thumbnailController.text = imageUrl;
                    }
                  }
                } catch (e) {
                  print("Error picking file: $e");
                }
              },
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                ),
                child: pickedImage == null && webImageBytes == null
                    ? Center(child: Text("Click to upload image"))
                    : kIsWeb
                    ? Image.memory(webImageBytes!, fit: BoxFit.cover)
                    : Image.file(pickedImage!, fit: BoxFit.cover),
              ),
            ),

            SizedBox(height: 16),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              // Convert the text from the TextEditingController list into a list of paragraphs
              final List<String> paragraphs = paragraphControllers.map((controller) => controller.text).toList();

              final newArticle = Article(
                title: titleController.text,
                paragraphs: paragraphs, // Pass the list of paragraphs
                sources: sourcesController.text,
                thumbnail: thumbnailController.text,
              );

              if (articleToEdit == null) {
                articles.add(newArticle);
              } else {
                final index = articles.indexOf(articleToEdit);
                articles[index] = newArticle;
              }

              Navigator.pop(context);
              Navigator.pop(context);
              showMindHubArticlesDialog(context, articles);
            },
            child: Text(articleToEdit == null ? "Add" : "Save"),
          ),

        ],
      );
    },
  );
}



/// Upload Image to Firebase Storage
Future<String> _uploadToFirebaseStorage(dynamic imageFile, [String? fileName]) async {
  try {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) throw Exception("User ID is not available");

    final storagePath = 'Users/Images/Profile/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref(storagePath);

    if (kIsWeb && imageFile is Uint8List) {
      await ref.putData(imageFile);
    } else if (imageFile is File) {
      await ref.putFile(imageFile);
    }

    return await ref.getDownloadURL();
  } catch (e) {
    throw Exception('Error uploading to Firebase: $e');
  }
}
