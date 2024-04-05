import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path/path.dart' as Path;
import 'home_page.dart';

class AdditionalInformationPage extends StatefulWidget {
  const AdditionalInformationPage({Key? key}) : super(key: key);

  @override
  _AdditionalInformationPageState createState() =>
      _AdditionalInformationPageState();
}

class _AdditionalInformationPageState
    extends State<AdditionalInformationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  TextEditingController _phoneNumberController = TextEditingController();
  DateTime? _selectedDate;
  File? _selectedImage;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _prepopulateTextFields();
  }

  void _prepopulateTextFields() async {
    // Get current user
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        // Fetch user data from Firestore
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userData.exists) {
          Map<String, dynamic>? userDataMap =
          userData.data() as Map<String, dynamic>?;

          setState(() {
            _phoneNumberController.text = userDataMap?['phoneNumber'] ?? '';
            // Check if birthday exists in user data
            if (userDataMap?['birthday'] != null) {
              _selectedDate = DateTime.parse(userDataMap?['birthday']);
            }
            // Check if profile image URL exists in user data
            // Assuming you're storing the profile image as a URL in Firestore
            if (userDataMap?['profileImageUrl'] != null) {
              // Load the profile image using the URL
              // This part can be implemented based on your method of storing images
              // For example, using a package like cached_network_image
              // _selectedImage = File(userDataMap?['profileImageUrl']);
            }
          });
        } else {
          print('Document does not exist in Firestore.');
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

  Widget _buildFormContainer({
    required TextEditingController controller,
    required String title,
    required String hintText,
    required bool isPasswordField,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        TextFormField(
          controller: controller,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly, // Allow only digits
            LengthLimitingTextInputFormatter(11),   // Limit length to 11 digits
          ],
          decoration: InputDecoration(
            hintText: hintText,
          ),
          obscureText: isPasswordField,
          keyboardType: keyboardType,
          validator: (value) {
            if (title == "Phone Number" && (value == null || value.length != 11)) {
              return 'Please enter a valid 11-digit phone number';
            }
            return null;
          },
        ),
        SizedBox(height: 20),
      ],
    );
  }


  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _selectProfileImage() async {
    final XFile? pickedImage =
    await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  void _selectPredefinedProfileImage(String imageName) {
    setState(() {
      _selectedImage = File('assets/images/$imageName');
    });
  }

  Future<void> _uploadImageToFirebaseStorage(File imageFile) async {
    try {
      String fileName = Path.basename(imageFile.path);
      firebase_storage.Reference firebaseStorageRef =
      firebase_storage.FirebaseStorage.instance.ref().child(fileName);
      firebase_storage.UploadTask uploadTask =
      firebaseStorageRef.putFile(imageFile);
      await uploadTask.whenComplete(() async {
        String downloadURL = await firebaseStorageRef.getDownloadURL();
        // Update profile image URL in Firestore
        // Get current user
        User? user = _auth.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            "profileImageUrl": downloadURL,
          });
        }
      });
    } catch (e) {
      print('Error uploading image to Firebase Storage: $e');
    }
  }

  void _saveAdditionalInformation() async {
    // Check if all fields are filled
    if (_phoneNumberController.text.isEmpty ||
        _selectedDate == null ||
        _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill all fields'),
        backgroundColor: Colors.yellow[800],
      ));
      return;
    }

    // Check if the phone number is valid
    if (_phoneNumberController.text.length != 11 ||
        !RegExp(r'^[0-9]+$').hasMatch(_phoneNumberController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter a valid 11-digit phone number'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() {
      isSaving = true;
    });

    String phoneNumber = _phoneNumberController.text;
    String birthday = DateFormat('yyyy-MM-dd').format(_selectedDate!);

    // Get current user
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        // Upload profile image to Firebase Storage
        await _uploadImageToFirebaseStorage(_selectedImage!);

        // Update additional information in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          "phoneNumber": phoneNumber,
          "birthday": birthday,
        });

        setState(() {
          isSaving = false;
        });

        // Check if professional information is filled
        if (await _checkProfessionalInfoFilled(user.uid)) {
          // Navigate to Home Page if both additional and professional information are filled
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) =>  ProfileScreen(uid: FirebaseAuth.instance.currentUser!.uid)),

          );
        } else {
          // Navigate to the Professional Information Page if not filled
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ProfessionalInformationPage()),
          );
        }

      } catch (e) {
        print('Error saving additional information: $e');
        setState(() {
          isSaving = false;
        });
      }
    } else {
      print("User not found");
      setState(() {
        isSaving = false;
      });
    }
  }


  Future<bool> _checkProfessionalInfoFilled(String userId) async {
    try {
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userData.exists) {
        Map<String, dynamic>? userDataMap =
        userData.data() as Map<String, dynamic>?;

        return (userDataMap?['university'] != null &&
            userDataMap?['yearAndCourse'] != null &&
            userDataMap?['ojtCoordinatorEmail'] != null &&
            userDataMap?['requiredHours'] != null &&
            userDataMap?['careerPath'] != null);
      }
    } catch (e) {
      print('Error checking educational information: $e');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Additional Information'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormContainer(
              controller: _phoneNumberController,
              title: "Phone Number",
              hintText: "Enter your mobile number e.g. (09991231234)",
              isPasswordField: false,
              keyboardType: TextInputType.phone,
            ),
            InkWell(
              onTap: () {
                _selectDate(context);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Birthday',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  InputDecorator(
                    decoration: InputDecoration(
                      hintText: 'Select Birthday',
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          _selectedDate != null
                              ? '${_selectedDate!.toLocal()}'.split(' ')[0]
                              : 'Select Birthday',
                          style: TextStyle(
                            fontSize: 15,
                          ),
                        ),
                        Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),
            Text(
              'Choose a Profile Image:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            SizedBox(height: 10),
            Center(
              child: GestureDetector(
                onTap: _selectProfileImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : AssetImage('assets/default_profile_image.jpg')
                  as ImageProvider,
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () =>
                      _selectPredefinedProfileImage('superhero.jpg'),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage:
                    AssetImage('assets/images/superhero.jpg'),
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      _selectPredefinedProfileImage('superhero3.jpg'),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage:
                    AssetImage('assets/images/superhero3.jpg'),
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      _selectPredefinedProfileImage('superhero4.jpg'),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage:
                    AssetImage('assets/images/superhero4.jpg'),
                  ),
                ),
              ],
            ),

            SizedBox(height: 30),
            Center(
              child: Container(
                width: 350,
                height: 45,
                child: ElevatedButton(
                  onPressed: () {
                    _saveAdditionalInformation(); // Save additional information before navigating
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Next',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfessionalInformationPage extends StatefulWidget {
  const ProfessionalInformationPage({Key? key}) : super(key: key);

  @override
  _ProfessionalInformationPageState createState() =>
      _ProfessionalInformationPageState();
}

class _ProfessionalInformationPageState
    extends State<ProfessionalInformationPage> {
  final TextEditingController _universityController =
  TextEditingController();
  final TextEditingController _yearAndCourseController =
  TextEditingController();
  final TextEditingController _ojtCoordinatorEmailController =
  TextEditingController();
  final TextEditingController _requiredHoursController =
  TextEditingController();

  List<String> careerPath = [];
  bool isSaving = false;

  final List<String> allCareerPaths = [
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

  @override
  void initState() {
    super.initState();
    _prepopulateProfessionalInformationFields();
  }

  void _prepopulateProfessionalInformationFields() async {
    // Get current user
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Fetch professional information data from Firestore
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userData.exists) {
          Map<String, dynamic>? userDataMap =
          userData.data() as Map<String, dynamic>?;

          setState(() {
            _universityController.text = userDataMap?['university'] ?? '';
            _yearAndCourseController.text =
                userDataMap?['yearAndCourse'] ?? '';
            _ojtCoordinatorEmailController.text =
                userDataMap?['ojtCoordinatorEmail'] ?? '';
            _requiredHoursController.text =
                userDataMap?['requiredHours'] ?? '';
            careerPath =
            List<String>.from(userDataMap?['careerPath'] ?? []);
          });
        } else {
          print('Document does not exist in Firestore.');
        }
      } catch (e) {
        print('Error fetching professional information data: $e');
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Educational Information'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            TextFormField(
              controller: _universityController,
              decoration: InputDecoration(
                hintText: "University",
              ),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _yearAndCourseController,
              decoration: InputDecoration(
                hintText: "Year and Course",
              ),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _ojtCoordinatorEmailController,
              decoration: InputDecoration(
                hintText: "OJT Coordinator Email",
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _requiredHoursController,
              decoration: InputDecoration(
                hintText: "Required Hours",
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            Text(
              "Choose your career path (Maximum of 3):",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Wrap(
              children: allCareerPaths
                  .map((career) => _buildCareerPathButton(career))
                  .toList(),
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _saveProfessionalInformation();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isSaving
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  'Save',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfessionalInformation() async {
    // Check if all fields are filled, ignoring pre-filled texts
    if ((_universityController.text.isEmpty ||
        _universityController.text == 'University') ||
        (_yearAndCourseController.text.isEmpty ||
            _yearAndCourseController.text == 'Year and Course') ||
        (_ojtCoordinatorEmailController.text.isEmpty ||
            _ojtCoordinatorEmailController.text == 'OJT Coordinator Email') ||
        (_requiredHoursController.text.isEmpty ||
            _requiredHoursController.text == 'Required Hours') ||
        careerPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill all fields'),
        backgroundColor: Colors.yellow[800],
      ));
      return;
    }

    setState(() {
      isSaving = true;
    });

    String university = _universityController.text;
    String yearAndCourse = _yearAndCourseController.text;
    String ojtCoordinatorEmail = _ojtCoordinatorEmailController.text;
    String requiredHours = _requiredHoursController.text;

    // Get current user
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Update professional information in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          "university": university,
          "yearAndCourse": yearAndCourse,
          "ojtCoordinatorEmail": ojtCoordinatorEmail,
          "requiredHours": requiredHours,
          "careerPath": careerPath, // Use the careerPath list directly
        });

        setState(() {
          isSaving = false;
        });

        // Check if additional information is filled
        if (await _checkAdditionalInfoFilled(user.uid)) {
          // Navigate to Home Page if both additional and professional information are filled
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen(uid: FirebaseAuth.instance.currentUser!.uid)),
          );
        } else {
          // Navigate to the Additional Information Page if not filled
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdditionalInformationPage()),
          );
        }

      } catch (e) {
        print('Error saving professional information: $e');
        setState(() {
          isSaving = false;
        });
      }
    } else {
      print("User not found");
      setState(() {
        isSaving = false;
      });
    }
  }

  Future<bool> _checkAdditionalInfoFilled(String userId) async {
    try {
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userData.exists) {
        Map<String, dynamic>? userDataMap =
        userData.data() as Map<String, dynamic>?;

        return (userDataMap?['phoneNumber'] != null &&
            userDataMap?['birthday'] != null &&
            userDataMap?['profileImageUrl'] != null);
      }
    } catch (e) {
      print('Error checking additional information: $e');
    }
    return false;
  }
}
