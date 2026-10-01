import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ExamsScreen extends StatelessWidget {
  const ExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exams'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('exams')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load exams.'),
            );
          }

          final exams = snapshot.data?.docs ?? [];

          if (exams.isEmpty) {
            return const Center(
              child: Text('No exams available.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: exams.length,
            itemBuilder: (context, index) {
              final data = exams[index].data();

              final title = data['title'] ?? 'Exam';
              final subject = data['subject'] ?? '-';
              final date = data['date'] ?? '-';
              final time = data['time'] ?? '-';
              final room = data['room'] ?? '-';
              final status = data['status'] ?? 'Upcoming';

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
                            child: Icon(Icons.event_note_outlined),
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
                          Chip(
                            label: Text(status.toString()),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Subject: $subject',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Date: $date'),
                      const SizedBox(height: 8),
                      Text('Time: $time'),
                      const SizedBox(height: 8),
                      Text('Room: $room'),
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