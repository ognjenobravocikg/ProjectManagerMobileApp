import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final _db = FirebaseFirestore.instance;

  Future<void> sendJoinRequest({
    required String projectId,
    required String projectName,
    required String ownerId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await _db.collection("notifications").add({
      "recipientId": ownerId,
      "senderId": user.uid,
      "projectId": projectId,
      "projectName": projectName,
      "type": "join_request",
      "status": "pending",
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptJoinRequest(String notificationId, String projectId, String senderId) async {
    try {
      // 1. Update project collaborators
      await _db.collection("projects").doc(projectId).update({
        "collaborators": FieldValue.arrayUnion([senderId])
      });

      // 2. Update notification status
      await _db.collection("notifications").doc(notificationId).update({
        "status": "accepted"
      });

      // 3. Notify collaborator
      await _db.collection("notifications").add({
        "recipientId": senderId,
        "senderId": FirebaseAuth.instance.currentUser?.uid,
        "projectId": projectId,
        "type": "request_accepted",
        "status": "info",
        "createdAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error accepting request: $e");
    }
  }

  Future<void> rejectJoinRequest(String notificationId) async {
    await _db.collection("notifications").doc(notificationId).update({
      "status": "rejected"
    });
  }
}
