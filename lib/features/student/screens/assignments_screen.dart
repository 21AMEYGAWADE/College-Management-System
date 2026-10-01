import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AssignmentsScreen extends StatelessWidget {
  const AssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('assignments')
            .orderBy('dueDate')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load assignments.'),
            );
          }

          final assignments = snapshot.data?.docs ?? [];

          if (assignments.isEmpty) {
            return const Center(
              child: Text('No assignments available.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final data = assignments[index].data();

              final title = data['title'] ?? 'Assignment';
              final subject = data['subject'] ?? '-';
              final description = data['description'] ?? '';
              final dueDate = data['dueDate'] ?? '-';
              final teacher = data['teacher'] ?? '-';
              final status = data['status'] ?? 'Pending';

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            child: Icon(Icons.assignment_outlined),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title.toString(),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Subject: $subject',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      Text('Teacher: $teacher'),
                      const SizedBox(height: 6),
                      Text('Due Date: $dueDate'),
                      const SizedBox(height: 10),
                      Text(description.toString()),
                      const SizedBox(height: 14),
                      Chip(
                        label: Text(status.toString()),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}