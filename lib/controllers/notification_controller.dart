import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lightlevelpsychosolutionsadmin/utils/app_messenger.dart';

/// Who the broadcast should be delivered to.
enum NotificationTarget { all, company, specific }

class NotificationController extends GetxController {
  // Cloud Function that holds the FCM service account and sends notifications.
  // Keeps the service-account key server-side instead of in the client bundle.
  static const String _functionUrl = 'https://sendadminnotification-zesi6puwbq-uc.a.run.app';

  var isSending = false.obs;

  // **Targeting state**
  final Rx<NotificationTarget> target = NotificationTarget.all.obs;

  // Loaded options for the dropdowns: {id, name}
  final RxList<Map<String, String>> companies = <Map<String, String>>[].obs;
  final RxList<Map<String, String>> users = <Map<String, String>>[].obs;
  final RxBool isLoadingOptions = false.obs;

  // Current selections
  final RxnString selectedCompanyId = RxnString();
  final RxnString selectedUserId = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadTargetingOptions();
  }

  // **Load companies and users so the admin can pick a target**
  Future<void> loadTargetingOptions() async {
    isLoadingOptions.value = true;
    try {
      final companySnapshot = await FirebaseFirestore.instance.collection('companies').get();
      companies.value = companySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': (data['companyId'] ?? doc.id).toString(),
          'name': (data['name'] ?? doc.id).toString(),
        };
      }).toList()
        ..sort((a, b) => a['name']!.toLowerCase().compareTo(b['name']!.toLowerCase()));

      final userSnapshot = await FirebaseFirestore.instance.collection('users').get();
      users.value = userSnapshot.docs
          .where((doc) {
            final data = doc.data();
            return data['fcmToken'] != null && data['fcmToken'].toString().isNotEmpty;
          })
          .map((doc) {
            final data = doc.data();
            final name = (data['name'] ?? '').toString();
            final email = (data['email'] ?? '').toString();
            final label = name.isNotEmpty && email.isNotEmpty
                ? '$name ($email)'
                : (name.isNotEmpty ? name : (email.isNotEmpty ? email : doc.id));
            return {
              'id': doc.id,
              'name': label,
              'fcmToken': data['fcmToken'].toString(),
            };
          })
          .toList()
        ..sort((a, b) => a['name']!.toLowerCase().compareTo(b['name']!.toLowerCase()));
    } catch (e) {
      print('❌ Error loading targeting options: $e');
    } finally {
      isLoadingOptions.value = false;
    }
  }

  // **Fetch all FCM tokens from Firestore**
  Future<List<String>> getAllFcmTokens() async {
    List<String> fcmTokens = [];
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').get();

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey('fcmToken') && data['fcmToken'] != null) {
          String fcmToken = data['fcmToken'];
          fcmTokens.add(fcmToken);
          print("✅ FCM Token found for user ${doc.id}: $fcmToken");
        } else {
          print("⚠️ No valid FCM token for user ${doc.id}, skipping...");
        }
      }
    } catch (e) {
      print('❌ Error fetching FCM tokens: $e');
    }
    return fcmTokens;
  }

  // **Fetch FCM tokens for a single company**
  Future<List<String>> getFcmTokensForCompany(String companyId) async {
    List<String> fcmTokens = [];
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('companyId', isEqualTo: companyId)
          .get();

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>?;

        if (data != null && data['fcmToken'] != null && data['fcmToken'].toString().isNotEmpty) {
          fcmTokens.add(data['fcmToken'].toString());
        } else {
          print("⚠️ No valid FCM token for user ${doc.id}, skipping...");
        }
      }
    } catch (e) {
      print('❌ Error fetching company FCM tokens: $e');
    }
    return fcmTokens;
  }

  // **Fetch the FCM token for a single user**
  Future<String?> getFcmTokenForUser(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final data = doc.data();
      if (data != null && data['fcmToken'] != null && data['fcmToken'].toString().isNotEmpty) {
        return data['fcmToken'].toString();
      }
    } catch (e) {
      print('❌ Error fetching user FCM token: $e');
    }
    return null;
  }

  // **Send notification to a single FCM token. Returns true on success.**
  Future<bool> sendNotificationToToken(String fcmToken, String title, String body) async {
    try {
      // Delegate to the Cloud Function, which holds the service-account key.
      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': fcmToken,
          'title': title,
          'body': body,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Notification sent to $fcmToken");
        return true;
      } else {
        print("❌ Failed to send notification to $fcmToken: ${response.statusCode} ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error sending notification to $fcmToken: $e");
      return false;
    }
  }

  // **Send notification to all users**
  Future<void> sendNotificationToAllUsers(String title, String body) async {
    isSending.value = true;
    try {
      List<String> fcmTokens = await getAllFcmTokens();

      if (fcmTokens.isEmpty) {
        print("⚠️ No valid FCM tokens found. Skipping notifications.");
        showAppSnackBar("No user tokens found to send notifications.", isError: true);
        isSending.value = false;
        return;
      }

      // Send notifications to each token
      int sent = 0;
      for (String token in fcmTokens) {
        if (await sendNotificationToToken(token, title, body)) sent++;
      }

      print('📲 ✅ Notifications sent to $sent/${fcmTokens.length} users!');
      if (sent == 0) {
        showAppSnackBar("Failed to send notifications.", isError: true);
      } else {
        showAppSnackBar("Notification sent to $sent of ${fcmTokens.length} user(s).");
      }
    } catch (e) {
      print('❌ Error sending notifications: $e');
      showAppSnackBar("Failed to send notifications.", isError: true);
    } finally {
      isSending.value = false;
    }
  }

  // **Send notification based on the currently selected target**
  Future<void> sendNotification(String title, String body) async {
    switch (target.value) {
      case NotificationTarget.all:
        await sendNotificationToAllUsers(title, body);
        break;

      case NotificationTarget.company:
        final companyId = selectedCompanyId.value;
        if (companyId == null || companyId.isEmpty) {
          showAppSnackBar("Please select a company.", isError: true);
          return;
        }
        await _sendToCompany(companyId, title, body);
        break;

      case NotificationTarget.specific:
        final userId = selectedUserId.value;
        if (userId == null || userId.isEmpty) {
          showAppSnackBar("Please select a user.", isError: true);
          return;
        }
        await _sendToUser(userId, title, body);
        break;
    }
  }

  // **Send notification to every user in a company**
  Future<void> _sendToCompany(String companyId, String title, String body) async {
    isSending.value = true;
    try {
      final fcmTokens = await getFcmTokensForCompany(companyId);

      if (fcmTokens.isEmpty) {
        showAppSnackBar("No user tokens found for this company.", isError: true);
        return;
      }

      int sent = 0;
      for (String token in fcmTokens) {
        if (await sendNotificationToToken(token, title, body)) sent++;
      }

      print('📲 ✅ Notifications sent to $sent/${fcmTokens.length} for company $companyId!');
      if (sent == 0) {
        showAppSnackBar("Failed to send notifications.", isError: true);
      } else {
        showAppSnackBar("Notification sent to $sent of ${fcmTokens.length} user(s).");
      }
    } catch (e) {
      print('❌ Error sending company notifications: $e');
      showAppSnackBar("Failed to send notifications.", isError: true);
    } finally {
      isSending.value = false;
    }
  }

  // **Send notification to a single user**
  Future<void> _sendToUser(String userId, String title, String body) async {
    isSending.value = true;
    try {
      final fcmToken = await getFcmTokenForUser(userId);

      if (fcmToken == null || fcmToken.isEmpty) {
        showAppSnackBar("No valid token found for this user.", isError: true);
        return;
      }

      final success = await sendNotificationToToken(fcmToken, title, body);

      if (success) {
        print('📲 ✅ Notification sent to user $userId!');
        showAppSnackBar("Notification sent successfully!");
      } else {
        print('❌ Notification failed for user $userId');
        showAppSnackBar("Failed to send notification.", isError: true);
      }
    } catch (e) {
      print('❌ Error sending notification: $e');
      showAppSnackBar("Failed to send notification.", isError: true);
    } finally {
      isSending.value = false;
    }
  }
}
