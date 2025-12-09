
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
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


  void _showCompanyDialog(
      {String? companyId, String? existingName, String? existingRole, bool? existingSafeAccess}) {
    TextEditingController companyNameController = TextEditingController(
        text: existingName);
    TextEditingController companyIdController = TextEditingController(
        text: companyId);
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
                        .map((role) =>
                        DropdownMenuItem(
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
                          activeColor: MyColors.color1,
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

                    var existingCompany =
                    await _firestore.collection("companies").doc(newCompanyId).get();

                    if (!existingCompany.exists || companyId != null) {
                      await _firestore.collection("companies").doc(newCompanyId).set({
                        "companyId": newCompanyId,
                        "name": companyName,
                        "role": selectedRole,
                        if (selectedRole == "User") "safeCommunityAccess": safeCommunityAccess,
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
                          message: "Company ID already exists. Please choose another.",
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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


  void _deleteCompany(String companyId) async {
    await _firestore.collection("companies").doc(companyId).delete();
  }

  void _showUsersDialog(String companyId, String companyName) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: MediaQuery
                .of(context)
                .size
                .width * 0.7,
            height: MediaQuery
                .of(context)
                .size
                .height * 0.7,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // **Header**
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$companyName - Users",
                      style: TextStyle(fontWeight: FontWeight.bold,
                          color: MyColors.color2,
                          fontSize: 20),
                    ),
                    IconButton(icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection("companies")
                        .doc(companyId)
                        .collection("users")
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return Center(child: CircularProgressIndicator());
                      var users = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          var user = users[index];

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            child: ListTile(
                              title: Text(user["name"]),
                              subtitle: Text(user["email"]),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      user["isActive"] ? Icons.check_circle : Icons.cancel,
                                      color: Colors.green,
                                    ),
                                    onPressed: () async {
                                      final String email = user["email"];
                                      print("📧 Email: $email");
                                      final bool newStatus = !user["isActive"];

                                      // 🔄 Update company user `isActive` status
                                      await _firestore
                                          .collection("companies")
                                          .doc(companyId)
                                          .collection("users")
                                          .doc(user.id)
                                          .update({"isActive": newStatus});

                                      // 🔄 Find user in top-level `users/` collection
                                      final userQuery = await _firestore
                                          .collection("users")
                                          .where("email", isEqualTo: email)
                                          .where("companyId", isEqualTo: companyId)
                                          .limit(1)
                                          .get();

                                      if (userQuery.docs.isNotEmpty) {
                                        final userDoc = userQuery.docs.first;
                                        final userDocId = userDoc.id;
                                        final currentAccess = userDoc.data()["access"] ?? true;

                                        // 🟢 Toggle access
                                        final newAccess = !currentAccess;

                                        print("🧾 Current access: $currentAccess → New access: $newAccess");

                                        await _firestore
                                            .collection("users")
                                            .doc(userDocId)
                                            .update({"access": newAccess});
                                      } else {
                                        print("⚠️ No matching user found in top-level 'users' collection.");
                                      }
                                    },
                                  ),

                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      final bool? confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (BuildContext dialogContext) {
                                          return AlertDialog(
                                            title: const Text("Confirm Deletion"),
                                            content: const Text("Are you sure you want to delete this user?"),
                                            actions: [
                                              TextButton(
                                                child: const Text("Cancel"),
                                                onPressed: () => Navigator.of(dialogContext).pop(false),
                                              ),
                                              TextButton(
                                                child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                                onPressed: () => Navigator.of(dialogContext).pop(true),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      if (confirm == true) {
                                        final String email = user["email"];

                                        // Step 1: Delete from companies/{companyId}/users
                                        await _firestore
                                            .collection("companies")
                                            .doc(companyId)
                                            .collection("users")
                                            .doc(user.id)
                                            .delete();

                                        // ✅ Debug log before Step 2
                                        debugPrint("🟡 Proceeding to global users query with:");
                                        debugPrint("📧 Email: $email");
                                        debugPrint("🏢 Company ID: $companyId");

                                        // Step 2: Find and delete from global users collection
                                        final userQuery = await _firestore
                                            .collection("users")
                                            .where("email", isEqualTo: email)
                                            .where("companyId", isEqualTo: companyId)
                                            .limit(1)
                                            .get();

                                        if (userQuery.docs.isNotEmpty) {
                                          final userDoc = userQuery.docs.first;
                                          final uid = userDoc["uid"];
                                          final docId = userDoc.id;

                                          debugPrint("🟢 Step 3: Ready to delete from Firebase Auth");
                                          debugPrint("📄 Firestore docId: $docId");
                                          debugPrint("🔐 UID to delete: $uid");

                                          await _deleteUser(context, uid, docId); // pass context to _deleteUser
                                        } else {
                                          debugPrint("🔴 No matching document found in global users collection.");
                                        }
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
                  ),
                ),


                // **Footer**
                ElevatedButton.icon(
                  onPressed: () => _showUserDialog(companyId),
                  icon: Icon(Icons.add, color: Colors.white),
                  label: Text("Add User",style: TextStyle(color: MyColors.white),),

                  style: ElevatedButton.styleFrom(backgroundColor: MyColors.color2),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Future<void> _deleteUser(BuildContext context, String uid, String docId) async {
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

      const String functionUrl = "https://deleteuseraccount-zesi6puwbq-uc.a.run.app";
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
        await FirebaseFirestore.instance.collection("users").doc(docId).delete();

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
    TextEditingController nameController = TextEditingController();
    TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add User", style: TextStyle(color: MyColors.color2),),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController,
                  decoration: InputDecoration(labelText: "Full Name")),
              TextField(controller: emailController,
                  decoration: InputDecoration(labelText: "Email")),
            ],
          ),
          actions: [
            TextButton(
                style: TextButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(color: Colors.white),)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: MyColors.color2),
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    emailController.text.isNotEmpty) {
                  var existingUser = await _firestore.collection("users").where(
                      "email", isEqualTo: emailController.text).get();
                  bool hasAccount = existingUser.docs.isNotEmpty;

                  await _firestore.collection("companies")
                      .doc(companyId)
                      .collection("users")
                      .add({
                    "name": nameController.text,
                    "email": emailController.text,
                    "isActive": true,
                    "hasAccount": hasAccount,
                  });
                }
                Navigator.pop(context);
              },
              child: Text("Add User", style: TextStyle(color: MyColors.white),),
            ),
          ],
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: const Text(
                'User Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24  ,
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
              style: TextStyle(fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection("companies").snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return Center(child: CircularProgressIndicator());

                  var companies = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: companies.length,
                    itemBuilder: (context, index) {
                      var company = companies[index];

                      // Ensure 'role' field exists in Firestore data
                      String companyRole = company["role"] ?? "User";
                      var companyData = company.data() as Map<String, dynamic>?; // Explicitly cast to Map
                      bool safeCommunityAccess = (companyData != null && companyData.containsKey("safeCommunityAccess"))
                          ? companyData["safeCommunityAccess"]
                          : false;


                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          onTap: () => _showUsersDialog(
                              company["companyId"], company["name"]),
                          title: Text("${company["name"]}"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "ID: ${company["companyId"]} | Role: $companyRole"),
                              // ✅ Show Safe Community Access ONLY for "User" role
                              if (companyRole == "User")
                                Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .spaceBetween,
                                  children: [
                                    const Text("Safe Community Access"),
                                    Switch(
                                      activeColor: MyColors.color1,
                                      value: safeCommunityAccess,
                                      onChanged: (value) {
                                        _firestore.collection("companies").doc(
                                            company.id).update({
                                          "safeCommunityAccess": value,
                                        });
                                      },
                                    ),
                                  ],
                                ),
                            ],
                          ),

                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: MyColors.color2),
                                onPressed: () =>
                                    _showCompanyDialog(
                                      companyId: company["companyId"],
                                      existingName: company["name"],
                                      existingRole: companyRole,
                                      // ✅ Passing role when editing
                                      existingSafeAccess: safeCommunityAccess, // ✅ Passing safe access value
                                    ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _deleteCompany(company["companyId"]),
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
              label: Text("Add Company", style: TextStyle(color: MyColors.white),),
              style: ElevatedButton.styleFrom(backgroundColor: MyColors.color1),
            ),
          ],
        ),
      ),
    );
  }
}