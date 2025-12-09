class Ebook {
  String id;
  String title;
  String description;
  String cover;
  String ebookFile;

  Ebook({
    required this.id,
    required this.title,
    required this.description,
    required this.cover,
    required this.ebookFile,
  });

  /// Convert Ebook object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'cover': cover,
      'ebookFile': ebookFile,
    };
  }

  /// Create an Ebook object from Firestore data
  factory Ebook.fromMap(Map<String, dynamic> map, String documentId) {
    return Ebook(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      cover: map['cover'] ?? '',
      ebookFile: map['ebookFile'] ?? '',
    );
  }
}
