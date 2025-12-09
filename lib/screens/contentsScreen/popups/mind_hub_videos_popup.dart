import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/videos_models.dart';
import '../../../repository/upload_video_repository.dart';

void showMindHubVideosDialog(BuildContext context, List<Video> videos) {
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6, // 60% of screen width
              height: MediaQuery.of(context).size.height * 0.7, // 70% of screen height
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // **Header with Close Icon**
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MindHub Videos',
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

                  // **Video List with Drag & Drop Support**
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: videos.isEmpty
                          ? Center(child: Text("No videos added yet.", style: TextStyle(color: Colors.grey)))
                          : ReorderableListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final item = videos.removeAt(oldIndex);
                            videos.insert(newIndex, item);
                          });
                        },
                        children: [
                          for (int index = 0; index < videos.length; index++)
                            Card(
                              key: ValueKey(videos[index]),
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              elevation: 2,
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Icon(Icons.drag_handle, color: Colors.blue),
                                title: Text(videos[index].title, maxLines: 1, overflow: TextOverflow.ellipsis),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      videos.removeAt(index);
                                    });
                                  },
                                ),
                                onTap: () {
                                  showVideoDialog(context, videos, videos[index]);
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
                            showVideoDialog(context, videos, null);
                          },
                          icon: Icon(Icons.add, color: Colors.white),
                          label: Text("Add Video"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Save videos logic
                            print("Saving videos...");
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.save, color: Colors.white),
                          label: Text("Save Videos"),
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

/// **Dialog to Add or Edit a Video**
void showVideoDialog(BuildContext context, List<Video> videos, Video? videoToEdit) {
  final VideoRepository videoRepo = VideoRepository();
  final TextEditingController titleController = TextEditingController(text: videoToEdit?.title);
  final TextEditingController descriptionController = TextEditingController(text: videoToEdit?.description);
  String? thumbnailUrl;
  String? videoUrl;

  File? pickedThumbnail;
  File? pickedVideo;

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
              Text(videoToEdit == null ? "Add New Video" : "Edit Video", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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

              // **Thumbnail Picker**
              GestureDetector(
                onTap: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    pickedThumbnail = File(image.path);
                    thumbnailUrl = await videoRepo.uploadThumbnail(pickedThumbnail!);
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                  ),
                  child: pickedThumbnail == null
                      ? Center(child: Text("Click to upload thumbnail"))
                      : Image.file(pickedThumbnail!, fit: BoxFit.cover),
                ),
              ),

              const SizedBox(height: 16),

              // **Video Picker**
              ElevatedButton.icon(
                onPressed: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
                  if (video != null) {
                    pickedVideo = File(video.path);
                    videoUrl = await videoRepo.uploadVideo(pickedVideo!);
                  }
                },
                icon: Icon(Icons.video_library),
                label: Text("Pick Video"),
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
                      final newVideo = Video(
                        title: titleController.text,
                        description: descriptionController.text,
                        thumbnail: thumbnailUrl ?? '',
                        videoFile: videoUrl ?? '', url: '',
                      );

                      if (videoToEdit == null) {
                        videos.add(newVideo);
                      } else {
                        final index = videos.indexOf(videoToEdit);
                        videos[index] = newVideo;
                      }

                      // Save video to Firestore
                      await videoRepo.saveVideo(newVideo);

                      Navigator.pop(context);
                      showMindHubVideosDialog(context, videos);
                    },
                    icon: Icon(Icons.save, color: Colors.white),
                    label: Text(videoToEdit == null ? "Add" : "Save"),
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
