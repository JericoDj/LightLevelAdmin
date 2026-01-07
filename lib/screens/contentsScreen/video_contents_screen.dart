import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../../models/videos_models.dart';
import '../../utils/colors.dart';

class VideosContentScreen extends StatefulWidget {
  final List<Video> videos;

  const VideosContentScreen({Key? key, required this.videos}) : super(key: key);

  @override
  _VideosContentScreenState createState() => _VideosContentScreenState();
}

class _VideosContentScreenState extends State<VideosContentScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  late List<Map<String, dynamic>> fetchedVideos;

  @override
  void initState() {
    super.initState();
    _fetchVideosFromFirestore();
  }

  Future<void> _pickThumbnail(int index) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      try {
        final file = result.files.first;
        final imageBytes = file.bytes;
        final fileName = file.name;

        final ref = storage.ref('contents/thumbnails/$fileName');
        await ref.putData(imageBytes!, SettableMetadata(contentType: 'image/jpeg'));
        final url = await ref.getDownloadURL();

        setState(() {
          fetchedVideos[index]['thumbnail'] = url;
        });

        await _updateFirestoreVideos();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading thumbnail: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _fetchVideosFromFirestore() async {
    try {
      DocumentSnapshot doc = await firestore.collection('contents').doc('videos').get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> videos = [];
        data.forEach((key, value) {
          if (key.startsWith('video')) {
            videos.add({
              'title': value['title'] ?? '',
              'description': value['description'] ?? '',
              'thumbnail': value['thumbnail'] ?? '',
              'videoUrl': value['videoUrl'] ?? '',
              'controller': TextEditingController(text: value['title']),
              'descriptionController': TextEditingController(text: value['description']),
              'urlController': TextEditingController(text: value['videoUrl']),
            });
          }
        });
        // Sort videos by 'order' if needed, or maintain the order from Firestore
        setState(() => fetchedVideos = videos);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching videos: ${e.toString()}')),
      );
    }
  }

  void _initializeVideos() {
    fetchedVideos = widget.videos.map((video) => _createVideoMap(video)).toList();
  }

  Map<String, dynamic> _createVideoMap(Video video) {
    return {
      'title': video.title,
      'description': video.description,
      'thumbnail': video.thumbnail,
      'videoUrl': video.url,
      'controller': TextEditingController(text: video.title),
      'descriptionController': TextEditingController(text: video.description),
      'urlController': TextEditingController(text: video.url),
    };
  }

  Future<void> _pickVideoAndReplace(int index) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      try {
        final file = result.files.first;
        final videoBytes = file.bytes;
        final fileName = file.name;

        final ref = storage.ref('contents/videos/$fileName');
        await ref.putData(videoBytes!, SettableMetadata(contentType: 'video/mp4'));
        final url = await ref.getDownloadURL();

        setState(() {
          fetchedVideos[index]['videoUrl'] = url;
          fetchedVideos[index]['urlController'].text = url;
        });

        await _updateFirestoreVideos();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading video: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _updateFirestoreVideos() async {
    try {
      final Map<String, dynamic> firestoreData = {};

      for (int i = 0; i < fetchedVideos.length; i++) {
        firestoreData['video${i + 1}'] = _toFirestoreVideo(fetchedVideos[i], i);
      }

      await firestore.collection('contents').doc('videos').set(
        firestoreData,
        SetOptions(merge: false), // Overwrite entire document
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving videos: ${e.toString()}')),
      );
    }
  }

  Map<String, dynamic> _toFirestoreVideo(Map<String, dynamic> video, int index) {
    return <String, dynamic>{
      'title': video['controller'].text,
      'description': video['descriptionController'].text,
      'videoUrl': video['urlController'].text,
      'thumbnail': video['thumbnail'] ?? '',
      'order': index,
    };
  }

  void _addNewVideo() {
    setState(() {
      fetchedVideos.add({
        'title': 'New Video',
        'description': '',
        'thumbnail': '',
        'videoUrl': '',
        'controller': TextEditingController(text: 'New Video'),
        'descriptionController': TextEditingController(),
        'urlController': TextEditingController(),
      });
    });
    _updateFirestoreVideos();
  }

  Future<void> _deleteVideo(int index) async {
    try {
      // Delete video file
      final videoUrl = fetchedVideos[index]['videoUrl'];
      if (videoUrl.isNotEmpty && videoUrl.contains("firebase")) {
        await storage.refFromURL(videoUrl).delete();
      }

      // Delete thumbnail file
      final thumbnailUrl = fetchedVideos[index]['thumbnail'];
      if (thumbnailUrl.isNotEmpty && thumbnailUrl.contains("firebase")) {
        await storage.refFromURL(thumbnailUrl).delete();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting files: ${e.toString()}')),
      );
    }

    setState(() => fetchedVideos.removeAt(index));
    await _updateFirestoreVideos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.012,
                ),
                'Manage Videos')),
        backgroundColor: MyColors.color1  ,
        foregroundColor: MyColors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewVideo,
        backgroundColor: MyColors.color2,
        child: const Icon(Icons.add, color: MyColors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Adjust for more columns
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.4, // Adjust to fit your card height
          ),
          itemCount: fetchedVideos.length,
          itemBuilder: (context, index) {
            final video = fetchedVideos[index];
            return _buildVideoCard(video, index);
          },
        ),
      ),

    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video, int index) {
    return Container(
      height: MediaQuery.of(context).size.width * 0.5,
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThumbnail(video, index),
              const SizedBox(height: 12),
              _buildTitleField(video),
              const SizedBox(height: 8),
              _buildDescriptionField(video),
              const SizedBox(height: 8),
              _buildUrlField(video),
              const SizedBox(height: 12),
              _buildActionButtons(index),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(Map<String, dynamic> video, int index) {
    return GestureDetector(
      onTap: () => _pickThumbnail(index),
      child: Stack(
        children: [
          Container(
            height:  MediaQuery.of(context).size.width * 0.12  ,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: (video['thumbnail']?.toString().isNotEmpty ?? false)
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                  height:  MediaQuery.of(context).size.width * 0.04  ,
                  video['thumbnail'], fit: BoxFit.cover),
            )
                : const Center(child: Text("Tap to upload thumbnail", style: TextStyle(color: Colors.grey))),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: IconButton(
              icon: Icon(Icons.upload, color: Colors.black87),
              onPressed: () => _pickThumbnail(index),
            ),
          ),
        ],
      ),
    );
  }




  Widget _buildTitleField(Map<String, dynamic> video) {
    return Container(
      height: MediaQuery.of(context).size.width * 0.025,
      child: TextField(
        controller: video['controller'],
        decoration: const InputDecoration(
          labelText: 'Title',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onChanged: (_) => _updateFirestoreVideos(),
      ),
    );
  }

  Widget _buildDescriptionField(Map<String, dynamic> video) {
    return Container(
      height: MediaQuery.of(context).size.width * 0.025,
      child: TextField(
        controller: video['descriptionController'],
        decoration: const InputDecoration(
          labelText: 'Description',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onChanged: (_) => _updateFirestoreVideos(),
      ),
    );
  }

  Widget _buildUrlField(Map<String, dynamic> video) {
    return Container(
      height: MediaQuery.of(context).size.width * 0.025,
      child: TextField(
        controller: video['urlController'],
        decoration: const InputDecoration(
          labelText: 'Video URL',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onChanged: (_) => _updateFirestoreVideos(),
      ),
    );
  }

  Widget _buildActionButtons(int index) {
    return Container(
      height: MediaQuery.of(context).size.width * 0.020,
      child: Row(
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.upload_file, size: 20, color: MyColors.white),
            label: const Text("Upload Video"),
            onPressed: () => _pickVideoAndReplace(index),
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColors.color2,
              foregroundColor: MyColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteVideo(index),
          ),
        ],
      ),
    );
  }
}