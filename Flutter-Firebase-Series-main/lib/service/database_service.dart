import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String? uid;

  DatabaseService({this.uid});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserData(String fullName, String email) async {
    try {
      await _firestore.collection("users").doc(uid).set({
        "fullName": fullName,
        "email": email,
        "uid": uid,
      });
    } catch (e) {
      print("Error saving user data: $e");
      throw e;
    }
  }

  Future<DocumentSnapshot?> getUserData(String email) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection("users")
          .where("email", isEqualTo: email)
          .get();

      return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first : null;
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }

  Stream<DocumentSnapshot?> getUserGroups() {
    return _firestore.collection("users").doc(uid).snapshots();
  }

  Future<void> sendMessage(String chatId, Map<String, dynamic> chatMessageData, String recipientId) async {
    try {
      await _firestore.collection("chats").doc(chatId).collection("messages").add({
        "message": chatMessageData['message'],
        "senderId": chatMessageData['senderId'],
        "recipientId": recipientId,
        "time": chatMessageData['time'],
      });
    } catch (e) {
      print("Error sending message: $e");
      throw e;
    }
  }


  String getChatId(String userId1, String userId2) {
    List<String> sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  Stream<QuerySnapshot> getChats(String userId, String recipientId) {
    String chatId = getChatId(userId, recipientId);
    return _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .orderBy("time")
        .snapshots();
  }
}
