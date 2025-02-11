import 'dart:typed_data';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

final ValueNotifier<bool> imageUploading = ValueNotifier(false); // Track image upload state
final String userId = "sampleUserId"; // Replace with your actual user ID
final user = ValueNotifier<Map<String, dynamic>>({}); // Placeholder for user data

/// Upload Profile Picture to Firebase Storage
Future<void> uploadUserProfilePicture(BuildContext context) async {
  try {
    imageUploading.value = true;



    if (kIsWeb) {
      // Web-specific file picking
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        final imageUrl = await _uploadToFirebaseStorage(bytes, image.name);
        await _updateProfilePictureUrl(context, imageUrl);
      }
    } else {
      // Mobile file picking
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxHeight: 512,
        maxWidth: 512,
      );

      if (image != null) {
        final imageUrl = await _uploadToFirebaseStorage(File(image.path), null);
        await _updateProfilePictureUrl(context, imageUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile picture update cancelled.')),
        );
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error Uploading Image: $e')),
    );
  } finally {
    imageUploading.value = false;
    user.notifyListeners(); // Manually trigger UI refresh
  }
}

/// Upload Image to Firebase Storage
Future<String> _uploadToFirebaseStorage(dynamic imageData, String? fileName) async {
  try {
    final storageRef = FirebaseStorage.instance.ref().child('profile_pictures/${fileName ?? DateTime.now().millisecondsSinceEpoch}.jpg');

    UploadTask uploadTask;
    if (imageData is Uint8List) {
      uploadTask = storageRef.putData(imageData);
    } else if (imageData is File) {
      uploadTask = storageRef.putFile(imageData);
    } else {
      throw Exception("Invalid image data type");
    }

    final snapshot = await uploadTask.whenComplete(() => {});
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  } catch (e) {
    throw Exception("Error uploading image to Firebase: $e");
  }
}

/// Update the Profile Picture URL in Firestore
Future<void> _updateProfilePictureUrl(BuildContext context, String imageUrl) async {
  try {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    await userRef.update({'profile_picture': imageUrl});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile picture updated successfully!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error updating profile picture: $e')),
    );
  }
}
