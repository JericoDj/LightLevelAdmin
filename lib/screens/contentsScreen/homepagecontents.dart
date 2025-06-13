import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';

import '../../utils/colors.dart';

class HomePageContentScreen extends StatefulWidget {
  @override
  _HomePageContentScreenState createState() => _HomePageContentScreenState();
}

class _HomePageContentScreenState extends State<HomePageContentScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  List<Map<String, dynamic>> fetchedImages = [];
  bool isReordering = false;

  @override
  void initState() {
    super.initState();
    _fetchFromFirestore();
  }

  Future<void> _pickImageAndAdd() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      final imageBytes = result.files.single.bytes;
      final fileName = result.files.single.name;

      final ref = storage.ref('contents/homescreen/$fileName');
      await ref.putData(
          imageBytes!, SettableMetadata(contentType: 'image/png'));
      final url = await ref.getDownloadURL();

      final newEntry = {
        'url': url,
        'title': fileName,
        'controller': TextEditingController(text: fileName),
        'order': fetchedImages.length,
      };

      setState(() {
        fetchedImages.add(newEntry);
      });

      await _updateFirestoreOrderAndTitles();
    }
  }

  Future<void> _fetchFromFirestore() async {
    final doc = await firestore.collection('contents').doc('homescreen').get();

    if (doc.exists) {
      final data = doc.data();
      final imageList = <Map<String, dynamic>>[];

      data?.forEach((key, value) {
        if (value is Map && value.containsKey('url')) {
          imageList.add({
            'url': value['url'],
            'title': value['title'] ?? key,
            'controller': TextEditingController(text: value['title'] ?? key),
            'order': value['order'] ?? 0,
          });
        }
      });

      imageList.sort((a, b) =>
          (a['order'] as int).compareTo(b['order'] as int));

      setState(() {
        fetchedImages = imageList;
      });
    }
  }

  Future<void> _updateFirestoreOrderAndTitles() async {
    final updates = <String, dynamic>{};
    for (int i = 0; i < fetchedImages.length; i++) {
      updates['image${i + 1}'] = {
        'url': fetchedImages[i]['url'],
        'title': fetchedImages[i]['controller'].text,
        'order': i,
      };
    }

    await firestore.collection('contents').doc('homescreen').set(updates);
  }

  void _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final movedItem = fetchedImages.removeAt(oldIndex);
    fetchedImages.insert(newIndex, movedItem);

    for (int i = 0; i < fetchedImages.length; i++) {
      fetchedImages[i]['order'] = i;
    }

    await _updateFirestoreOrderAndTitles();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50), // <-- set your desired height here
        child: AppBar(
          title: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: const Text(
                'Homepage Image Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24  ,
                ),
              ),
            ),
          ),
          backgroundColor: Colors.green[800],
          elevation: 0,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Divider(height: 20),
           Container(
             height: 250,
              child: fetchedImages.isEmpty
                  ? Center(child: Column(
                    children: [
                      _buildAddNewImageCard(key: const ValueKey('add_new_card')),
                    ],
                  ))
                  : isReordering

                  /// Arranging
                  ? Container(
                    height: 200,
                    child: ReorderableListView(
                                    scrollDirection: Axis.horizontal,
                                    onReorder: _onReorder,
                                    children: [
                    ...fetchedImages.map((img) {
                      return Container(
                        key: ValueKey(img['url']),
                        width: 200,
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    img['url'],
                                    height: 160,
                                    width: 200,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                // Drag icon positioned top-right
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Icon(Icons.drag_handle, color: Colors.grey[600], size: 20),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: img['controller'],
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
                    _buildAddNewImageCard(key: const ValueKey('add_new_card'))
                    // ✅ Fixed with key
                                    ],
                                  ),
                  )
                  ///image not arranging
                  : ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...fetchedImages.map((img) {
                    return Container(
                      height: 100,
                      width:200,
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                img['url'],
                                height: 113,
                                width: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          TextField(
                            controller: img['controller'],
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
                  _buildAddNewImageCard()
                ],
              ),
            ),
            SizedBox(height: 20,),
            GestureDetector(
              onTap: () {
                setState(() {
                  isReordering = !isReordering;
                });
              },
              child: Container(
                height: 40,
                width: 200,
                margin: EdgeInsets.only(right: 12),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 6),
                    Text(
                      isReordering ? 'Done' : 'Rearrange',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )

          ],
        ),
      ),
    );
  }

  Widget _buildAddNewImageCard({Key? key}) {
    return Container(
      key: key, // 🔑 This fixes the ReorderableListView assertion
      height: 225,
      width: 400,
      margin: EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: _pickImageAndAdd,
        child: DottedBorder(
          color: MyColors.color2,
          strokeWidth: 2,
          dashPattern: [6, 4],
          borderType: BorderType.RRect,
          radius: Radius.circular(12),
          child: Center(
            child: Column(

              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add, size: 40, color: MyColors.color2),
                SizedBox(height: 8),
                Text('Add New Image', style: TextStyle(color: MyColors.color2)),
              ],
            ),
          ),
        ),
      ),
    );
  }

}