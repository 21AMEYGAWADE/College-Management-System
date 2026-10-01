
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TeacherExamsScreen extends StatefulWidget {
  const TeacherExamsScreen({super.key});

  @override
  State<TeacherExamsScreen> createState() => _TeacherExamsScreenState();
}

class _TeacherExamsScreenState extends State<TeacherExamsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _dateController = TextEditingController();
  final _marksController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isSaving = false;

  final CollectionReference _exams =
  FirebaseFirestore.instance.collection('exams');

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (picked != null) {
      _dateController.text =
      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _addExam() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      await _exams.add({
        'title': _titleController.text.trim(),
        'subject': _subjectController.text.trim(),
        'examDate': _dateController.text.trim(),
        'totalMarks': int.parse(_marksController.text.trim()),
        'description': _descriptionController.text.trim(),
        'teacher': user.email ?? 'Teacher',
        'teacherUid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _titleController.clear();
      _subjectController.clear();
      _dateController.clear();
      _marksController.clear();
      _descriptionController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exam created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create exam: $e')),
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
    _dateController.dispose();
    _marksController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Exams & Results')),
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
                      'Create New Exam',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Exam Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Enter exam title'
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
                          ? 'Enter subject'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      onTap: _pickDate,
                      decoration: const InputDecoration(
                        labelText: 'Exam Date',
                        hintText: 'Select exam date',
                        suffixIcon: Icon(Icons.calendar_month),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                      value == null || value.isEmpty
                          ? 'Select exam date'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _marksController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total Marks',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final marks = int.tryParse(value ?? '');
                        if (marks == null || marks <= 0) {
                          return 'Enter valid total marks';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Instructions / Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _addExam,
                        icon: const Icon(Icons.add),
                        label: Text(
                          _isSaving ? 'Saving...' : 'Create Exam',
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
            'Exams Created by Me',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: _exams
                .where('teacherUid', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Unable to load exams.');
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Text('No exams created yet.');
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.assignment_outlined),
                      title: Text(data['title'] ?? 'Untitled Exam'),
                      subtitle: Text(
                        'Subject: ${data['subject'] ?? '-'}\n'
                            'Date: ${data['examDate'] ?? '-'}\n'
                            'Total Marks: ${data['totalMarks'] ?? '-'}',
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