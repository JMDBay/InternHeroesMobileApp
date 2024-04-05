import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class EditableProfileScreen extends StatefulWidget {
  final String uid;

  const EditableProfileScreen({Key? key, required this.uid}) : super(key: key);

  @override
  _EditableProfileScreenState createState() => _EditableProfileScreenState();
}

class _EditableProfileScreenState extends State<EditableProfileScreen> {
  late TextEditingController _phoneNumberController;
  late TextEditingController _ojtCoordinatorEmailController;
  late TextEditingController _requiredHoursController;
  List<String> careerPath = [];
  File? _image;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _phoneNumberController = TextEditingController();
    _ojtCoordinatorEmailController = TextEditingController();
    _requiredHoursController = TextEditingController();
    _prepopulateFields();
  }

  void _prepopulateFields() async {
    try {
      DocumentSnapshot userData =
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      if (userData.exists) {
        Map<String, dynamic>? userDataMap = userData.data() as Map<String, dynamic>?;

        setState(() {
          _phoneNumberController.text = userDataMap?['phoneNumber'] ?? '';
          _ojtCoordinatorEmailController.text = userDataMap?['ojtCoordinatorEmail'] ?? '';
          _requiredHoursController.text = userDataMap?['requiredHours'] ?? '';
          if (userDataMap?['careerPath'] != null) {
            careerPath = List<String>.from(userDataMap?['careerPath']);
          }
        });
      } else {
        print('Document does not exist in Firestore.');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Widget _buildCareerPathButton(String career) {
    bool isSelected = careerPath.contains(career);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            careerPath.remove(career);
          } else {
            if (careerPath.length < 3) {
              careerPath.add(career);
            }
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.yellow[800] : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          career,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Future<void> _getImage() async {
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
      List<int> imageBytes = await _image!.readAsBytes();
      Uint8List uint8List = Uint8List.fromList(imageBytes);

      Reference storageReference =
      FirebaseStorage.instance.ref().child('user_profile_images/${widget.uid}.jpg');

      await storageReference.putData(uint8List);
      String downloadURL = await storageReference.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
        'profileImageUrl': downloadURL,
      });

      print('Image uploaded to Firebase Storage and URL saved to Firestore.');
    } catch (e) {
      print('Error uploading image to Firebase Storage: $e');
    }
  }

  void _saveChanges() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
        'phoneNumber': _phoneNumberController.text,
        'ojtCoordinatorEmail': _ojtCoordinatorEmailController.text,
        'requiredHours': _requiredHoursController.text,
        'careerPath': careerPath,
      });

      await _uploadImageToFirebase();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Changes saved successfully'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.yellow[800],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving changes: $e'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.uid).snapshots(),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _getImage,
                  child: Center(
                    child: CircleAvatar(
                      radius: 70,
                      backgroundImage: _image != null
                          ? FileImage(_image!)
                          : userData['profileImageUrl'] != null
                          ? NetworkImage(userData['profileImageUrl'] as String)
                          : null as ImageProvider<Object>?,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                buildProfileItem('Name', userData['name'] ?? ''),
                buildProfileItem('Email', userData['email'] ?? ''),
                buildEditableProfileItem('Phone Number', _phoneNumberController),
                buildProfileItem('Birthday', userData['birthday'] ?? ''),
                buildProfileItem('University', userData['university'] ?? ''),
                buildProfileItem('Year and Course', userData['yearAndCourse'] ?? ''),
                buildEditableProfileItem('OJT Coordinator Email', _ojtCoordinatorEmailController),
                buildEditableProfileItem('Required Hours', _requiredHoursController),
                buildCareerPathSelection(),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(15),
                      backgroundColor: Colors.yellow[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Save Changes',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildProfileItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        Divider(
          color: Colors.grey[300],
          thickness: 1,
        ),
      ],
    );
  }

  Widget buildEditableProfileItem(String title, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 5),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: title,
              border: InputBorder.none,
            ),
          ),
        ),
        SizedBox(height: 10),
        Divider(
          color: Colors.grey[300],
          thickness: 1,
        ),
      ],
    );
  }

  Widget buildCareerPathSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Text(
          'Career Path',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 5),
        Wrap(
          children: allCareerPaths.map((career) => _buildCareerPathButton(career)).toList(),
        ),
        SizedBox(height: 10),
        Divider(
          color: Colors.grey[300],
          thickness: 1,
        ),
      ],
    );
  }
}

List<String> allCareerPaths = [
  "UI/UX",
  "Vercel",
  "Webflow",
  "Flutter",
  "Programming",
  "Database Manager",
  "System Administrator",
  "Quality Assurance",
  "Service Assurance",
];
