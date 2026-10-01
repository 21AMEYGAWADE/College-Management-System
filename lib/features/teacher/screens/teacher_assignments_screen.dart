import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TeacherAssignmentsScreen extends StatefulWidget {
  const TeacherAssignmentsScreen({super.key});

  @override
  State<TeacherAssignmentsScreen> createState() =>
      _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState
    extends State<TeacherAssignmentsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _dueDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );

    if (selectedDate != null) {
      setState(() {
        _dueDate = selectedDate;
      });
    }
  }

  Future<void> _createAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a due date.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final teacherProfile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      final teacherName =
          teacherProfile.data()?['name'] ?? user.email ?? 'Teacher';

      final formattedDate =
          '${_dueDate!.year.toString().padLeft(4, '0')}-'
          '${_dueDate!.month.toString().padLeft(2, '0')}-'
          '${_dueDate!.day.toString().padLeft(2, '0')}';

      await FirebaseFirestore.instance.collection('assignments').add({
        'title': _titleController.text.trim(),
        'subject': _subjectController.text.trim(),
        'description': _descriptionController.text.trim(),
        'dueDate': formattedDate,
        'teacher': teacherName,
        'teacherUid': user.uid,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _titleController.clear();
      _subjectController.clear();
      _descriptionController.clear();

      setState(() {
        _dueDate = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment created successfully!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to create assignment.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Assignments'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Create New Assignment',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Assignment Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.assignment_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter assignment title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.book_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter subject';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter assignment description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(
                    _dueDate == null
                        ? 'Select Due Date'
                        : 'Due Date: ${_dueDate!.year}-'
                        '${_dueDate!.month.toString().padLeft(2, '0')}-'
                        '${_dueDate!.day.toString().padLeft(2, '0')}',
                  ),
                  trailing: const Icon(Icons.arrow_drop_down),
                  onTap: _selectDueDate,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _createAssignment,
                    child: _isLoading
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('Create Assignment'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'Assignments Created',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('assignments')
                .where(
              'teacherUid',
              isEqualTo: FirebaseAuth.instance.currentUser!.uid,
            )
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return const Text('Unable to load created assignments.');
              }

              final assignments = snapshot.data?.docs ?? [];

              if (assignments.isEmpty) {
                return const Text('You have not created any assignments.');
              }

              return Column(
                children: assignments.map((document) {
                  final data = document.data();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const Icon(Icons.assignment_outlined),
                      title: Text(data['title'] ?? 'Assignment'),
                      subtitle: Text(
                        '${data['subject'] ?? '-'}\n'
                            'Due: ${data['dueDate'] ?? '-'}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.check_circle_outline),
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