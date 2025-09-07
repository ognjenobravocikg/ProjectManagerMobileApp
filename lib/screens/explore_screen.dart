import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/request_service.dart';
import '../widgets/logout_button.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  final _requestService = RequestService();
  String? _searchedEmail;

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade100,
        title: const Text(
          "Explore projects",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
        elevation: 0,
        actions: const [
          LogoutButton(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔎 Search Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search owner by email',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _searchedEmail = _searchController.text.trim());
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  child: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 🔎 Results / Placeholder
            if (_searchedEmail == null || _searchedEmail!.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Search for a user by email',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              )
            else
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('projects')
                      .where('projectEmail', isEqualTo: _searchedEmail)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error loading projects'));
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No projects found',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final data = docs[i].data();
                        final projectId = docs[i].id;
                        final projectName = data['projectName'] ?? 'Untitled';
                        final ownerId = data['projectOwner'] as String? ?? '';
                        final ownerEmail = data['projectEmail'] as String? ?? '';
                        final description = data['projectDescription'] ?? '';

                        final isMine = me?.uid == ownerId;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.folder_open,
                                    size: 40, color: Colors.deepPurple),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        projectName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.person,
                                              size: 16, color: Colors.deepPurple),
                                          const SizedBox(width: 4),
                                          Text(
                                            ownerEmail,
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isMine)
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('requests')
                                        .where('projectId', isEqualTo: projectId)
                                        .where('senderId', isEqualTo: me?.uid)
                                        .snapshots(),
                                    builder: (context, requestSnapshot) {
                                      if (requestSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        );
                                      }
                                      final alreadyRequested =
                                          requestSnapshot.data?.docs.isNotEmpty ?? false;

                                      if (alreadyRequested) {
                                        return const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(
                                            'Request Sent',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        );
                                      }

                                      return ElevatedButton(
                                        onPressed: () async {
                                          await _requestService.sendJoinRequest(
                                            projectId: projectId,
                                            projectName: projectName,
                                            ownerId: ownerId,
                                            ownerEmail: ownerEmail,
                                          );
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Join request sent'),
                                              ),
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text('Request to Join'),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
