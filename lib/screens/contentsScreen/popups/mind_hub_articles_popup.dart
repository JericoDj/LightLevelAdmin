import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../controllers/mindhub_controllers/articles_upload_controller.dart';
import '../../../models/articles_model.dart';

void showMindHubArticlesDialog(BuildContext context, List<Article> articles) {
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              width: MediaQuery.of(context).size.width *
                  0.6, // 60% of screen width
              height: MediaQuery.of(context).size.height *
                  0.7, // 70% of screen height
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // **Header with Close Icon**
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MindHub Articles',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          fontSize: MediaQuery.of(context).size.width * 0.012,),
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

                  // **Article List with Drag & Drop Support**
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: articles.isEmpty
                          ? Center(
                              child: Text("No articles added yet.",
                                  style: TextStyle(color: Colors.grey)))
                          : ReorderableListView(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  if (newIndex > oldIndex) {
                                    newIndex -= 1;
                                  }
                                  final item = articles.removeAt(oldIndex);
                                  articles.insert(newIndex, item);
                                });
                              },
                              children: [
                                for (int index = 0;
                                    index < articles.length;
                                    index++)
                                  Card(
                                    key: ValueKey(articles[index]),
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    elevation: 2,
                                    child: ListTile(
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      leading: Icon(Icons.drag_handle,
                                          color: Colors.blue),
                                      title: Text(articles[index].title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            articles.removeAt(index);
                                          });
                                        },
                                      ),
                                      onTap: () {
                                        showArticleDialog(
                                            context, articles, articles[index]);
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
                            showArticleDialog(context, articles, null);
                          },
                          icon: Icon(Icons.add, color: Colors.white),
                          label: Text("Add Article"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Save articles logic
                            print("Saving articles...");
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.save, color: Colors.white),
                          label: Text("Save Articles"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
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
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
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
