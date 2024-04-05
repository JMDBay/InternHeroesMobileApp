import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/userlistpage.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/knowledgeresourcepage.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/calendar.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/addpost.dart';
import 'package:InternHeroes/features/user_auth/presentation/widgets/bottom_navbar.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/postdetailspage.dart';

class OtherProfileScreen extends StatelessWidget {
  final String uid;

  const OtherProfileScreen({Key? key, required this.uid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Two tabs: Details and Posts
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            tabs: [
              Tab(text: 'Details'),
              Tab(text: 'Posts'),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Details Tab
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
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
                    child: Text('User data not found for UID: $uid'),
                  );
                }

                var userData = snapshot.data!.data() as Map<String, dynamic>;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 70,
                          backgroundImage: userData['profileImageUrl'] != null
                              ? NetworkImage(userData['profileImageUrl'] as String)
                              : AssetImage('assets/default_profile_image.jpg') as ImageProvider<Object>?,
                        ),
                      ),
                      const SizedBox(height: 20),
                      buildProfileItem('Name', userData['name'] as String?),
                      buildProfileItem('Email', userData['email'] as String?),
                      buildProfileItem('Phone Number', userData['phoneNumber'] as String?),
                      buildProfileItem('Birthday', userData['birthday'] as String?),
                      buildProfileItem('University', userData['university'] as String?),
                      buildProfileItem('Year and Course', userData['yearAndCourse'] as String?),
                      buildProfileItem('OJT Coordinator Email', userData['ojtCoordinatorEmail'] as String?),
                      buildProfileItem('Required Hours', userData['requiredHours'] as String?),
                      buildProfileItem('Career Path', (userData['careerPath'] as List<dynamic>).join(', ')),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
            // Posts Tab
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('knowledge_resource')
                  .where('userId', isEqualTo: uid) // Fetch posts where userId matches viewed user's uid
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
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
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text('No posts found for this user.'),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var post = snapshot.data!.docs[index];
                    var postData = post.data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: GestureDetector(
                        onTap: () {
                          _viewPostDetails(context, post);
                        },
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: InkWell(
                            onTap: () {
                              _viewPostDetails(context, post);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    postData['title'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    children: (postData['tags'] as List<dynamic>)
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
                                  if (postData['imageUrls'] != null)
                                    SizedBox(
                                      height: 200,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: postData['imageUrls'].length,
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 8.0),
                                            child: Image.network(
                                              postData['imageUrls'][index],
                                              width: 200,
                                              height: 200,
                                              fit: BoxFit.cover,
                                            ),
                                          );
                                        },
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
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          selectedIndex: 1, // Profile screen is selected by default
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
      ),
    );
  }

  Widget buildProfileItem(String title, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 5),
        Text(
          value ?? 'N/A', // Use 'N/A' if value is null
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
                backgroundColor: MaterialStateProperty.all<Color>(Colors.yellow[800]!),
                padding: MaterialStateProperty.all<EdgeInsetsGeometry>(EdgeInsets.all(15)),
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
                padding: MaterialStateProperty.all<EdgeInsetsGeometry>(EdgeInsets.all(15)),
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

  void _clearCachedUserData() {
    // No cached user data to clear in this case
  }

  Future<String> _getPostUserName(DocumentSnapshot post) async {
    final userId = post['userId'];
    final userSnapshot = await FirebaseFirestore.instance.collection('users')
        .doc(userId)
        .get();
    return userSnapshot['name'];
  }

  void _viewPostDetails(BuildContext context, DocumentSnapshot post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailsPage(post: post),
      ),
    );
  }
}
