import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProjectService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> createProject({
    required String projectName,
    required String projectDescription,
    required int color,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final docRef = await _db.collection('projects').add({
      'projectOwner': user.uid,
      'projectEmail': user.email,
      'projectName': projectName,
      'projectDescription': projectDescription,
      'createdAt': FieldValue.serverTimestamp(),
      'color': color,
    });

    return docRef.id; // return projectId for tasks
  }

  Future<void> addTask({
    required String projectId,
    required String taskName,
    required int taskColor,
    String taskStatus = "In Progress",
  }) async {
    final taskRef = _db.collection('projects/$projectId/tasks').doc();

    await taskRef.set({
      'taskId': taskRef.id,
      'taskName': taskName,
      'taskColor': taskColor,
      "taskStatus": taskStatus,
    });
  }
}
