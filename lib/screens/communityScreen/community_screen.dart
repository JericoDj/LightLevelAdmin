import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CommunityScreen extends StatefulWidget {
  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _updatePostStatus(String postId, String newStatus) async {
    await _firestore.collection('safeSpace/posts/userPosts').doc(postId).update({
      "status": newStatus,
    });
  }

  void _deletePost(String postId) async {
    await _firestore.collection('safeSpace/posts/userPosts').doc(postId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Community Management'), backgroundColor: Colors.blue),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                _buildPostSection("Pending Review", "pending"),
                _buildPostSection("All Posts", "approved"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostSection(String title, String status) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('safeSpace/posts/userPosts')
            .where("status", isEqualTo: status)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No posts"));
          }

          var filteredPosts = snapshot.data!.docs;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(title, style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredPosts.length,
                  itemBuilder: (context, index) {
                    var post = filteredPosts[index].data() as Map<String, dynamic>;
                    var postId = filteredPosts[index].id;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child: ListTile(
                        title: Text(post["userId"]),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(post["content"]),
                            if (status == "approved")
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () => _showLikesDialog(post["likes"]),
                                    child: Text("👍 ${post["likes"]?.length ?? 0} Likes"),
                                  ),
                                  TextButton(
                                    onPressed: () => _showCommentsDialog(
                                        post["comments"] ?? [], postId),
                                    child: Text("💬 ${post["comments"]?.length ?? 0} Comments"),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        onTap: () {
                          if (status == "pending") {
                            _showPendingReviewDialog(post, postId);
                          } else {
                            _showDeletePostDialog(postId);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPendingReviewDialog(Map<String, dynamic> post, String postId) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(16),
            width: 400,
            height: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Review Post",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 12),
                Text(post["content"], style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _updatePostStatus(postId, "approved");
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text("Approve"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _updatePostStatus(postId, "rejected");
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("Reject"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeletePostDialog(String postId) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(16),
            width: 300,
            height: 180,
            child: Column(
              children: [
                const Text("Delete Post?",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 16),
                const Text("Are you sure you want to delete this post?", textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _deletePost(postId);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("Delete"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                      child: const Text("Cancel"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLikesDialog(dynamic likesData) {
    List<String> likes = (likesData as List<dynamic>)
        .map((like) => like.toString())  // ✅ Convert to List<String>
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(16),
            width: 300,
            height: likes.isNotEmpty ? 300 : 150,
            child: Column(
              children: [
                const Text("Liked by", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Expanded(
                  child: likes.isNotEmpty
                      ? ListView.builder(
                    itemCount: likes.length,
                    itemBuilder: (context, index) => ListTile(
                      leading: const Icon(Icons.person, color: Colors.blue),
                      title: Text(likes[index]),
                    ),
                  )
                      : const Center(child: Text("No likes yet")),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCommentsDialog(dynamic commentsData, String postId) {
    List<Map<String, dynamic>> comments = (commentsData as List<dynamic>)
        .map((comment) => Map<String, dynamic>.from(comment))
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(16),
                width: 400,
                height: 400,
                child: Column(
                  children: [
                    const Text("Comments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Expanded(
                      child: comments.isNotEmpty
                          ? ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          var comment = comments[index];
                          return ListTile(
                            leading: const Icon(Icons.person, color: Colors.blue),
                            title: Text(comment["user"] ?? "Unknown User"),
                            subtitle: Text(comment["comment"] ?? "No Comment"),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  comments.removeAt(index);
                                });

                                // ✅ Update comments in Firestore
                                _firestore.collection('safeSpace/posts/userPosts').doc(postId).update({
                                  "comments": comments,
                                });
                              },
                            ),
                          );
                        },
                      )
                          : const Center(child: Text("No comments yet")),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
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

}
