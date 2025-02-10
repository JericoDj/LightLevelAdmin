import 'package:flutter/material.dart';

class CommunityScreen extends StatefulWidget {
  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<Map<String, dynamic>> posts = [
    {
      "id": "1",
      "user": "John Doe",
      "content": "Loving this app! ❤️",
      "likes": ["Alice", "Bob", "Charlie"],
      "comments": [
        {"user": "Alice", "comment": "Great post!"},
        {"user": "Bob", "comment": "I agree, this app is awesome!"},
      ],
      "status": "approved",
    },
    {
      "id": "2",
      "user": "Jane Smith",
      "content": "New features are amazing! 🚀",
      "likes": ["Daniel", "Eve"],
      "comments": [
        {"user": "Daniel", "comment": "Loving the update!"},
      ],
      "status": "approved",
    },
    {
      "id": "3",
      "user": "Alice Brown",
      "content": "Feature request: Dark mode! 🌙",
      "status": "pending",
    },
  ];

  void _updatePostStatus(String postId, String newStatus) {
    setState(() {
      posts.firstWhere((post) => post["id"] == postId)["status"] = newStatus;
    });
  }

  void _deletePost(String postId) {
    setState(() {
      posts.removeWhere((post) => post["id"] == postId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Community Management'), backgroundColor: Colors.blue),
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
    List<Map<String, dynamic>> filteredPosts = posts.where((
        post) => post["status"] == status).toList();

    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(title, style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          Expanded(
            child: filteredPosts.isEmpty
                ? Center(child: Text("No posts"))
                : ListView.builder(
              itemCount: filteredPosts.length,
              itemBuilder: (context, index) {
                var post = filteredPosts[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: ListTile(
                    title: Text(post["user"]),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post["content"]),
                        if (status == "approved")
                          Row(
                            children: [
                              TextButton(
                                onPressed: () =>
                                    _showLikesDialog(post["likes"]),
                                child: Text("👍 ${post["likes"].length} Likes"),
                              ),
                              TextButton(
                                onPressed: () => _showCommentsDialog(
                                    post["comments"], post["id"]),
                                child: Text(
                                    "💬 ${post["comments"].length} Comments"),
                              ),
                            ],
                          ),
                      ],
                    ),
                    onTap: () {
                      if (status == "pending") {
                        _showPendingReviewDialog(post);
                      } else {
                        _showDeletePostDialog(post["id"]);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPendingReviewDialog(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: EdgeInsets.all(16),
            width: 400,
            height: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Review Post", style: TextStyle(fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue)),
                SizedBox(height: 12),
                Text(post["content"], style: TextStyle(fontSize: 16)),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _updatePostStatus(post["id"], "approved");
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      child: Text("Approve"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _updatePostStatus(post["id"], "rejected");
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red),
                      child: Text("Reject"),
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: EdgeInsets.all(16),
            width: 300,
            height: 180,
            child: Column(
              children: [
                Text("Delete Post?", style: TextStyle(fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red)),
                SizedBox(height: 16),
                Text("Are you sure you want to delete this post?",
                    textAlign: TextAlign.center),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _deletePost(postId);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red),
                      child: Text("Delete"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey),
                      child: Text("Cancel"),
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

  void _showLikesDialog(List<String> likes) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: EdgeInsets.all(16),
            width: 300,
            height: likes.isNotEmpty ? 300 : 150,
            child: Column(
              children: [
                Text("Liked by", style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Expanded(
                  child: likes.isNotEmpty
                      ? ListView.builder(
                    itemCount: likes.length,
                    itemBuilder: (context, index) =>
                        ListTile(
                          leading: Icon(Icons.person, color: Colors.blue),
                          title: Text(likes[index]),
                        ),
                  )
                      : Center(child: Text("No likes yet")),
                ),
                SizedBox(height: 10),
                ElevatedButton(onPressed: () => Navigator.pop(context),
                    child: Text("Close")),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCommentsDialog(List<Map<String, String>> comments, String postId) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: EdgeInsets.all(16),
                width: 400,
                height: 400,
                child: Column(
                  children: [
                    Text("Comments", style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Expanded(
                      child: comments.isNotEmpty
                          ? ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          var comment = comments[index];
                          return ListTile(
                            leading: Icon(Icons.person, color: Colors.blue),
                            title: Text(comment["user"]!),
                            subtitle: Text(comment["comment"]!),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  comments.removeAt(index);
                                });
                                // Update the main post list
                                setState(() {
                                  posts.firstWhere((post) =>
                                  post["id"] == postId)["comments"] = comments;
                                });
                              },
                            ),
                          );
                        },
                      )
                          : Center(child: Text("No comments yet")),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(onPressed: () => Navigator.pop(context),
                        child: Text("Close")),
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
