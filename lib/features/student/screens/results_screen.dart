import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  Future<DocumentSnapshot<Map<String, dynamic>>> _getResult() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('results')
        .doc(uid)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _getResult(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load results.'),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Result not found.'),
            );
          }

          final data = snapshot.data!.data()!;

          final semester = data['semester'] ?? '-';
          final academicYear = data['academicYear'] ?? '-';
          final totalMarks = data['totalMarks'] ?? 0;
          final totalSubjects = data['totalSubjects'] ?? 0;
          final percentage = (data['percentage'] ?? 0).toDouble();
          final grade = data['grade'] ?? '-';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          semester.toString(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Academic Year: $academicYear',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _ResultSummary(
                                title: 'Percentage',
                                value: '${percentage.toStringAsFixed(0)}%',
                              ),
                            ),
                            Expanded(
                              child: _ResultSummary(
                                title: 'Grade',
                                value: grade.toString(),
                              ),
                            ),
                            Expanded(
                              child: _ResultSummary(
                                title: 'Marks',
                                value: '$totalMarks',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Subject-wise Results',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _SubjectResults(
                  subjects: data['subjects'] as Map<String, dynamic>? ?? {},
                ),
                const SizedBox(height: 20),
                Text(
                  'Total Subjects: $totalSubjects',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ResultSummary extends StatelessWidget {
  final String title;
  final String value;

  const _ResultSummary({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
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
    );
  }
}

class _SubjectResults extends StatelessWidget {
  final Map<String, dynamic> subjects;

  const _SubjectResults({
    required this.subjects,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: subjects.entries.map((entry) {
        final subjectData = Map<String, dynamic>.from(entry.value);

        final marks = subjectData['marks'] ?? 0;
        final grade = subjectData['grade'] ?? '-';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.book_outlined),
            ),
            title: Text(
              entry.key,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text('Marks: $marks'),
            trailing: Text(
              grade.toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}