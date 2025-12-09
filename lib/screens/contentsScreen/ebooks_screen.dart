import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../../utils/colors.dart';

class Ebook {
  final String title;
  final String description;
  final String pdfUrl;
  final String coverUrl;

  Ebook({
    required this.title,
    required this.description,
    required this.pdfUrl,
    required this.coverUrl,
  });
}

class EbooksContentScreen extends StatefulWidget {
  const EbooksContentScreen({Key? key, required List<Ebook> ebooks}) : super(key: key);

  @override
  _EbooksContentScreenState createState() => _EbooksContentScreenState();
}

class _EbooksContentScreenState extends State<EbooksContentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<Map<String, dynamic>> _ebooks = [];

  @override
  void initState() {
    super.initState();
    _fetchEbooksFromFirestore();
  }

  Future<void> _fetchEbooksFromFirestore() async {
    try {
      DocumentSnapshot doc = await _firestore.collection('contents').doc('ebooks').get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> ebooks = [];

        data.forEach((key, value) {
          if (key.startsWith('ebook')) {
            ebooks.add({
              'title': value['title'] ?? '',
              'description': value['description'] ?? '',
              'pdfUrl': value['pdfUrl'] ?? '',
              'coverUrl': value['coverUrl'] ?? '',
              'titleController': TextEditingController(text: value['title']),
              'descriptionController': TextEditingController(text: value['description']),
              'pdfController': TextEditingController(text: value['pdfUrl']),
            });
          }
        });

        setState(() => _ebooks = ebooks);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching ebooks: ${e.toString()}')),
      );
    }
  }

  Future<void> _uploadFile(int index, String type) async {
    FileType fileType = type == 'pdf'
        ? FileType.custom
        : FileType.image;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: fileType,
      withData: true,
      allowedExtensions: type == 'pdf' ? ['pdf'] : null,
    );

    if (result != null && result.files.isNotEmpty) {
      try {
        final file = result.files.first;
        final bytes = file.bytes;
        final fileName = file.name;
        final storagePath = type == 'pdf'
            ? 'contents/ebooks/$fileName'
            : 'contents/covers/$fileName';

        final ref = _storage.ref(storagePath);
        await ref.putData(bytes!, SettableMetadata(
            contentType: type == 'pdf' ? 'application/pdf' : 'image/jpeg'
        ));
        final url = await ref.getDownloadURL();

        setState(() {
          if (type == 'pdf') {
            _ebooks[index]['pdfUrl'] = url;
            _ebooks[index]['pdfController'].text = url;
          } else {
            _ebooks[index]['coverUrl'] = url;
          }
        });

        await _updateFirestore();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading file: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _updateFirestore() async {
    try {
      final Map<String, dynamic> firestoreData = {};

      for (int i = 0; i < _ebooks.length; i++) {
        firestoreData['ebook${i + 1}'] = {
          'title': _ebooks[i]['titleController'].text,
          'description': _ebooks[i]['descriptionController'].text,
          'pdfUrl': _ebooks[i]['pdfController'].text,
          'coverUrl': _ebooks[i]['coverUrl'],
          'order': i,
        };
      }

      await _firestore.collection('contents').doc('ebooks').set(
        firestoreData,
        SetOptions(merge: false),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving ebooks: ${e.toString()}')),
      );
    }
  }

  void _addNewEbook() {
    setState(() {
      _ebooks.add({
        'title': 'New Ebook',
        'description': '',
        'pdfUrl': '',
        'coverUrl': '',
        'titleController': TextEditingController(text: 'New Ebook'),
        'descriptionController': TextEditingController(),
        'pdfController': TextEditingController(),
      });
    });
    _updateFirestore();
  }

  Future<void> _deleteEbook(int index) async {
    try {
      // Delete PDF file
      final pdfUrl = _ebooks[index]['pdfUrl'];
      if (pdfUrl.isNotEmpty) {
        await _storage.refFromURL(pdfUrl).delete();
      }

      // Delete cover image
      final coverUrl = _ebooks[index]['coverUrl'];
      if (coverUrl.isNotEmpty) {
        await _storage.refFromURL(coverUrl).delete();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting files: ${e.toString()}')),
      );
    }

    setState(() => _ebooks.removeAt(index));
    await _updateFirestore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
            alignment: AlignmentDirectional.centerStart,
            child: const Text('Manage eBooks')),
        backgroundColor: MyColors.color1,
        foregroundColor: MyColors.white,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 50.0), // Adjust right padding to move left
        child: FloatingActionButton(
          onPressed: _addNewEbook,
          backgroundColor: MyColors.color2,
          child: const Icon(Icons.add, color: MyColors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          itemCount: _ebooks.length,
          separatorBuilder: (_, __) => const Divider(height: 20),
          itemBuilder: (context, index) => _buildEbookCard(index),
        ),
      ),
    );
  }

  Widget _buildEbookCard(int index) {
    final ebook = _ebooks[index];
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCoverSection(ebook, index),
            const SizedBox(height: 12),
            _styledTextField(ebook['titleController'], 'Title'),
            const SizedBox(height: 8),
            _styledTextField(ebook['descriptionController'], 'Description'),
            const SizedBox(height: 8),
            _buildPdfSection(ebook, index),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _uploadFile(index, 'cover'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyColors.color2,
                    foregroundColor: MyColors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Upload Cover"),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteEbook(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _styledTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: MyColors.color1),
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: MyColors.color2, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: (_) => _updateFirestore(),
    );
  }




  Widget _buildCoverSection(Map<String, dynamic> ebook, int index) {
    return GestureDetector(
      onTap: () => _uploadFile(index, 'cover'),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: ebook['coverUrl']?.isNotEmpty == true
            ? ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(ebook['coverUrl'], fit: BoxFit.cover),
        )
            : const Center(
            child: Text("Tap to upload cover",
                style: TextStyle(color: Colors.grey))),
      ),
    );
  }

  Widget _buildPdfSection(Map<String, dynamic> ebook, int index) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: ebook['pdfController'],
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'PDF File',
              labelStyle: TextStyle(color: MyColors.color1),
              border: const OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: MyColors.color2, width: 2),
              ),
              suffixIcon: const Icon(Icons.insert_drive_file),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.upload, color: MyColors.color1),
          onPressed: () => _uploadFile(index, 'pdf'),
        ),
      ],
    );
  }
}