import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestService {
  final _db = FirebaseFirestore.instance;

  /// Create (or overwrite) a join request for this (projectId, senderId) pair
  Future<void> sendJoinRequest({
    required String projectId,
    required String projectName,
    required String ownerId,
    required String ownerEmail,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final senderId = user.uid;
    final senderEmail = user.email ?? '';

    final reqId = '${projectId}_$senderId'; // deterministic to avoid duplicates

    await _db.collection('requests').doc(reqId).set({
      'requestId': reqId,
      'projectId': projectId,
      'projectName': projectName,
      'ownerId': ownerId,           // owner uid (keep for security)
      'ownerEmail': ownerEmail,     // owner email (for display)
      'senderId': senderId,         // sender uid (keep for security)
      'senderEmail': senderEmail,   // sender email (for display)
      'status': 'pending',          // pending | accepted | rejected
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptRequest({
    required String requestId,
    required String projectId,
    required String senderEmail,
  }) async {
    // 1) add collaborator to project (by email, not uid)
    await _db.collection('projects').doc(projectId).update({
      'collaborators': FieldValue.arrayUnion([senderEmail]),
    });

    // 2) mark request as accepted
    await _db.collection('requests').doc(requestId).update({
      'status': 'accepted',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectRequest({required String requestId}) async {
    await _db.collection('requests').doc(requestId).update({
      'status': 'rejected',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }
}
