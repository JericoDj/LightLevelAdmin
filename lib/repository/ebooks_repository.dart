import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/ebooks_model.dart';

class EbookRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload cover image to Firebase Storage
  Future<String> uploadCover(File coverImage) async {
    try {
      final ref = _storage.ref().child('ebooks/covers/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(coverImage);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Error uploading cover image: $e');
    }
  }

  /// Upload ebook file to Firebase Storage
  Future<String> uploadEbook(File ebookFile) async {
    try {
      final ref = _storage.ref().child('ebooks/files/${DateTime.now().millisecondsSinceEpoch}.pdf');
      await ref.putFile(ebookFile);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Error uploading ebook file: $e');
    }
  }

  /// Save Ebook Data to Firestore
  Future<void> saveEbook(Ebook ebook) async {
    try {
      final docRef = _firestore.collection('ebooks').doc(ebook.id.isEmpty ? null : ebook.id);
      await docRef.set(ebook.toMap());
    } catch (e) {
      throw Exception('Error saving ebook: $e');
    }
  }

  /// Fetch all ebooks from Firestore
  Future<List<Ebook>> fetchEbooks() async {
    try {
      final querySnapshot = await _firestore.collection('ebooks').get();
      return querySnapshot.docs.map((doc) => Ebook.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Error fetching ebooks: $e');
    }
  }

  /// Delete an ebook from Firestore & Firebase Storage
  Future<void> deleteEbook(Ebook ebook) async {
    try {
      await _firestore.collection('ebooks').doc(ebook.id).delete();

      // Delete cover
      if (ebook.cover.isNotEmpty) {
        final coverRef = _storage.refFromURL(ebook.cover);
        await coverRef.delete();
      }

      // Delete file
      if (ebook.ebookFile.isNotEmpty) {
        final fileRef = _storage.refFromURL(ebook.ebookFile);
        await fileRef.delete();
      }
    } catch (e) {
      throw Exception('Error deleting ebook: $e');
    }
  }
}
