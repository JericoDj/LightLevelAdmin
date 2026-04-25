import 'dart:typed_data'; // ✅ Correct import for Uint8List
import 'dart:io'; // File handling for mobile
import 'dart:html' as html; // Web file handling

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../models/articles_model.dart';
import '../../screens/contentsScreen/popups/mind_hub_articles_popup.dart';
import '../../utils/colors.dart';
import '../../utils/rich_text_controller.dart';

const List<Color> _textColors = [
  Colors.black,
  Colors.red,
  Colors.blue,
  Colors.green,
  Colors.orange,
  Colors.purple,
  Colors.pink,
  Color(0xFFfd9c33), // Brand Orange
];

void _formatText(TextEditingController controller, String tag, {String? value}) {
  final selection = controller.selection;
  final text = controller.text;

  if (selection.start == -1) return;

  final String openTag = value != null ? '<$tag=$value>' : '<$tag>';
  final String closeTag = '</${tag.split('=').first}>';

  // Special Handling for Color: Prevent nesting by removing existing color tags in selection
  if (tag == 'color') {
    final selectedPart = selection.textInside(text);
    // Remove existing color tags from selected text
    final cleanSelected = selectedPart.replaceAll(RegExp(r'<color=#.*?>|</color>'), '');
    
    final newText = text.replaceRange(selection.start, selection.end, '$openTag$cleanSelected$closeTag');
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection(
        baseOffset: selection.start,
        extentOffset: selection.start + openTag.length + cleanSelected.length + closeTag.length,
      ),
    );
    return;
  }

  // Toggle Detection: Check if already wrapped
  if (selection.start >= openTag.length &&
      selection.end <= text.length - closeTag.length) {
    String prefix =
        text.substring(selection.start - openTag.length, selection.start);
    String suffix = text.substring(selection.end, selection.end + closeTag.length);

    if (prefix == openTag && suffix == closeTag) {
      final newText =
          text.replaceRange(selection.end, selection.end + closeTag.length, '');
      final finalText = newText.replaceRange(
          selection.start - openTag.length, selection.start, '');
      controller.value = controller.value.copyWith(
        text: finalText,
        selection: TextSelection(
          baseOffset: selection.start - openTag.length,
          extentOffset: selection.end - openTag.length,
        ),
      );
      return;
    }
  }

  // Toggle Detection: Check if selection contains tags
  if (selection.start < selection.end) {
    String selectedPart = text.substring(selection.start, selection.end);
    if (selectedPart.startsWith(openTag) && selectedPart.endsWith(closeTag)) {
      final innerText = selectedPart.substring(
          openTag.length, selectedPart.length - closeTag.length);
      final finalText =
          text.replaceRange(selection.start, selection.end, innerText);
      controller.value = controller.value.copyWith(
        text: finalText,
        selection: TextSelection(
          baseOffset: selection.start,
          extentOffset: selection.start + innerText.length,
        ),
      );
      return;
    }
  }

  if (selection.start == selection.end) {
    final newText =
        text.replaceRange(selection.start, selection.end, '$openTag$closeTag');
    controller.value = controller.value.copyWith(
      text: newText,
      selection:
          TextSelection.collapsed(offset: selection.start + openTag.length),
    );
  } else {
    final selectedText = selection.textInside(text);
    final newText = text.replaceRange(
        selection.start, selection.end, '$openTag$selectedText$closeTag');
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection(
        baseOffset: selection.start,
        extentOffset: selection.start +
            openTag.length +
            selectedText.length +
            closeTag.length,
      ),
    );
  }
}

void _clearFormatting(TextEditingController controller) {
  final selection = controller.selection;
  final text = controller.text;
  if (selection.start == -1) return;

  if (selection.start == selection.end) {
    // If no selection, try to find tags surrounding the cursor and remove them
    // For now, just a simple string-wide replacement if they want to clear ALL
    return; 
  }

  final selectedPart = selection.textInside(text);
  final cleanText = selectedPart.replaceAll(RegExp(r'<[^>]+>'), '');
  
  final newText = text.replaceRange(selection.start, selection.end, cleanText);
  controller.value = controller.value.copyWith(
    text: newText,
    selection: TextSelection(
      baseOffset: selection.start,
      extentOffset: selection.start + cleanText.length,
    ),
  );
}

