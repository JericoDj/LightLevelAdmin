import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/ebooks_model.dart';
import '../../../repository/ebooks_repository.dart';


void showMindHubEbooksDialog(BuildContext context, List<Ebook> ebooks) {
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
                  // **Header with Close Icon**
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MindHub Ebooks',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 20),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // **Ebook List with Drag & Drop Support**
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ebooks.isEmpty
                          ? Center(child: Text("No ebooks added yet.", style: TextStyle(color: Colors.grey)))
                          : ReorderableListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final item = ebooks.removeAt(oldIndex);
                            ebooks.insert(newIndex, item);
                          });
                        },
                        children: [
                          for (int index = 0; index < ebooks.length; index++)
                            Card(
                              key: ValueKey(ebooks[index]),
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              elevation: 2,
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Icon(Icons.drag_handle, color: Colors.blue),
                                title: Text(ebooks[index].title, maxLines: 1, overflow: TextOverflow.ellipsis),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      ebooks.removeAt(index);
                                    });
                                  },
                                ),
                                onTap: () {
                                  showEbookDialog(context, ebooks, ebooks[index]);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // **Footer Buttons (Add, Save, Close)**
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            showEbookDialog(context, ebooks, null);
                          },
                          icon: Icon(Icons.add, color: Colors.white),
                          label: Text("Add Ebook"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Save ebooks logic
                            print("Saving ebooks...");
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.save, color: Colors.white),
                          label: Text("Save Ebooks"),
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

/// **Dialog to Add or Edit an Ebook**
void showEbookDialog(BuildContext context, List<Ebook> ebooks, Ebook? ebookToEdit) {
  final EbookRepository ebookRepo = EbookRepository();
  final TextEditingController titleController = TextEditingController(text: ebookToEdit?.title);
  final TextEditingController descriptionController = TextEditingController(text: ebookToEdit?.description);
  String? coverUrl;
  String? ebookFileUrl;

  File? pickedCover;
  File? pickedEbook;

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.5,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(ebookToEdit == null ? "Add New Ebook" : "Edit Ebook", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),

              const SizedBox(height: 16),

              // **Cover Picker**
              GestureDetector(
                onTap: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    pickedCover = File(image.path);
                    coverUrl = await ebookRepo.uploadCover(pickedCover!);
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                  ),
                  child: pickedCover == null
                      ? Center(child: Text("Click to upload cover image"))
                      : Image.file(pickedCover!, fit: BoxFit.cover),
                ),
              ),

              const SizedBox(height: 16),

              // **Ebook File Picker**
              ElevatedButton.icon(
                onPressed: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? ebook = await picker.pickImage(source: ImageSource.gallery);
                  if (ebook != null) {
                    pickedEbook = File(ebook.path);
                    ebookFileUrl = await ebookRepo.uploadEbook(pickedEbook!);
                  }
                },
                icon: Icon(Icons.upload_file),
                label: Text("Upload Ebook"),
              ),

              const SizedBox(height: 16),

              // **Footer Buttons**
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.cancel, color: Colors.white),
                    label: Text("Cancel"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final newEbook = Ebook(
                        title: titleController.text,
                        description: descriptionController.text,
                        cover: coverUrl ?? '',
                        ebookFile: ebookFileUrl ?? '', id: '',
                      );

                      if (ebookToEdit == null) {
                        ebooks.add(newEbook);
                      } else {
                        final index = ebooks.indexOf(ebookToEdit);
                        ebooks[index] = newEbook;
                      }

                      // Save ebook to Firestore
                      await ebookRepo.saveEbook(newEbook);

                      Navigator.pop(context);
                      showMindHubEbooksDialog(context, ebooks);
                    },
                    icon: Icon(Icons.save, color: Colors.white),
                    label: Text(ebookToEdit == null ? "Add" : "Save"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
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
}
