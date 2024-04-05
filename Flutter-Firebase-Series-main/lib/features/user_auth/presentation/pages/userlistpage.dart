import 'package:InternHeroes/features/user_auth/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/chat_page.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/knowledgeresourcepage.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/calendar.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/addpost.dart';
import 'package:InternHeroes/features/user_auth/presentation/widgets/bottom_navbar.dart';

class UserListPage extends StatefulWidget {
  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  late TextEditingController _searchController;
  late Stream<QuerySnapshot> _usersStream;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _usersStream = FirebaseFirestore.instance.collection('users').snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chats',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Making the title text bold
          ),
        ),
        centerTitle: true, // Centering the title text
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for users...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _usersStream = FirebaseFirestore.instance
                      .collection('users')
                      .where('name', isGreaterThanOrEqualTo: value)
                      .snapshots();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _usersStream,
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text('No users available'),
                  );
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var user = snapshot.data!.docs[index];
                      String? profileImageUrl = user['profileImageUrl'];

                      // Convert careerPath list to string
                      List<dynamic>? careerPathList = user['careerPath'];
                      String careerPath = careerPathList != null ? careerPathList.join(', ') : 'Career path not available';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: profileImageUrl != null
                              ? NetworkImage(profileImageUrl)
                              : AssetImage('assets/superhero.jpg') as ImageProvider<Object>,
                        ),
                        title: Text(user['name'] ?? 'Name not available'),
                        subtitle: Text(careerPath),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                recipientId: user.id,
                                recipientName: user['name'],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 1,
        onItemTapped: (index) {
          _handleNavigation(context, index);
        },
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => KnowledgeResource()),
        );
        break;
      case 1:
        break; // Stay on the current page (UserListPage)
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen(uid: FirebaseAuth.instance.currentUser!.uid)),
        );
        break;
    }
  }
}
