import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationController extends GetxController {
  static const String _cloudFunctionUrl = 'https://sendadminnotification-zesi6puwbq-uc.a.run.app'; // Your deployed HTTPS function

  @override
  void onInit() {
    super.onInit();
    print("🔄 NotificationController initialized");
  }

  /// ✅ Fetch all FCM tokens from Firestore
  Future<List<String>> getAllFcmTokens() async {
    print("📡 Fetching all FCM tokens from Firestore...");
    List<String> tokens = [];
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final token = data?['fcmToken'];

        if (token != null && token is String && token.isNotEmpty) {
          tokens.add(token);
          print("✅ Token for user ${doc.id}: $token");
        } else {
          print("⚠️ No valid token for user ${doc.id}, skipping...");
        }
      }

      print("🔢 Total tokens found: ${tokens.length}");
    } catch (e) {
      print("❌ Error fetching FCM tokens: $e");
    }
    return tokens;
  }

  /// ✅ Send notification to a single device using Firebase Function
  Future<void> sendNotificationToToken(String fcmToken, String title, String body) async {
    print("📨 Sending notification to token: $fcmToken");

    try {
      final response = await http.post(
        Uri.parse(_cloudFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': fcmToken,
          'title': title,
          'body': body,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Notification sent to $fcmToken");
      } else {
        print("❌ Failed to send notification to $fcmToken");
        print("🔴 Status Code: ${response.statusCode}");
        print("📄 Body: ${response.body}");
      }
    } catch (e) {
      print("❌ Exception during send to $fcmToken: $e");
    }
  }

  /// ✅ Send notification to all users
  Future<void> sendNotificationToAllUsers(String title, String body) async {
    print("🚀 Sending notification to all users...");
    try {
      final tokens = await getAllFcmTokens();

      if (tokens.isEmpty) {
        print("⚠️ No tokens available. Abort sending.");
        return;
      }

      for (String token in tokens) {
        await sendNotificationToToken(token, title, body);
      }

      print("📲 ✅ Notifications sent to all users");
    } catch (e) {
      print("❌ Error sending notifications to all users: $e");
    }
  }
}
