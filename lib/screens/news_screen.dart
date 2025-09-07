import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/logout_button.dart';
import 'package:async/async.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({Key? key}) : super(key: key);

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  bool _isProcessing = false;

  Future<void> _acceptRequest(
      BuildContext context,
      String requestId,
      Map<String, dynamic> requestData,
      ) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final projectId = requestData['projectId'] ?? '';
      final senderId = requestData['senderId'] ?? '';
      final senderEmail = requestData['senderEmail'] ?? '';
      final projectName = requestData['projectName'] ?? '';

      // Add collaborator to the project
      await FirebaseFirestore.instance.collection('projects').doc(projectId).update({
        'collaborators': FieldValue.arrayUnion([senderEmail]),
      });

      // Update request
      await FirebaseFirestore.instance.collection('requests').doc(requestId).update({
        'status': 'accepted',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      // Create ONE notification
      final me = FirebaseAuth.instance.currentUser;
      if (me != null) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'toId': senderId,
          'toEmail': senderEmail,
          'fromId': me.uid,
          'fromEmail': me.email,
          'ownerEmail': me.email, // ✅ ensure owner email is saved
          'projectId': projectId,
          'projectName': projectName,
          'type': 'request_accepted',
          'message': 'Your request to join "$projectName" was accepted.',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectRequest(
      BuildContext context,
      String requestId,
      Map<String, dynamic> requestData,
      ) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final senderId = requestData['senderId'] ?? '';
      final senderEmail = requestData['senderEmail'] ?? '';
      final projectName = requestData['projectName'] ?? '';

      await FirebaseFirestore.instance.collection('requests').doc(requestId).update({
        'status': 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      final me = FirebaseAuth.instance.currentUser;
      if (me != null) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'toId': senderId,
          'toEmail': senderEmail,
          'fromId': me.uid,
          'fromEmail': me.email,
          'ownerEmail': me.email,
          'projectId': requestData['projectId'],
          'projectName': projectName,
          'type': 'request_rejected',
          'message': 'Your request to join "$projectName" was rejected.',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _dismissNotification(String notificationId) async {
    await FirebaseFirestore.instance.collection('notifications').doc(notificationId).delete();
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    final pendingRequestsStream = FirebaseFirestore.instance
        .collection('requests')
        .where('ownerId', isEqualTo: me.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();

    final notificationsByIdStream = FirebaseFirestore.instance
        .collection('notifications')
        .where('toId', isEqualTo: me.uid)
        .snapshots();

    final notificationsByEmailStream = FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientEmail', isEqualTo: me.email)
        .snapshots();


    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade100,
        title: const Text(
          "News and Notifications",
          style: TextStyle(fontWeight: FontWeight.bold, color:Colors.deepPurple),
        ),
        elevation: 0,
        actions: const [
          LogoutButton(),
        ],
      ),
      body: Column(
        children: [
          // ---------------- Pending Requests ----------------
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: pendingRequestsStream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('Error loading requests'));
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No pending join requests'));
                }

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: docs.map((doc) {
                    final data = doc.data();
                    return Card(
                      child: ListTile(
                        title: Text('Join request for "${data['projectName']}"'),
                        subtitle: Text('From: ${data['senderEmail']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _acceptRequest(context, doc.id, data),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _rejectRequest(context, doc.id, data),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          const Divider(),

          // ---------------- Notifications ----------------
          Expanded(
            child: StreamBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
              stream: StreamZip([
                notificationsByIdStream,
                notificationsByEmailStream,
              ]),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('Error loading notifications'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = [
                  ...snap.data![0].docs,
                  ...snap.data![1].docs,
                ];

                if (allDocs.isEmpty) {
                  return const Center(child: Text('No notifications'));
                }

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: allDocs.map((doc) {
                    final data = doc.data();
                    return Card(
                      child: ListTile(
                        leading: data['type'] == 'request_accepted'
                            ? const Icon(Icons.check_circle, color: Colors.deepPurple)
                            : data['type'] == 'request_rejected'
                            ? const Icon(Icons.block, color: Colors.deepPurple)
                            : const Icon(Icons.notifications, color: Colors.deepPurple),
                        title: Text(data['message'] ?? ''),
                        subtitle: Text(data['projectName'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.deepPurple),
                          onPressed: () => _dismissNotification(doc.id),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

        ],
      ),
    );
  }
}
