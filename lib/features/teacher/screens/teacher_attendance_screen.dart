import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  State<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  final Set<String> _savingStudents = {};

  String get _formattedDate {
    return '${_selectedDate.year}-'
        '${_selectedDate.month.toString().padLeft(2, '0')}-'
        '${_selectedDate.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _markAttendance({
    required String studentUid,
    required String studentName,
    required String status,
  }) async {
    setState(() {
      _savingStudents.add(studentUid);
    });

    try {
      final teacherUid = FirebaseAuth.instance.currentUser!.uid;
      final recordId = '${studentUid}_$_formattedDate';

      await FirebaseFirestore.instance
          .collection('attendanceRecords')
          .doc(recordId)
          .set({
        'studentUid': studentUid,
        'studentName': studentName,
        'teacherUid': teacherUid,
        'date': _formattedDate,
        'status': status,
        'markedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$studentName marked $status'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to mark attendance.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingStudents.remove(studentUid);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Attendance'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Attendance Date'),
                subtitle: Text(_formattedDate),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: _selectDate,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Registered Students',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'student')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Unable to load students.'),
                  );
                }

                final students = snapshot.data?.docs ?? [];

                if (students.isEmpty) {
                  return const Center(
                    child: Text('No students found.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final data = student.data();
                    final uid = student.id;
                    final name = (data['name'] ?? 'Student').toString();
                    final studentId =
                    (data['studentId'] ?? '').toString();

                    final recordId = '${uid}_$_formattedDate';

                    return StreamBuilder<
                        DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('attendanceRecords')
                          .doc(recordId)
                          .snapshots(),
                      builder: (context, recordSnapshot) {
                        final record = recordSnapshot.data?.data();
                        final status = record?['status'] as String?;

                        final isSaving = _savingStudents.contains(uid);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.person_outline),
                                  ),
                                  title: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    studentId.isEmpty
                                        ? 'Student'
                                        : 'ID: $studentId',
                                  ),
                                  trailing: status == null
                                      ? const Chip(
                                    label: Text('Not Marked'),
                                  )
                                      : Chip(
                                    label: Text(status),
                                    backgroundColor:
                                    status == 'Present'
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                  ),
                                ),
                                if (isSaving)
                                  const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: LinearProgressIndicator(),
                                  )
                                else
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _markAttendance(
                                                studentUid: uid,
                                                studentName: name,
                                                status: 'Present',
                                              ),
                                          icon: const Icon(
                                            Icons.check_circle_outline,
                                          ),
                                          label: const Text('Present'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.green,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _markAttendance(
                                                studentUid: uid,
                                                studentName: name,
                                                status: 'Absent',
                                              ),
                                          icon: const Icon(
                                            Icons.cancel_outlined,
                                          ),
                                          label: const Text('Absent'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}