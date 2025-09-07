import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProjectDetailScreen extends StatelessWidget {
  final String projectId;
  final String projectName;

  const ProjectDetailScreen({
    Key? key,
    required this.projectId,
    required this.projectName,
  }) : super(key: key);

  Future<void> _assignCollaborator(
      BuildContext context, String taskId, String collaboratorEmail) async {
    final projectRef =
    FirebaseFirestore.instance.collection('projects').doc(projectId);

    await projectRef.collection('tasks').doc(taskId).update({
      'assignedTo': collaboratorEmail, // store email, not id
    });

    await FirebaseFirestore.instance.collection('notifications').add({
      'recipientEmail': collaboratorEmail, // store email
      'message': "You have been assigned to a task in $projectName",
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Assigned to $collaboratorEmail")),
    );
  }


  Future<void> _deleteTask(
      BuildContext context, String taskId, String taskName) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Task"),
        content: Text("Are you sure you want to delete \"$taskName\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('tasks')
          .doc(taskId)
          .delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Task \"$taskName\" deleted")),
        );
      }
    }
  }



  Future<void> _addTask(BuildContext context) async {
    final nameController = TextEditingController();
    Color selectedColor = Colors.blue;

    final shouldAdd = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text("New Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Task Name"),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Color>(
                value: selectedColor,
                decoration: const InputDecoration(labelText: "Task Color"),
                items: const [
                  DropdownMenuItem(
                    value: Colors.blue,
                    child: Text("Blue"),
                  ),
                  DropdownMenuItem(
                    value: Colors.green,
                    child: Text("Green"),
                  ),
                  DropdownMenuItem(
                    value: Colors.orange,
                    child: Text("Orange"),
                  ),
                  DropdownMenuItem(
                    value: Colors.red,
                    child: Text("Red"),
                  ),
                  DropdownMenuItem(
                    value: Colors.purple,
                    child: Text("Purple"),
                  ),
                ],
                onChanged: (color) {
                  if (color != null) {
                    setState(() => selectedColor = color);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );

    if (shouldAdd == true && nameController.text.trim().isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('tasks')
          .add({
        'taskName': nameController.text.trim(),
        'taskColor': selectedColor.value,
        'status': 'In Progress',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Task added")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectRef =
    FirebaseFirestore.instance.collection('projects').doc(projectId);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade100,
        title: const Text(
          "Explore projects",
          style: TextStyle(fontWeight: FontWeight.bold, color:Colors.deepPurple),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: projectRef.snapshots(),
        builder: (context, projectSnapshot) {
          if (!projectSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final projectData =
          projectSnapshot.data!.data() as Map<String, dynamic>;

          final collaborators =
              (projectData['collaborators'] as List<dynamic>?)?.cast<String>() ??
                  [];

          return StreamBuilder<QuerySnapshot>(
            stream: projectRef
                .collection('tasks')
                .snapshots(),
            builder: (context, taskSnapshot) {
              if (!taskSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final tasks = taskSnapshot.data!.docs;

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: tasks.length + 1, // +1 for "Add Task"
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index == tasks.length) {
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.deepPurple.shade100,
                      child: ListTile(
                        leading: const Icon(Icons.add, color: Colors.deepPurple),
                        title: const Text("Add New Task"),
                        onTap: () => _addTask(context),
                      ),
                    );
                  }

                  final taskDoc = tasks[index];
                  return _buildTaskCard(context, taskDoc, collaborators);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(
      BuildContext context,
      QueryDocumentSnapshot taskDoc,
      List<String> collaborators,
      ) {
    final taskData = taskDoc.data() as Map<String, dynamic>;
    final taskId = taskDoc.id;

    final status = taskData['status'] ?? 'In Progress';
    final assignedTo = taskData['assignedTo'];

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Color(taskData['taskColor'] ?? Colors.grey.value).withOpacity(0.5),
      child: ListTile(
        title: Text(taskData['taskName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Status: $status"),
            if (assignedTo != null)
              Text("Assigned to: $assignedTo",
                  style: const TextStyle(color: Colors.black)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ Toggle status button
            IconButton(
              icon: Icon(
                status == "In Progress" ? Icons.check_circle : Icons.refresh,
                color: status == "In Progress" ? Colors.deepPurple.shade500 : Colors.deepPurple.shade800,
              ),
              tooltip: status == "In Progress"
                  ? "Mark as Completed"
                  : "Mark as In Progress",
              onPressed: () {
                final newStatus =
                status == "In Progress" ? "Completed" : "In Progress";
                FirebaseFirestore.instance
                    .collection('projects')
                    .doc(projectId)
                    .collection('tasks')
                    .doc(taskId)
                    .update({'status': newStatus});
              },
            ),

            PopupMenuButton<String>(
              onSelected: (collab) {
                _assignCollaborator(context, taskId, collab);
              },
              itemBuilder: (context) {
                return collaborators
                    .map((c) => PopupMenuItem(
                  value: c,
                  child: Text(c),
                ))
                    .toList();
              },
              child: const Icon(Icons.person_add, color: Colors.deepPurple),
            ),


            // Delete task
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.deepPurple),
              onPressed: () =>
                  _deleteTask(context, taskId, taskData['taskName'] ?? ''),
            ),
          ],
        ),
      ),
    );
  }
}
