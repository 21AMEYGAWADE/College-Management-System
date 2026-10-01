
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TeacherStudyMaterialsScreen extends StatefulWidget {
  const TeacherStudyMaterialsScreen({super.key});

  @override
  State<TeacherStudyMaterialsScreen> createState() =>
      _TeacherStudyMaterialsScreenState();
}

class _TeacherStudyMaterialsScreenState
    extends State<TeacherStudyMaterialsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController();

  String _type = 'PDF';
  bool _isSaving = false;

  final _materials = FirebaseFirestore.instance.collection('studyMaterials');

  Future<void> _addMaterial() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      await _materials.add({
        'title': _titleController.text.trim(),
        'subject': _subjectController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _type,
        'url': _urlController.text.trim(),
        'teacher': user.email ?? 'Teacher',
        'teacherUid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _titleController.clear();
      _subjectController.clear();
      _descriptionController.clear();
      _urlController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Study material added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add material: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Study Materials')),
      body: user == null
          ? const Center(child: Text('Please log in again.'))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Study Material',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Material Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Enter a title'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Enter a subject'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(
                        labelText: 'Material Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'PDF',
                          child: Text('PDF'),
                        ),
                        DropdownMenuItem(
                          value: 'Video',
                          child: Text('Video'),
                        ),
                        DropdownMenuItem(
                          value: 'Link',
                          child: Text('Link'),
                        ),
                        DropdownMenuItem(
                          value: 'Notes',
                          child: Text('Notes'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _type = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'Material URL (optional)',
                        hintText: 'https://...',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _addMaterial,
                        icon: const Icon(Icons.add),
                        label: Text(
                          _isSaving ? 'Saving...' : 'Add Material',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'My Study Materials',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: _materials
                .where('teacherUid', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Unable to load study materials.');
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Text('You have not added any materials yet.');
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.menu_book),
                      title: Text(data['title'] ?? 'Untitled'),
                      subtitle: Text(
                        '${data['subject'] ?? ''} • ${data['type'] ?? 'Material'}\n'
                            '${data['description'] ?? ''}'
                            '${(data['url'] ?? '').toString().isNotEmpty ? '\n${data['url']}' : ''}',
                      ),
                      isThreeLine: true,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}