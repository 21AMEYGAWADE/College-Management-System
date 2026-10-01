
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TeacherResultsScreen extends StatefulWidget {
  const TeacherResultsScreen({super.key});

  @override
  State<TeacherResultsScreen> createState() => _TeacherResultsScreenState();
}

class _TeacherResultsScreenState extends State<TeacherResultsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _marksController = TextEditingController();
  final _totalController = TextEditingController();

  String? _selectedStudentUid;
  bool _isSaving = false;

  Future<void> _saveResult(String studentName) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentUid == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final marks = int.parse(_marksController.text.trim());
    final total = int.parse(_totalController.text.trim());
    final subject = _subjectController.text.trim();

    if (marks > total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marks cannot exceed total marks')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final percentage = (marks / total) * 100;

      await FirebaseFirestore.instance
          .collection('results')
          .doc(_selectedStudentUid)
          .set({
        'studentUid': _selectedStudentUid,
        'studentName': studentName,
        'subjects': {
          subject: {
            'marks': marks,
            'totalMarks': total,
            'percentage': double.parse(percentage.toStringAsFixed(2)),
          },
        },
        'updatedBy': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _subjectController.clear();
      _marksController.clear();
      _totalController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Result saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save result: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _marksController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Results')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load students.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data!.docs;

          if (students.isEmpty) {
            return const Center(child: Text('No students found.'));
          }

          final selectedExists = students.any(
                (student) => student.id == _selectedStudentUid,
          );

          final selectedUid =
          selectedExists ? _selectedStudentUid : null;

          final selectedStudent = selectedUid == null
              ? null
              : students.firstWhere((student) => student.id == selectedUid);

          final studentName =
              selectedStudent?.data()['name']?.toString() ?? 'Student';

          return ListView(
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
                          'Enter Student Marks',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedUid,
                          decoration: const InputDecoration(
                            labelText: 'Select Student',
                            border: OutlineInputBorder(),
                          ),
                          items: students.map((student) {
                            final data = student.data();
                            final name =
                                data['name']?.toString() ?? 'Student';
                            final email =
                                data['email']?.toString() ?? '';
                            return DropdownMenuItem(
                              value: student.id,
                              child: Text(
                                email.isEmpty ? name : '$name ($email)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedStudentUid = value);
                          },
                          validator: (value) =>
                          value == null ? 'Select a student' : null,
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
                          controller: _marksController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Marks Obtained',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final marks = int.tryParse(value ?? '');
                            if (marks == null || marks < 0) {
                              return 'Enter valid marks';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _totalController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Total Marks',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final total = int.tryParse(value ?? '');
                            if (total == null || total <= 0) {
                              return 'Enter valid total marks';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving || selectedUid == null
                                ? null
                                : () => _saveResult(studentName),
                            icon: const Icon(Icons.save),
                            label: Text(
                              _isSaving ? 'Saving...' : 'Save Result',
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
                'Students',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...students.map((student) {
                final data = student.data();
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(data['name']?.toString() ?? 'Student'),
                    subtitle: Text(data['email']?.toString() ?? ''),
                    trailing: selectedUid == student.id
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.chevron_right),
                    onTap: () {
                      setState(() => _selectedStudentUid = student.id);
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}