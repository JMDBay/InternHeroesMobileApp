import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostDetailsPage extends StatelessWidget {
  final DocumentSnapshot post;

  const PostDetailsPage({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post['title'] ?? 'Title not available',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: (post['tags'] as List<dynamic>).map<Widget>((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: Colors.grey[300],
                    labelStyle: TextStyle(
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              Text(
                post['description'] ?? 'Description not available',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 20),
              // Display multiple images if available
              if (post['imageUrls'] != null && (post['imageUrls'] as List).isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: (post['imageUrls'] as List<dynamic>).map<Widget>((imageUrl) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            _showImageDialog(context, imageUrl);
                          },
                          child: Image.network(
                            imageUrl,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              SizedBox(height: 20),
              FutureBuilder(
                future: _getPostUserName(post),
                builder: (context, AsyncSnapshot<String> userNameSnapshot) {
                  if (userNameSnapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (userNameSnapshot.hasData) {
                    return Text(
                      'Posted by: ${userNameSnapshot.data}',
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  } else {
                    return Text(
                      'Posted by: Unknown',
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  }
                },
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Navigate back to the previous screen
                    },
                    child: Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _getPostUserName(DocumentSnapshot post) async {
    final userId = post['userId'];
    final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userSnapshot['name'];
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Image.network(imageUrl),
      ),
    );
  }
}
