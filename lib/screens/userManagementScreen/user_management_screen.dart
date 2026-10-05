import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lightlevelpsychosolutionsadmin/utils/colors.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../utils/user_storage.dart';

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  void _showCompanyDialog(
      {String? companyId,
      String? existingName,
      String? existingRole,
      bool? existingSafeAccess}) {
    TextEditingController companyNameController =
        TextEditingController(text: existingName);
    TextEditingController companyIdController =
        TextEditingController(text: companyId);
    String selectedRole = existingRole ?? "User"; // Default role
    bool safeCommunityAccess = existingSafeAccess ?? false; // Default to false

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(companyId == null ? "Add Company" : "Edit Company"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: companyIdController,
                    decoration: InputDecoration(labelText: "Company ID"),
                    enabled: companyId == null, // Prevent editing existing IDs
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: companyNameController,
                    decoration: InputDecoration(labelText: "Company Name"),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    items: ["Specialist", "Admin", "Super Admin", "User"]
                        .map((role) => DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedRole = value);
                      }
                    },
                    decoration: InputDecoration(labelText: "Company Role"),
                  ),
                  const SizedBox(height: 10),
                  // Show Safe Community Access switch ONLY for "User" role
                  if (selectedRole == "User")
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Safe Community Access"),
                        Switch(
                          activeColor: MyColors.color2,
                          value: safeCommunityAccess,
                          onChanged: (value) {
                            setState(() {
                              safeCommunityAccess = value;
                            });
                          },
                        ),
                      ],
                    ),
                ],
              ),
              actions: [
                // Cancel Button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: MyColors.color2,
                      border: Border.all(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                // Confirm Button (Add / Update)
                GestureDetector(
                  onTap: () async {
                    String newCompanyId = companyIdController.text.trim();
                    String companyName = companyNameController.text.trim();

                    if (newCompanyId.isEmpty || companyName.isEmpty) {
                      showTopSnackBar(
                        Overlay.of(context),
                        const CustomSnackBar.error(
                          message: "Company ID and Name cannot be empty.",
                        ),
                      );
                      return;
                    }

                    var existingCompany = await _firestore
                        .collection("companies")
                        .doc(newCompanyId)
                        .get();

                    if (!existingCompany.exists || companyId != null) {
                      await _firestore
                          .collection("companies")
                          .doc(newCompanyId)
                          .set({
                        "companyId": newCompanyId,
                        "name": companyName,
                        "role": selectedRole,
                        if (selectedRole == "User")
                          "safeCommunityAccess": safeCommunityAccess,
                      });

                      Navigator.pop(context);

                      showTopSnackBar(
                        Overlay.of(context),
                        const CustomSnackBar.success(
                          message: "Company saved successfully!",
                        ),
                      );
                    } else {
                      showTopSnackBar(
                        Overlay.of(context),
                        const CustomSnackBar.error(
                          message:
                              "Company ID already exists. Please choose another.",
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: MyColors.color1,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      companyId == null ? "Add" : "Update",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Firebase Auth account info (uid, createdAt, lastSignInAt) keyed by
  // lowercase email, loaded from the getAuthUserDates Cloud Function.
  final Map<String, Map<String, dynamic>> _authInfoByEmail = {};
  final Set<String> _authRequestedEmails = {};

  static const String _authUserDatesUrl =
      "https://us-central1-llps-mentalapp.cloudfunctions.net/getAuthUserDates";

  Future<void> _loadAuthInfo(List<String> emails, VoidCallback onLoaded) async {
    final missing = emails
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty && !_authRequestedEmails.contains(e))
        .toSet()
        .toList();
    if (missing.isEmpty) return;
    _authRequestedEmails.addAll(missing);

    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) throw Exception("Not signed in");

      final response = await dio.Dio().post(
        _authUserDatesUrl,
        data: {"emails": missing},
        options: dio.Options(headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $idToken",
        }),
      );

      final users = response.data["users"];
      if (users is Map) {
        users.forEach((email, info) {
          _authInfoByEmail[email.toString()] = Map<String, dynamic>.from(info);
        });
      }
      onLoaded();
    } catch (e) {
      debugPrint("❌ Error loading auth user dates: $e");
      // Allow a retry next time the dialog is opened
      _authRequestedEmails.removeAll(missing);
    }
  }

  String _formatDate(dynamic raw) {
    DateTime? date;
    if (raw is Timestamp) date = raw.toDate();
    if (raw is DateTime) date = raw;
    if (raw is String) date = DateTime.tryParse(raw);
    if (date == null) return "—";
    return DateFormat("MMM d, yyyy").format(date.toLocal());
  }

  Future<void> _deleteCompany(String companyId) async {
    await _firestore.collection("companies").doc(companyId).delete();
  }

  Future<bool> _companyHasUsers(String companyId) async {
    final snapshot = await _firestore
        .collection("companies")
        .doc(companyId)
        .collection("users")
        .limit(1) // Only check 1 → avoids heavy reads
        .get();

    return snapshot.docs.isNotEmpty;
  }

  void _showUsersDialog(String companyId, String companyName, String role) {
    String userSearch = "";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.7,
                height: MediaQuery.of(context).size.height * 0.7,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          companyName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: MyColors.color2,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    Text("ID: $companyId | Role: $role"),

                    const SizedBox(height: 16),

                    // 🔍 SEARCH FIELD
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Search user...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) {
                        setStateDialog(() {
                          userSearch = value.toLowerCase().trim();
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // USERS LIST
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection("companies")
                            .doc(companyId)
                            .collection("users")
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          // ORIGINAL USERS
                          final allUsers = snapshot.data!.docs.toList()
                            ..sort((a, b) {
                              final nameA =
                                  (a.data() as Map<String, dynamic>)["name"]
                                          ?.toString()
                                          .toLowerCase() ??
                                      "";
                              final nameB =
                                  (b.data() as Map<String, dynamic>)["name"]
                                          ?.toString()
                                          .toLowerCase() ??
                                      "";
                              return nameA.compareTo(nameB);
                            });

                          // FILTER USERS
                          final users = allUsers.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final name =
                                data["name"]?.toString().toLowerCase() ?? "";
                            final email =
                                data["email"]?.toString().toLowerCase() ?? "";

                            return name.contains(userSearch) ||
                                email.contains(userSearch);
                          }).toList();

                          if (users.isEmpty) {
                            return const Center(
                              child: Text("No users found."),
                            );
                          }

                          // Load Firebase Auth dates for these users (once per email)
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _loadAuthInfo(
                              allUsers
                                  .map((doc) => ((doc.data() as Map<String, dynamic>)["email"] ?? "").toString())
                                  .toList(),
                              () {
                                if (context.mounted) setStateDialog(() {});
                              },
                            );
                          });

                          // App accounts (signed-up users) of this company, keyed by email
                          return StreamBuilder<QuerySnapshot>(
                            stream: _firestore
                                .collection("users")
                                .where("companyId", isEqualTo: companyId)
                                .snapshots(),
                            builder: (context, accountSnapshot) {
                              final accountsByEmail =
                                  <String, Map<String, dynamic>>{};
                              for (final doc
                                  in accountSnapshot.data?.docs ?? []) {
                                final account =
                                    doc.data() as Map<String, dynamic>;
                                final email = account["email"]
                                        ?.toString()
                                        .trim()
                                        .toLowerCase() ??
                                    "";
                                if (email.isNotEmpty) {
                                  accountsByEmail[email] = {
                                    ...account,
                                    "uid": account["uid"] ?? doc.id
                                  };
                                }
                              }

                              return ListView.builder(
                                itemCount: users.length,
                                itemBuilder: (context, index) {
                                  final user = users[index];
                                  final data =
                                      user.data() as Map<String, dynamic>;
                                  final emailKey = data["email"]
                                          ?.toString()
                                          .trim()
                                          .toLowerCase() ??
                                      "";
                                  final account = accountsByEmail[emailKey];
                                  // Firebase Auth is the source of truth for
                                  // sign-up dates; Firestore is the fallback.
                                  final authInfo = _authInfoByEmail[emailKey];
                                  final hasAccount =
                                      authInfo != null || account != null;
                                  final uid = (authInfo?["uid"] ??
                                          account?["uid"] ??
                                          "")
                                      .toString();

                                  return Card(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.orange.shade100,
                                        child: Text(
                                          "${index + 1}",
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      title: Text(data["name"] ?? ""),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(data["email"] ?? ""),
                                          const SizedBox(height: 2),
                                          Text(
                                            "Enrolled: ${_formatDate(data["createdAt"])}"
                                            "  •  Signed Up: ${hasAccount ? _formatDate(authInfo?["createdAt"] ?? account?["createdAt"]) : "No account yet"}"
                                            "${authInfo?["lastSignInAt"] != null ? "  •  Last Sign-In: ${_formatDate(authInfo!["lastSignInAt"])}" : ""}"
                                            "  •  User ID: ${uid.isEmpty ? "—" : "…${uid.substring(uid.length > 4 ? uid.length - 4 : 0)}"}",
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade700),
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // ACTIVATE / DEACTIVATE
                                          IconButton(
                                            icon: Icon(
                                              data["isActive"] == true
                                                  ? Icons.check_circle
                                                  : Icons.cancel,
                                              color: Colors.green,
                                            ),
                                            onPressed: () async {
                                              final newStatus =
                                                  !(data["isActive"] ?? false);

                                              await _firestore
                                                  .collection("companies")
                                                  .doc(companyId)
                                                  .collection("users")
                                                  .doc(user.id)
                                                  .update(
                                                      {"isActive": newStatus});
                                            },
                                          ),

                                          // DELETE USER
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () async {
                                              /// 🔥 IMPORTANT: capture SAFE context before dialog closes
                                              final rootContext = context;

                                              final confirm =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text(
                                                      "Confirm Deletion"),
                                                  content: const Text(
                                                      "Delete this user?"),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              rootContext,
                                                              false),
                                                      child:
                                                          const Text("Cancel"),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              rootContext,
                                                              true),
                                                      child: const Text(
                                                        "Delete",
                                                        style: TextStyle(
                                                            color: Colors.red),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirm != true) return;

                                              final email = data["email"];

                                              // DELETE mini user
                                              await _firestore
                                                  .collection("companies")
                                                  .doc(companyId)
                                                  .collection("users")
                                                  .doc(user.id)
                                                  .delete();

                                              // GET company role
                                              final companyDoc =
                                                  await _firestore
                                                      .collection("companies")
                                                      .doc(companyId)
                                                      .get();
                                              final companyRole = companyDoc
                                                      .data()?["role"]
                                                      ?.toString()
                                                      .toLowerCase() ??
                                                  "user";

                                              // DELETE ADMIN
                                              if (companyRole != "user") {
                                                final adminQuery =
                                                    await _firestore
                                                        .collection("admins")
                                                        .where("email",
                                                            isEqualTo: email)
                                                        .limit(1)
                                                        .get();

                                                if (adminQuery
                                                    .docs.isNotEmpty) {
                                                  await _deleteAdmin(
                                                      rootContext,
                                                      adminQuery.docs.first.id);
                                                }
                                              }

                                              // DELETE global user
                                              final userQuery = await _firestore
                                                  .collection("users")
                                                  .where("email",
                                                      isEqualTo: email)
                                                  .where("companyId",
                                                      isEqualTo: companyId)
                                                  .limit(1)
                                                  .get();

                                              if (userQuery.docs.isNotEmpty) {
                                                final doc =
                                                    userQuery.docs.first;
                                                await _deleteUser(rootContext,
                                                    doc["uid"], doc.id);
                                              }

                                              /// SAFE SNACKBAR — use ROOT CONTEXT
                                              if (rootContext.mounted) {
                                                ScaffoldMessenger.of(
                                                        rootContext)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        "User deleted successfully."),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // ADD USER BUTTON
                    ElevatedButton.icon(
                      onPressed: () => _showUserDialog(companyId),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: Text(
                        "Add User",
                        style: TextStyle(color: MyColors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyColors.color2,
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

  Future<void> _deleteAdmin(BuildContext context, String uid) async {
    try {
      print("running deletion of admin");
      final String currentUserUid = UserStorage.getUser()?['uid'] ?? '';

      if (uid == currentUserUid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You can't delete your own admin account."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      const String functionUrl =
          "https://deleteuseraccount-zesi6puwbq-uc.a.run.app";
      final dio.Dio httpClient = dio.Dio();

      debugPrint("📡 Calling delete function: $functionUrl");
      debugPrint("🧾 Sending UID: $uid");

      final response = await httpClient.post(
        functionUrl,
        data: {"uid": uid},
        options: dio.Options(
          headers: {
            "Content-Type": "application/json",
          },
        ),
      );

      debugPrint("📡 Response: ${response.statusCode} - ${response.data}");

      if (response.statusCode == 200 && response.data['success'] == true) {
        await FirebaseFirestore.instance.collection("admins").doc(uid).delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User deleted successfully."),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete user: ${response.data}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("🔥 Deletion Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unexpected error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteUser(
      BuildContext context, String uid, String docId) async {
    try {
      final String currentUserUid = UserStorage.getUser()?['uid'] ?? '';

      if (uid == currentUserUid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You can't delete your own admin account."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      const String functionUrl =
          "https://deleteuseraccount-zesi6puwbq-uc.a.run.app";
      final dio.Dio httpClient = dio.Dio();

      debugPrint("📡 Calling delete function: $functionUrl");
      debugPrint("🧾 Sending UID: $uid");

      final response = await httpClient.post(
        functionUrl,
        data: {"uid": uid},
        options: dio.Options(
          headers: {
            "Content-Type": "application/json",
          },
        ),
      );

      debugPrint("📡 Response: ${response.statusCode} - ${response.data}");

      if (response.statusCode == 200 && response.data['success'] == true) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(docId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User deleted successfully."),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete user: ${response.data}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("🔥 Deletion Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unexpected error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUserDialog(String companyId) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // 🔒 prevent accidental close while loading
      builder: (dialogContext) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width:
                      MediaQuery.sizeOf(context).width * (kIsWeb ? 0.3 : 0.9),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// ✅ TITLE
                      Text(
                        "Add User",
                        style: TextStyle(
                          color: MyColors.color2,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      /// ✅ NAME
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: "Full Name",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      /// ✅ EMAIL
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      /// ✅ ACTIONS
                      Row(
                        children: [
                          /// ❌ CANCEL
                          Expanded(
                            child: GestureDetector(
                              onTap: isLoading
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),

                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //   children: [
                          //     ElevatedButton.icon(
                          //       icon: const Icon(Icons.download, color: Colors.white),
                          //       label: const Text("Download Users"),
                          //       style: ElevatedButton.styleFrom(backgroundColor: MyColors.color1),
                          //       onPressed: () => _downloadUsers(companyId, companyName),
                          //     ),
                          //     ElevatedButton.icon(
                          //       icon: const Icon(Icons.upload_file, color: Colors.white),
                          //       label: const Text("Upload Users"),
                          //       style: ElevatedButton.styleFrom(backgroundColor: MyColors.color2),
                          //       onPressed: () => _uploadUsers(companyId, context),
                          //     ),
                          //   ],
                          // ),
                          // const SizedBox(height: 12),
                          const SizedBox(width: 12),

                          /// ✅ ADD USER
                          Expanded(
                            child: GestureDetector(
                              onTap: isLoading
                                  ? null
                                  : () async {
                                      final name = nameController.text.trim();
                                      final email = emailController.text
                                          .trim()
                                          .toLowerCase();

                                      if (name.isEmpty || email.isEmpty) return;

                                      setDialogState(() => isLoading = true);

                                      try {
                                        /// 🔍 CHECK ALL COMPANIES → USERS
                                        final companiesSnapshot =
                                            await _firestore
                                                .collection("companies")
                                                .get();

                                        bool emailExists = false;

                                        for (final company
                                            in companiesSnapshot.docs) {
                                          final usersSnapshot = await _firestore
                                              .collection("companies")
                                              .doc(company.id)
                                              .collection("users")
                                              .where("email", isEqualTo: email)
                                              .limit(1)
                                              .get();

                                          if (usersSnapshot.docs.isNotEmpty) {
                                            emailExists = true;
                                            break;
                                          }
                                        }

                                        /// ❌ EMAIL EXISTS
                                        if (emailExists) {
                                          Navigator.pop(dialogContext);

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                "❌ This email already exists in another company.",
                                              ),
                                              backgroundColor: Colors.red,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              margin: EdgeInsets.fromLTRB(
                                                16,
                                                20,
                                                16,
                                                MediaQuery.of(context)
                                                        .size
                                                        .height -
                                                    120,
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        /// 🔍 CHECK GLOBAL USERS
                                        final globalUserQuery = await _firestore
                                            .collection("users")
                                            .where("email", isEqualTo: email)
                                            .limit(1)
                                            .get();

                                        final bool hasAccount =
                                            globalUserQuery.docs.isNotEmpty;

                                        /// ✅ ADD USER
                                        await _firestore
                                            .collection("companies")
                                            .doc(companyId)
                                            .collection("users")
                                            .add({
                                          "name": name,
                                          "email": email,
                                          "isActive": true,
                                          "hasAccount": hasAccount,
                                          "createdAt":
                                              FieldValue.serverTimestamp(),
                                        });

                                        Navigator.pop(dialogContext);

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                                "✅ User added successfully."),
                                            backgroundColor: MyColors.color1,
                                            behavior: SnackBarBehavior.floating,
                                            margin: EdgeInsets.fromLTRB(
                                              16,
                                              20,
                                              16,
                                              MediaQuery.of(context)
                                                      .size
                                                      .height -
                                                  120,
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        Navigator.pop(dialogContext);

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                "❌ Failed to add user: $e"),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                            dismissDirection:
                                                DismissDirection.up,
                                            margin: EdgeInsets.fromLTRB(
                                              16,
                                              20,
                                              16,
                                              MediaQuery.of(context)
                                                      .size
                                                      .height -
                                                  120,
                                            ),
                                          ),
                                        );
                                      } finally {
                                        if (mounted) {
                                          setDialogState(
                                              () => isLoading = false);
                                        }
                                      }
                                    },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: MyColors.color2,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Text(
                                        "Add User",
                                        style: TextStyle(color: MyColors.white),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50), // <-- set your desired height here

        child: AppBar(
          title: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'User Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: MediaQuery.of(context).size.width * 0.012,
                ),
              ),
            ),
          ),
          backgroundColor: Colors.green[800],
          elevation: 0,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // **Title**
            Text(
              "Companies",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),

            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search company...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase().trim();
                });
              },
            ),

            const SizedBox(height: 16),

            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection("companies").snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return Center(child: CircularProgressIndicator());

                  var companies = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data["name"]?.toString().toLowerCase() ?? "";
                    final id =
                        data["companyId"]?.toString().toLowerCase() ?? "";

                    return name.contains(searchQuery) ||
                        id.contains(searchQuery);
                  }).toList();

                  return ListView.builder(
                    itemCount: companies.length,
                    itemBuilder: (context, index) {
                      var company = companies[index];

                      // Ensure 'role' field exists in Firestore data
                      String companyRole = company["role"] ?? "User";
                      var companyData = company.data()
                          as Map<String, dynamic>?; // Explicitly cast to Map
                      bool safeCommunityAccess = (companyData != null &&
                              companyData.containsKey("safeCommunityAccess"))
                          ? companyData["safeCommunityAccess"]
                          : false;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          onTap: () => _showUsersDialog(company["companyId"],
                              company["name"], company["role"]),
                          title: Text("${company["name"]}"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "ID: ${company["companyId"]} | Role: $companyRole"),
                              // ✅ Show Safe Community Access ONLY for "User" role
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (companyRole == "User")
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Text(
                                        style: TextStyle(fontSize: 14),
                                        "Safe Community Access"),
                                    Switch(
                                      activeColor: MyColors.color1,
                                      value: safeCommunityAccess,
                                      onChanged: (value) {
                                        _firestore
                                            .collection("companies")
                                            .doc(company.id)
                                            .update({
                                          "safeCommunityAccess": value,
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              IconButton(
                                icon: Icon(Icons.edit, color: MyColors.color2),
                                onPressed: () => _showCompanyDialog(
                                  companyId: company["companyId"],
                                  existingName: company["name"],
                                  existingRole: companyRole,
                                  // ✅ Passing role when editing
                                  existingSafeAccess:
                                      safeCommunityAccess, // ✅ Passing safe access value
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDeleteCompany(
                                    context, company["companyId"]),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // **Add Company Button**
            ElevatedButton.icon(
              onPressed: () => _showCompanyDialog(),
              icon: Icon(Icons.add, color: Colors.white),
              label: Text(
                "Add Company",
                style: TextStyle(color: MyColors.white),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: MyColors.color1),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteCompany(
      BuildContext context, String companyId) async {
    // 🔍 Check if users exist FIRST
    final hasUsers = await _companyHasUsers(companyId);

    if (hasUsers) {
      // ❌ Company has users → show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Cannot delete this company because it still has users."),
          backgroundColor: Colors.red,
        ),
      );
      return; // ⛔ Stop here, do not show delete dialog
    }

    // ✔️ No users → show delete confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Company"),
        content: const Text("Are you sure you want to delete this company?"),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // CANCEL BUTTON
              GestureDetector(
                onTap: () => Navigator.of(dialogContext).pop(false),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black87, width: 1.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // DELETE BUTTON
              GestureDetector(
                onTap: () => Navigator.of(dialogContext).pop(true),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Delete",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteCompany(companyId);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Company deleted successfully"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
