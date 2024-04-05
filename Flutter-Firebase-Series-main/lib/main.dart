import 'package:InternHeroes/features/user_auth/presentation/pages/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:InternHeroes/features/user_auth/presentation/pages/additionalinformationpage.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/login_page.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/sign_up_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "YOUR_API_KEY",
        appId: "YOUR_APP_ID",
        messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
        projectId: "YOUR_PROJECT_ID",
        // Your web Firebase config options
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'InternHeroes',
      theme: ThemeData(
        primarySwatch: Colors.yellow, // Set primary color
        backgroundColor: Colors.white, // Set background color
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.yellow,
          backgroundColor: Colors.white,
        ).copyWith(
          primary: Colors.yellow[800], // Set primary color
        ),
      ),
      home: AuthWrapper(),
      routes: {
        '/login': (context) => LoginPage(),
        '/signUp': (context) => SignUpPage(),
        '/additional_information': (context) => AdditionalInformationPage(),
        '/home': (context) => ProfileScreen(uid: FirebaseAuth.instance.currentUser!.uid),// Route to your ProfileScreen
     
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return ProfileScreen(uid: user.uid);
    } else {
      return LoginPage();
    }
  }
}
