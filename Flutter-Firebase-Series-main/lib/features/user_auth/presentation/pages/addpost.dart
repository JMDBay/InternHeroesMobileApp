import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/knowledgeresourcepage.dart';
import 'package:image_picker/image_picker.dart';

class AddPostPage extends StatefulWidget {
  @override
  _AddPostPageState createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<String> selectedTags = [];
  List<File> _images = [];

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Post'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => KnowledgeResource()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Text('Tags:'),
                  SizedBox(width: 20),
                  DropdownButton<String>(
                    hint: Text(selectedTags.isNotEmpty ? 'Add Another Tag' : 'Add a Tag'),
                    value: null,
                    onChanged: (String? newValue) {
                      setState(() {
                        if (newValue != null) {
                          if (!selectedTags.contains(newValue)) {
                            selectedTags.add(newValue);
                          }
                        }
                      });
                    },
                    items: allTags.map((String tag) {
                      return DropdownMenuItem<String>(
                        value: tag,
                        child: Text(tag),
                      );
                    }).toList(),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Wrap(
                spacing: 8.0,
                children: List.generate(selectedTags.length, (index) {
                  final tag = selectedTags[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTags.remove(tag);
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(tag, style: TextStyle(fontSize: 12)),
                          SizedBox(width: 4),
                          IconButton(
                            iconSize: 18,
                            icon: Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                selectedTags.remove(tag);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 20),
              _buildImagePreview(),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Select Image'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _addPost(context),
                child: Text('Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_images.isNotEmpty) {
      return SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _images.length,
          itemBuilder: (context, index) {
            return Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Image.file(_images[index]),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _images.removeAt(index);
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    } else {
      return SizedBox();
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedImage != null) {
        _images.add(File(pickedImage.path));
      } else {
        print('No image selected.');
      }
    });
  }

  void _addPost(BuildContext context) async {
    String title = _titleController.text;
    String description = _descriptionController.text;

    if (title.isNotEmpty && description.isNotEmpty) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userId = user.uid;

        // Retrieve the user's display name
        String? userName = user.displayName;

        List<String?> imageUrls = [];
        for (File image in _images) {
          final imageStorageRef = FirebaseStorage.instance.ref().child('images').child('${DateTime.now()}.jpg');
          await imageStorageRef.putFile(image);
          final imageUrl = await imageStorageRef.getDownloadURL();
          imageUrls.add(imageUrl);
        }

        await FirebaseFirestore.instance.collection('knowledge_resource').add({
          'title': title,
          'description': description,
          'userId': userId, // Change 'userId' to 'uid'
          'userName': userName,
          'datePosted': Timestamp.now(),
          'tags': selectedTags,
          'imageUrls': imageUrls,
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => KnowledgeResource()),
        );
      } else {
        print('User is not authenticated.');
      }
    }
  }
}
