class Video {
  String title;
  String description;
  String thumbnail;
  String videoFile; // Local path or temp file path
  String url;       // Download URL from Firebase

  Video({
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.videoFile,
    required this.url,
  });
}
