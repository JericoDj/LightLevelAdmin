import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/videos_models.dart';


class VideoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// **Upload Video to Firebase Storage**
  Future<String> uploadVideo(File videoFile) async {
    try {
      String filePath = 'videos/${DateTime.now().millisecondsSinceEpoch}.mp4';
      Reference ref = _storage.ref().child(filePath);
      UploadTask uploadTask = ref.putFile(videoFile);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception("Error uploading video: $e");
    }
  }

  /// **Upload Thumbnail to Firebase Storage**
  Future<String> uploadThumbnail(File thumbnailFile) async {
    try {
      String filePath = 'thumbnails/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child(filePath);
      UploadTask uploadTask = ref.putFile(thumbnailFile);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception("Error uploading thumbnail: $e");
    }
  }

  /// **Save Video Metadata to Firestore**
  Future<void> saveVideo(Video video) async {
    try {
      await _firestore.collection('videos').add({
        'title': video.title,
        'description': video.description,
        'thumbnail': video.thumbnail,
        'videoFile': video.videoFile,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Error saving video metadata: $e");
    }
  }

  /// **Retrieve Videos from Firestore**
  Future<List<Video>> fetchVideos() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('videos').orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) => Video(
        title: doc['title'],
        description: doc['description'],
        thumbnail: doc['thumbnail'],
        videoFile: doc['videoFile'], url: '',
      )).toList();
    } catch (e) {
      throw Exception("Error fetching videos: $e");
    }
  }

  /// **Delete Video from Firestore & Firebase Storage**
  Future<void> deleteVideo(Video video) async {
    try {
      // Delete Firestore record
      QuerySnapshot snapshot = await _firestore
          .collection('videos')
          .where('videoFile', isEqualTo: video.videoFile)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.delete();
      }

      // Delete from Firebase Storage
      await _storage.refFromURL(video.videoFile).delete();
      await _storage.refFromURL(video.thumbnail).delete();
    } catch (e) {
      throw Exception("Error deleting video: $e");
    }
  }
}
