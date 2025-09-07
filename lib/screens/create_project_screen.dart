import 'package:flutter/material.dart';
import '../services/project_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({Key? key}) : super(key: key);

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final ProjectService _projectService = ProjectService();

  int _selectedColor = Colors.blue.value;

  // Task controllers
  final List<TextEditingController> _taskNameControllers = [];
  final List<int> _taskColors = [];
  final List<String> _taskStatuses = [];

  void _addTaskField() {
    setState(() {
      _taskNameControllers.add(TextEditingController());
      _taskColors.add(Colors.grey.value);
      _taskStatuses.add("In Progress");
    });
  }

  Future<void> _saveProject() async {
    if (_formKey.currentState!.validate()) {
      // Save project
      final projectId = await _projectService.createProject(
        projectName: _nameController.text.trim(),
        projectDescription: _descController.text.trim(),
        color: _selectedColor,
      );


      if (projectId != null) {
        // Save tasks
        for (int i = 0; i < _taskNameControllers.length; i++) {
          final name = _taskNameControllers[i].text.trim();
          if (name.isNotEmpty) {
            await _projectService.addTask(
              projectId: projectId,
              taskName: name,
              taskColor: _taskColors[i],
              taskStatus: _taskStatuses[i],
            );
          }
        }
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade100,
        title: const Text(
          "Create a Project",
          style: TextStyle(fontWeight: FontWeight.bold, color:Colors.deepPurple),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Project Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? "Enter a project name" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: "Project Description",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Tasks section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Tasks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: _addTaskField,
                    icon: const Icon(Icons.add),
                    tooltip: "Add Task",
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ..._taskNameControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                        TextFormField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: "Task ${index + 1} Name",
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      const SizedBox(height: 12),
                       DropdownButtonFormField<String>(
                          value: _taskStatuses[index],
                          items: const [
                            DropdownMenuItem(
                              value: "In Progress",
                              child: Text("In Progress"),
                            ),
                            DropdownMenuItem(
                              value: "Completed",
                              child: Text("Completed"),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _taskStatuses[index] = value;
                              });
                            }
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Status",
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              final colors = [
                                Colors.red,
                                Colors.green,
                                Colors.blue,
                                Colors.orange,
                                Colors.purple,
                              ];
                              final current = _taskColors[index];
                              final currentIndex = colors.indexWhere((c) => c.value == current);
                              final nextIndex = (currentIndex + 1) % colors.length;
                              _taskColors[index] = colors[nextIndex].value;
                            });
                          },
                          child: CircleAvatar(
                            backgroundColor: Color(_taskColors[index]),
                            radius: 20,
                            child: const Icon(Icons.palette, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saveProject,
                icon: const Icon(Icons.save),
                label: const Text("Create Project with Tasks"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
