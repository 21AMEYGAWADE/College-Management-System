import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  Future<QuerySnapshot<Map<String, dynamic>>> _getClasses() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('timetable')
        .doc(uid)
        .collection('classes')
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable'),
      ),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: _getClasses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load timetable.'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No timetable available.'),
            );
          }

          final classes = snapshot.data!.docs;

          const days = [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
          ];

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              for (final day in days)
                _buildDaySection(
                  day,
                  classes.where((doc) {
                    return doc.data()['day'] == day;
                  }).toList(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDaySection(
      String day,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> classes,
      ) {
    if (classes.isEmpty) {
      return const SizedBox.shrink();
    }

    classes.sort((a, b) {
      final timeA = a.data()['time'] ?? '';
      final timeB = b.data()['time'] ?? '';

      return timeA.compareTo(timeB);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          day,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...classes.map((classDocument) {
          final data = classDocument.data();

          final time = data['time'] ?? '';
          final subject = data['subject'] ?? '';
          final teacher = data['teacher'] ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.book_outlined),
              ),
              title: Text(
                subject,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '$time\n$teacher',
              ),
              isThreeLine: true,
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}