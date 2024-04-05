import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/addpost.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/knowledgeresourcepage.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/userlistpage.dart';
import 'calendar.dart';
import 'editableprofilescreen.dart';
import 'dart:typed_data';
import 'package:InternHeroes/features/user_auth/presentation/widgets/bottom_navbar.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/postdetailspage.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  final String placeholderImageUrl = 'assets/superhero.jpg';
  const ProfileScreen({Key? key, required this.uid}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _image;

  final picker = ImagePicker();

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> _uploadImageToFirebase() async {
    if (_image == null) return;

    try {
      print('Starting image upload...');
      // Read the file as bytes
      List<int> imageBytes = await _image!.readAsBytes();

      // Convert List<int> to Uint8List
      Uint8List uint8List = Uint8List.fromList(imageBytes);

      Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('user_profile_images/${widget.uid}.jpg');

      // Upload the image data as bytes
      await storageReference.putData(uint8List);

      // Get the download URL for the uploaded image
      String downloadURL = await storageReference.getDownloadURL();

      // Update the user document in Firestore with the download URL
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({
        'profileImageUrl': downloadURL,
      });

      print('Image uploaded to Firebase Storage and URL saved to Firestore.');
    } catch (e) {
      print('Error uploading image to Firebase Storage: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: <Widget>[
            Container(
              constraints: BoxConstraints.expand(height: 50),
              child: TabBar(
                tabs: [
                  Tab(text: 'Details'),
                  Tab(text: 'Posts'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // User Details Tab
                  _buildDetailsTab(),
                  // Posts Tab
                  _buildPostsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 4, // Profile screen is selected by default
        onItemTapped: (index) {
          // Handle navigation based on index
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => KnowledgeResource()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => UserListPage()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AddPostPage()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Calendar()),
              );
              break;
            case 4:
            // Profile screen is already open, do nothing
              break;
          }
        },
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .snapshots(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text('User data not found for UID: ${widget.uid}'),
            );
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: getImage,
                  child: CircleAvatar(
                    radius: 70,
                    backgroundImage: _image != null
                        ? FileImage(_image!)
                        : userData['profileImageUrl'] != null
                        ? NetworkImage(
                        userData['profileImageUrl'] as String)
                        : null as ImageProvider<Object>?,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              buildProfileItem('Name', userData['name']),
              buildProfileItem('Email', userData['email']),
              buildProfileItem('Phone Number', userData['phoneNumber']),
              buildProfileItem('Birthday', userData['birthday']),
              buildProfileItem('University', userData['university']),
              buildProfileItem('Year and Course', userData['yearAndCourse']),
              buildProfileItem(
                  'OJT Coordinator Email', userData['ojtCoordinatorEmail']),
              buildProfileItem('Required Hours', userData['requiredHours']),
              buildProfileItem('Career Path', userData['careerPath']),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _uploadImageToFirebase();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              EditableProfileScreen(uid: widget.uid)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(15),
                    backgroundColor: Colors.yellow[800],
                  ),
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPostsTab() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('knowledge_resource')
          .where('userId', isEqualTo: widget.uid) // Filter posts by user ID
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No posts available'),
          );
        } else {
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var post = snapshot.data!.docs[index];
              return GestureDetector(
                onTap: () {
                  _viewPostDetails(context, post);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post['title'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: (post['tags'] as List<dynamic>)
                                .map<Widget>((tag) {
                              return Chip(
                                label: Text(tag),
                                backgroundColor: Colors.grey[300],
                                labelStyle: TextStyle(
                                  fontSize: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 10),
                          // Display multiple images if available
                          if (post['imageUrls'] != null && (post['imageUrls'] as List).isNotEmpty)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: (post['imageUrls'] as List<dynamic>).map<Widget>((imageUrl) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Image.network(
                                      imageUrl,
                                      width: 200,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          SizedBox(height: 5),
                          Row(
                            children: [
                              Text(
                                'Posted by: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              FutureBuilder(
                                future: _getPostUserName(post),
                                builder: (context, AsyncSnapshot<String> userNameSnapshot) {
                                  if (userNameSnapshot.connectionState == ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  } else if (userNameSnapshot.hasData) {
                                    return Text(
                                      userNameSnapshot.data!,
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    );
                                  } else {
                                    return Text(
                                      'Unknown',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              _showDeleteConfirmationDialog(post.id); // Show delete confirmation dialog
                            },
                            child: Text('Delete Post'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  Future<String> _getPostUserName(DocumentSnapshot post) async {
    final userId = post['userId'];
    final userSnapshot = await FirebaseFirestore.instance.collection('users')
        .doc(userId)
        .get();
    return userSnapshot['name'];
  }

  void _showDeleteConfirmationDialog(String postId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Delete"),
          content: Text("Are you sure you want to delete this post?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _deletePost(postId); // Delete the post
              },
              child: Text(
                "Delete",
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePost(String postId) async {
    try {
      await FirebaseFirestore.instance
          .collection('knowledge_resource')
          .doc(postId)
          .delete();
      print('Post deleted successfully');
    } catch (e) {
      print('Error deleting post: $e');
    }
  }

  Widget buildProfileItem(String title, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 5),
        if (title == 'Career Path' && value is List<dynamic>) // Check if the value is a list
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: value.map((item) {
              return Row(
                children: [
                  Text(
                    '$item',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(width: 10), // Add spacing between items
                  Text(
                    '|',
                    style: TextStyle(fontSize: 16, color: Colors.grey), // Separator style
                  ),
                  SizedBox(width: 10), // Add spacing between items
                ],
              );
            }).toList(),
          ),
        if (title != 'Career Path') // If it's not career path, treat it as a regular string
          Text(
            value ?? '',
            style: TextStyle(fontSize: 16),
          ),
        const SizedBox(height: 10),
        Divider(
          color: Colors.grey[300],
          thickness: 1,
        ),
      ],
    );
  }

  // Inside your logout function where you sign out the user
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Logout"),
          content: Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await FirebaseAuth.instance.signOut();
                  // Clear cached user data
                  _clearCachedUserData();
                  Navigator.pushReplacementNamed(context, '/login');
                } catch (e) {
                  print("Error logging out: $e");
                }
              },
              child: Text(
                "Yes",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ButtonStyle(
                backgroundColor:
                MaterialStateProperty.all<Color>(Colors.yellow[800]!),
                padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                    EdgeInsets.all(15)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "No",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
                padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                    EdgeInsets.all(15)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.black),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to clear cached user data
  void _clearCachedUserData() {
    setState(() {
      _image = null; // Clear the profile picture
    });
  }

  // Function to navigate to the post details page
  void _viewPostDetails(BuildContext context, DocumentSnapshot post) {
    // Navigate to the post details page, you can replace `PostDetailsPage` with your actual page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailsPage(post: post),
      ),
    );
  }
}
