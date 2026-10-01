import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  Future<DocumentSnapshot<Map<String, dynamic>>> _getAttendance() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('attendance')
        .doc(uid)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _getAttendance(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load attendance.'),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Attendance record not found.'),
            );
          }

          final data = snapshot.data!.data()!;

          final double overallPercentage =
          (data['overallPercentage'] ?? 0).toDouble();

          final int present = data['present'] ?? 0;
          final int absent = data['absent'] ?? 0;
          final int total = data['total'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall Attendance
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text(
                          'Overall Attendance',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 130,
                          height: 130,
                          child: CircularProgressIndicator(
                            value: overallPercentage / 100,
                            strokeWidth: 12,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '${overallPercentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Overall Attendance',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Attendance Summary
                const Text(
                  'Attendance Summary',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.check_circle_outline,
                        title: 'Present',
                        value: present.toString(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.cancel_outlined,
                        title: 'Absent',
                        value: absent.toString(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.calendar_month_outlined,
                        title: 'Total',
                        value: total.toString(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Subject-wise Attendance
                const Text(
                  'Subject-wise Attendance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('attendance')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection('subjects')
                      .snapshots(),
                  builder: (context, subjectSnapshot) {
                    if (subjectSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (subjectSnapshot.hasError) {
                      return const Text(
                        'Unable to load subject attendance.',
                      );
                    }

                    final subjects = subjectSnapshot.data?.docs ?? [];

                    if (subjects.isEmpty) {
                      return const Text(
                        'No subject attendance available.',
                      );
                    }

                    return Column(
                      children: subjects.map((subject) {
                        final data = subject.data();

                        final double percentage =
                        (data['percentage'] ?? 0).toDouble();

                        return _SubjectAttendance(
                          subject: subject.id,
                          percentage: percentage / 100,
                          attendance:
                          '${percentage.toStringAsFixed(0)}%',
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 8,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectAttendance extends StatelessWidget {
  final String subject;
  final double percentage;
  final String attendance;

  const _SubjectAttendance({
    required this.subject,
    required this.percentage,
    required this.attendance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  attendance,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }
}