void _pickColor(BuildContext context, TextEditingController controller) {
  Color currentColor = Colors.blue;
  final TextEditingController hexController = TextEditingController(
      text: '#${currentColor.value.toRadixString(16).substring(2).toUpperCase()}');

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setStateDialog) {
        return AlertDialog(
          title: const Text('Pick Text Color'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ColorPicker(
                  pickerColor: currentColor,
                  onColorChanged: (color) {
                    setStateDialog(() {
                      currentColor = color;
                      hexController.text =
                          '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
                    });
                  },
                  colorPickerWidth: 300,
                  pickerAreaHeightPercent: 0.7,
                  enableAlpha: false,
                  displayThumbColor: true,
                  paletteType: PaletteType.hsvWithHue,
                  labelTypes: const [], // Hide default labels to use our custom one
                  pickerAreaBorderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2),
                    topRight: Radius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: hexController,
                  decoration: const InputDecoration(
                    labelText: 'Manual Hex Value',
                    prefixText: '#',
                    border: OutlineInputBorder(),
                    hintText: 'RRGGBB',
                  ),
                  onChanged: (val) {
                    if (val.length == 6) {
                      try {
                        final color =
                            Color(int.parse('0xFF${val.toUpperCase()}'));
                        setStateDialog(() {
                          currentColor = color;
                        });
                      } catch (_) {}
                    }
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.color2,
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply'),
              onPressed: () {
                final hex =
                    '#${currentColor.value.toRadixString(16).substring(2).toUpperCase()}';
                _formatText(controller, 'color', value: hex);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ),
  );
}

Widget _buildFormattingToolbar(BuildContext context, TextEditingController controller) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: const Icon(Icons.format_bold, size: 18),
        onPressed: () => _formatText(controller, 'b'),
        tooltip: 'Bold',
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(8),
      ),
      IconButton(
        icon: const Icon(Icons.format_italic, size: 18),
        onPressed: () => _formatText(controller, 'i'),
        tooltip: 'Italic',
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(8),
      ),
      IconButton(
        icon: const Icon(Icons.format_underlined, size: 18),
        onPressed: () => _formatText(controller, 'u'),
        tooltip: 'Underline',
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(8),
      ),
      IconButton(
        icon: const Icon(Icons.palette_outlined, size: 18),
        onPressed: () => _pickColor(context, controller),
        tooltip: 'Text Color',
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(8),
      ),
      IconButton(
        icon: const Icon(Icons.format_clear, size: 18),
        onPressed: () => _clearFormatting(controller),
        tooltip: 'Clear Formatting',
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(8),
      ),
    ],
  );
}

Future<void> showArticleDialog(BuildContext context, List<Article> articles,
    Article? articleToEdit) async {
  final MindHubRichTextController titleController =
      MindHubRichTextController()..text = articleToEdit?.title ?? '';
  List<MindHubRichTextController> paragraphControllers = [];
  if (articleToEdit != null) {
    paragraphControllers = articleToEdit.paragraphs
        .map((paragraph) => MindHubRichTextController()..text = paragraph)
        .toList();
  }
  final MindHubRichTextController sourcesController =
      MindHubRichTextController()..text = articleToEdit?.sources ?? '';
  final MindHubRichTextController thumbnailController =
      MindHubRichTextController()..text = articleToEdit?.thumbnail ?? '';

  File? pickedImage;
  Uint8List? webImageBytes;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
          title:
              Text(articleToEdit == null ? "Add New Article" : "Edit Article"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Highlight text to apply Bold, Italic, or Underline.',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormattingToolbar(context, titleController),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Display multiple paragraph fields
                ...paragraphControllers.map((controller) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormattingToolbar(context, controller),
                      TextField(
                        controller: controller,
                        decoration:
                            const InputDecoration(labelText: 'Paragraph'),
                        maxLines: null,
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                }),
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
                        final html.FileUploadInputElement uploadInput =
                            html.FileUploadInputElement();
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
                                final imageUrl = await _uploadToFirebaseStorage(
                                    webImageBytes!, file.name);
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
                          final imageUrl =
                              await _uploadToFirebaseStorage(pickedImage!);
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
                  final List<String> paragraphs = paragraphControllers
                      .map((controller) => controller.text)
                      .toList();

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
Future<String> _uploadToFirebaseStorage(dynamic imageFile,
    [String? fileName]) async {
  try {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) throw Exception("User ID is not available");

    final storagePath =
        'Users/Images/Profile/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
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
