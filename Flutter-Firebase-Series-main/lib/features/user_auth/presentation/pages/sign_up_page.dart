import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:InternHeroes/features/user_auth/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/login_page.dart';
import 'package:InternHeroes/features/user_auth/presentation/widgets/form_container_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuthService _auth = FirebaseAuthService();

  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  bool isSigningUp = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                  "Sign Up to",
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                ),
                Image.asset(
                  'assets/images/internheroeslogo.png', // Change path as needed
                  height: 100, // Adjust height as needed
                ),
                SizedBox(height: 30),
                FormContainerWidget(
                  controller: _usernameController,
                  hintText: "Enter your full name",
                  isPasswordField: false,
                  inputType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z ]*$'))],
                ),
                SizedBox(height: 10),
                FormContainerWidget(
                  controller: _emailController,
                  hintText: "Enter your email address",
                  isPasswordField: false,
                  inputType: TextInputType.emailAddress,
                ),
                SizedBox(height: 10),
                FormContainerWidget(
                  controller: _passwordController,
                  hintText: "Enter your password",
                  isPasswordField: true,
                ),
                SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.only(left: 10), // Added left padding
                  child: Text(
                    "Password must contain 8 characters, 1 uppercase, 1 lowercase, 1 digit, and 1 special character",
                    style: TextStyle(
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                FormContainerWidget(
                  controller: _confirmPasswordController,
                  hintText: "Confirm your password",
                  isPasswordField: true,
                ),
                SizedBox(height: 30),
                GestureDetector(
                  onTap: () {
                    _signUp(context);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.yellow[800],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: isSigningUp
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                        "Sign Up",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account?"),
                      SizedBox(width: 5),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LoginPage()),
                          );
                        },
                        child: Text(
                          "Login",
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

  void _signUp(BuildContext context) async { // Pass the context from the onTap method
    String username = _usernameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar(context, 'All fields are required'); // Pass the context to the _showSnackBar method
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar(context, 'Passwords do not match'); // Pass the context to the _showSnackBar method
      return;
    }

    // Validate password requirements
    if (!_isPasswordValid(password)) {
      _showSnackBar(context, 'Password must contain 8 characters, 1 uppercase, 1 lowercase, 1 digit, and 1 special character'); // Pass the context to the _showSnackBar method
      return;
    }

    setState(() {
      isSigningUp = true;
    });

    print("Signing up with username: $username, email: $email");

    try {
      User? user = await _auth.signUpWithEmailAndPassword(
        name: username,
        email: email,
        password: password,
      );

      setState(() {
        isSigningUp = false;
      });

      if (user != null) {
        print("User is successfully created: ${user.uid}");
        showToast(message: "User is successfully created");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        isSigningUp = false;
      });
      if (e.code == 'email-already-in-use') {
        _showSnackBar(context, 'The email address is already in use'); // Pass the context to the _showSnackBar method
      } else {
        print("Error: ${e.message}");
        showToast(message: "Error: ${e.message}");
      }
    } catch (e) {
      print("Error: $e");
      showToast(message: "Some error happened");
      setState(() {
        isSigningUp = false;
      });
    }
  }

  bool _isPasswordValid(String password) {
    String pattern =
        r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[.!@#\$&*~]).{8,}$';
    RegExp regex = RegExp(pattern);
    return regex.hasMatch(password);
  }

  void showToast({required String message}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.yellow[800],
      ),
    );
  }
}
