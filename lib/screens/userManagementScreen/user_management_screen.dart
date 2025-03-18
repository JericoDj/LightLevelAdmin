import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  void _showCompanyDialog({String? companyId, String? existingName, String? existingRole}) {
    TextEditingController companyNameController = TextEditingController(text: existingName);
    TextEditingController companyIdController = TextEditingController(text: companyId);
    String selectedRole = existingRole ?? "User"; // Default role

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
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () async {
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

                    var existingCompany = await _firestore.collection("companies").doc(newCompanyId).get();

                    if (!existingCompany.exists || companyId != null) {
                      await _firestore.collection("companies").doc(newCompanyId).set({
                        "companyId": newCompanyId,
                        "name": companyName,
                        "role": selectedRole, // Add role to Firestore
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
                  child: Text(companyId == null ? "Add" : "Update"),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.height * 0.7,
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
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 20),
                    ),
                    IconButton(icon: Icon(Icons.close, color: Colors.red), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection("companies").doc(companyId).collection("users").snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
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
                                    icon: Icon(user["isActive"] ? Icons.check_circle : Icons.cancel, color: Colors.green),
                                    onPressed: () {
                                      _firestore.collection("companies").doc(companyId).collection("users").doc(user.id).update({
                                        "isActive": !user["isActive"],
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _firestore.collection("companies").doc(companyId).collection("users").doc(user.id).delete();
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
                  label: Text("Add User"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showUserDialog(String companyId) {
    TextEditingController nameController = TextEditingController();
    TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add User"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: "Full Name")),
              TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
                  var existingUser = await _firestore.collection("users").where("email", isEqualTo: emailController.text).get();
                  bool hasAccount = existingUser.docs.isNotEmpty;

                  await _firestore.collection("companies").doc(companyId).collection("users").add({
                    "name": nameController.text,
                    "email": emailController.text,
                    "isActive": true,
                    "hasAccount": hasAccount,
                  });
                }
                Navigator.pop(context);
              },
              child: Text("Add User"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Management'), backgroundColor: Colors.blue),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // **Title**
            Text(
              "Companies",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection("companies").snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                  var companies = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: companies.length,
                    itemBuilder: (context, index) {
                      var company = companies[index];

                      // Ensure 'role' field exists in Firestore data
                      String companyRole = company["role"] ?? "User";

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          title: Text("${company["name"]}"),
                          subtitle: Text("ID: ${company["companyId"]} | Role: $companyRole"), // ✅ Displaying company role
                          onTap: () => _showUsersDialog(company["companyId"], company["name"]),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showCompanyDialog(
                                  companyId: company["companyId"],
                                  existingName: company["name"],
                                  existingRole: companyRole, // ✅ Passing role when editing
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteCompany(company["companyId"]),
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
              label: Text("Add Company"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}