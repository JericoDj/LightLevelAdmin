import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/videos_models.dart';

import '../../../repository/upload_video_repository.dart';

void showVideoDialog(BuildContext context, List<Video> videos, Video? videoToEdit) async {
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
      return AlertDialog(
        title: Text(videoToEdit == null ? "Add New Video" : "Edit Video"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),

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
            onPressed: () async {
              final newVideo = Video(
                title: titleController.text,
                description: descriptionController.text,
                thumbnail: thumbnailUrl ?? '',
                videoFile: videoUrl ?? '',
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
            child: Text(videoToEdit == null ? "Add" : "Save"),
          ),
        ],
      );
    },
  );
}



void showMindHubVideosDialog(BuildContext context, List<Video> videos) async {
  final VideoRepository videoRepo = VideoRepository();
  videos = await videoRepo.fetchVideos(); // Fetch videos from Firestore

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
                  // Header
                  Text('MindHub Videos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 20)),
                  const SizedBox(height: 16),

                  Expanded(
                    child: videos.isEmpty ? Center(child: Text("No videos added yet.")) : ListView.builder(
                      itemCount: videos.length,
                      itemBuilder: (context, index) => ListTile(title: Text(videos[index].title)),
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
