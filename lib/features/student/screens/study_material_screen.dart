import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudyMaterialScreen extends StatelessWidget {
  const StudyMaterialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Materials'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('studyMaterials')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load study materials.'),
            );
          }

          final materials = snapshot.data?.docs ?? [];

          if (materials.isEmpty) {
            return const Center(
              child: Text('No study materials available.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: materials.length,
            itemBuilder: (context, index) {
              final data = materials[index].data();

              final title = data['title'] ?? 'Study Material';
              final subject = data['subject'] ?? '-';
              final description = data['description'] ?? '';
              final type = data['type'] ?? 'Material';
              final teacher = data['teacher'] ?? '-';

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    child: Icon(
                      type.toString().toLowerCase() == 'pdf'
                          ? Icons.picture_as_pdf_outlined
                          : Icons.menu_book_outlined,
                    ),
                  ),
                  title: Text(
                    title.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '$subject\n$description\nTeacher: $teacher',
                    ),
                  ),
                  isThreeLine: true,
                  trailing: Chip(
                    label: Text(type.toString()),
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