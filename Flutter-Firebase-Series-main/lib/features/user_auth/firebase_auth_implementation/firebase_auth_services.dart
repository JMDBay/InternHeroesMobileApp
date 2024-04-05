import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> isFirstTimeLogin(String userId) async {
    try {
      // Check if the user's data exists in Firestore
      DocumentSnapshot userSnapshot =
      await _firestore.collection('users').doc(userId).get();
      return !userSnapshot.exists;
    } catch (e) {
      print("Error checking first time login: $e");
      return true; // Consider it as first time login in case of any error
    }
  }

  Future<User?> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Create user in Firebase Authentication
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user details in Firestore with the generated random ID
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        "name": name,
        "email": email,
        "status": "Unavailable",
        "uid": userCredential.user!.uid, // Use Firebase Auth UID
      });

      // Update user's display name
      await userCredential.user!.updateDisplayName(name);

      print("Account created Successfully");

      return userCredential.user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<User?> logIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("Login Successful");

      DocumentSnapshot userData =
      await _firestore.collection('users').doc(userCredential.user!.uid).get();
      if (userData.exists) {
        Map<String, dynamic>? userDataMap =
        userData.data() as Map<String, dynamic>?; // Explicit cast to Map<String, dynamic>
        if (userDataMap != null && userDataMap.containsKey('name')) {
          await userCredential.user!.updateDisplayName(userDataMap['name']);
        } else {
          print('Name field does not exist in Firestore document.');
        }
      } else {
        print('Document does not exist in Firestore.');
      }

      return userCredential.user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<void> logOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("error");
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<void> updateAdditionalInformation({
    required String userId,
    required String phoneNumber,
    required String birthday,
    required String university,
    required String yearAndCourse,
    required String ojtCoordinatorEmail,
    required String requiredHours,
    required String careerPath,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        "phoneNumber": phoneNumber,
        "birthday": birthday,
        "university": university,
        "yearAndCourse": yearAndCourse,
        "ojtCoordinatorEmail": ojtCoordinatorEmail,
        "requiredHours": requiredHours,
        "careerPath": careerPath,
      });
    } catch (e) {
      print("Error updating additional information: $e");
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print("Error sending password reset email: $e");
      throw e;
    }
  }
}
