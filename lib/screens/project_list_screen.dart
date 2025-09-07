import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'project_detail_screen.dart';
import 'create_project_screen.dart';
import '../widgets/logout_button.dart';

class ProjectListScreen extends StatelessWidget {
  const ProjectListScreen({Key? key}) : super(key: key);

  Future<void> _confirmDelete(
      BuildContext context, String projectId, String projectName) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text("Delete Project"),
          ],
        ),
        content: Text(
          "Are you sure you want to delete \"$projectName\"?\n\n"
              "This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete),
            label: const Text("Delete"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await FirebaseFirestore.instance.collection('projects').doc(projectId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Project \"$projectName\" deleted")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;

    if (me == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade100,
        title: const Text(
          "My Projects",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
        elevation: 0,
        actions: const [
          LogoutButton(),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('projects')
            .where(Filter.or(
          Filter('projectOwner', isEqualTo: me.uid),
          Filter('collaborators', arrayContains: me.email),
        ))
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No projects yet.\nTap + to create one!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final projectId = docs[index].id;
              final projectName = data['projectName'] ?? '';
              final isOwner = data['projectOwner'] == me.uid;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProjectDetailScreen(
                          projectId: projectId,
                          projectName: projectName,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.folder, size: 40, color: Colors.deepPurple),
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
                                (data['projectDescription'] ?? '').toString().length > 80
                                    ? "${data['projectDescription'].toString().substring(0, 80)}..."
                                    : data['projectDescription'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.people, size: 16, color: Colors.deepPurple),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${(data['collaborators'] as List<dynamic>?)?.length ?? 0} collaborators",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isOwner)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.deepPurple),
                            onPressed: () => _confirmDelete(context, projectId, projectName),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateProjectScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("New Project"),
      ),
    );
  }
}
