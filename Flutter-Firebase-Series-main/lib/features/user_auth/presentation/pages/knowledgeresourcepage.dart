import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/home_page.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/addpost.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/calendar.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/postdetailspage.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/userlistpage.dart';
import 'package:InternHeroes/features/user_auth/presentation/widgets/bottom_navbar.dart';

class KnowledgeResource extends StatefulWidget {
  // Define the allTags list as a class variable
  final List<String> allTags = [
    "UI/UX",
    "Vercel",
    "Webflow",
    "Flutter",
    "Programming",
    "Database Manager",
    "System Administrator",
    "Quality Assurance",
    "Service Assurance",
    // Add more tags as needed
  ];

  @override
  _KnowledgeResourceState createState() => _KnowledgeResourceState();
}

class _KnowledgeResourceState extends State<KnowledgeResource> {
  late TextEditingController _searchController;
  late Query _postsQuery;
  late Stream<QuerySnapshot> _postsStream;
  late List<String> _selectedTags; // Define _selectedTags here

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _postsQuery = FirebaseFirestore.instance.collection('knowledge_resource');
    _postsStream = _postsQuery.snapshots();
    _selectedTags = []; // Initialize selected tags list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Knowledge Resource',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Making the title text bold
          ),
        ),
        centerTitle: true, // Centering the title text
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                      border: Border.all(color: Colors.grey), // Add border
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by title',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () {
                            _searchPosts(_searchController.text);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.filter_list),
                  onPressed: () {
                    _showFilterDialog(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _postsStream,
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text('No knowledge resources available'),
                  );
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          children: [
                            Divider( // Add a divider above the first post item
                              color: Colors.grey,
                              thickness: 1,
                            ),
                            _buildPostItem(snapshot.data!.docs[index]),
                          ],
                        );
                      }
                      return _buildPostItem(snapshot.data!.docs[index]);
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 0,
        onItemTapped: (index) {
          _handleNavigation(context, index);
        },
      ),
    );
  }

  Widget _buildPostItem(DocumentSnapshot post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: GestureDetector(
            onTap: () {
              _viewPostDetails(context, post);
            },
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
                  children: _buildTagChips(post['tags']),
                ),
                SizedBox(height: 10),
                if (post['imageUrls'] != null && post['imageUrls'].isNotEmpty) // Check if imageUrls is not empty
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: post['imageUrls'].map<Widget>((imageUrl) {
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
                _buildPostedByRow(post),
              ],
            ),
          ),
        ),
        Divider(
          color: Colors.grey,
          thickness: 1,
        ),
      ],
    );
  }


  List<Widget> _buildTagChips(List<dynamic> tags) {
    return tags.map<Widget>((tag) {
      if (tag is String) {
        return Chip(
          label: Text(
            tag,
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.yellow[800],
          labelStyle: TextStyle(
            fontSize: 10,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.transparent),
          ),
        );
      } else {
        return Container(); // Handle non-string tags
      }
    }).toList();
  }

  Widget _buildPostedByRow(DocumentSnapshot post) {
    return Row(
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
    );
  }




  Future<String> _getPostUserName(DocumentSnapshot post) async {
    final userId = post['userId'];
    final userSnapshot = await FirebaseFirestore.instance.collection('users')
        .doc(userId)
        .get();
    return userSnapshot['name'];
  }

  void _searchPosts(String query) {
    setState(() {
      Query filteredQuery = FirebaseFirestore.instance.collection(
          'knowledge_resource');

      if (query.isNotEmpty) {
        filteredQuery =
            filteredQuery.where('title', isGreaterThanOrEqualTo: query).where(
                'title', isLessThan: query + 'z');
      }

      if (_selectedTags.isNotEmpty) {
        filteredQuery =
            filteredQuery.where('tags', arrayContainsAny: _selectedTags);
      }

      _postsQuery = filteredQuery;
      _postsStream = _postsQuery.snapshots();
    });
  }

  void _viewPostDetails(BuildContext context, DocumentSnapshot post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailsPage(post: post),
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>
              ProfileScreen(uid: FirebaseAuth.instance.currentUser!.uid)),
        );
        break;
    }
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Filter by Tags'),
              content: SingleChildScrollView(
                child: Column(
                  children: widget.allTags.map((tag) {
                    bool isSelected = _selectedTags.contains(tag);
                    return TextButton(
                      onPressed: () {
                        setState(() {
                          if (isSelected) {
                            _selectedTags.remove(tag);
                          } else {
                            _selectedTags.add(tag);
                          }
                        });
                        // Update isSelected value immediately
                        isSelected = !isSelected;
                        _searchPosts(_searchController.text); // Update posts based on selected tags
                      },
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          isSelected ? Colors.blue : Colors.grey[300]!,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

}
