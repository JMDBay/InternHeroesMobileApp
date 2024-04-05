import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:InternHeroes/features/user_auth/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/additionalinformationpage.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/sign_up_page.dart';
import 'package:InternHeroes/global/common/toast.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuthService _authService = FirebaseAuthService();

  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  bool isLoggingIn = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Welcome to",
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                ),
                Image.asset(
                  'assets/images/internheroeslogo.png',
                  height: 100,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    "Unleash the powers within you.",
                    style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 5),
                      child: Text(
                        "Email",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 350,
                        child: TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: "Enter your email",
                            border: UnderlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: EdgeInsets.only(top: 20, left: 5),
                      child: Text(
                        "Password",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 350,
                        child: TextField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            hintText: "Enter your password",
                            border: UnderlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                GestureDetector(
                  onTap: () {
                    _login();
                  },
                  child: Container(
                    width: 350,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.yellow[800],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: isLoggingIn
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                        "Login",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    _showForgotPasswordDialog();
                  },
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: Colors.yellow[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account?"),
                      SizedBox(width: 5),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignUpPage(),
                            ),
                          );
                        },
                        child: Text(
                          "Sign Up",
                          style: TextStyle(
                            color: Colors.yellow[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      // Show snackbar if any field is empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All fields are required.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.yellow[800], // Set background color
        ),
      );
      return;
    }

    setState(() {
      isLoggingIn = true;
    });

    try {
      User? user = await _authService.logIn(email, password);

      setState(() {
        isLoggingIn = false;
      });

      if (user != null) {
        print("User is successfully logged in: ${user.uid}");

        // Check if additional information is filled
        _checkAdditionalInformation(user);
      } else {
        print("Failed to login");
        // Show snackbar for invalid email or password
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid email or password'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.yellow[800], // Set background color
          ),
        );
      }
    } catch (e) {
      print("Error logging in: $e");
      // Show snackbar for any error during login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while logging in.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.yellow[800], // Set background color
        ),
      );

      setState(() {
        isLoggingIn = false;
      });
    }
  }



  void _checkAdditionalInformation(User user) async {
    try {
      // Fetch additional information data from Firestore
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userData.exists) {
        Map<String, dynamic>? userDataMap =
        userData.data() as Map<String, dynamic>?;

        // Check if additional information fields are filled
        if (userDataMap?['phoneNumber'] != null &&
            userDataMap?['birthday'] != null) {
          // Additional information fields are filled, navigate to home screen
          Navigator.pushReplacementNamed(context, "/home");
        } else {
          // Additional information fields are empty, show additional information page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdditionalInformationPage(),
            ),
          );
        }
      } else {
        print('Document does not exist in Firestore.');
      }
    } catch (e) {
      print('Error fetching additional information data: $e');
    }
  }

  void _showForgotPasswordDialog() {
    TextEditingController emailController =
    TextEditingController(text: _emailController.text.trim());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Forgot Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Enter your email to receive a password reset link:"),
              SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: "Email",
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Reset Password"),
              onPressed: () {
                String email = emailController.text.trim();
                _resetPassword(email);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
      showToast(message: "Password reset email sent to $email");
    } catch (e) {
      print("Error resetting password: $e");
      String errorMessage =
          "Failed to reset password. Please try again later.";
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-email':
            errorMessage = "Invalid email address.";
            break;
          case 'user-not-found':
            errorMessage = "No user found with this email address.";
            break;
          default:
            errorMessage = "An error occurred while resetting the password.";
        }
      }
      showToast(message: errorMessage);
    }
  }
}
