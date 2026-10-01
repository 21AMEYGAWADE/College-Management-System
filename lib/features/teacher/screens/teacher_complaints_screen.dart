
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TeacherComplaintsScreen extends StatelessWidget {
  const TeacherComplaintsScreen({super.key});

  Future<void> _updateStatus(
      BuildContext context,
      String documentId,
      String status,
      ) async {
    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(documentId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Complaint marked as $status')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update complaint: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Complaints')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
        FirebaseFirestore.instance.collection('complaints').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
                child: Text('Unable to load complaints.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No complaints submitted.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final studentName =
                  data['studentName']?.toString() ?? 'Student';
              final title = data['title']?.toString() ??
                  data['subject']?.toString() ??
                  'Complaint';
              final message = data['complaint']?.toString() ??
                  data['description']?.toString() ??
                  data['message']?.toString() ??
                  'No details provided';
              final status = data['status']?.toString() ?? 'Pending';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('Submitted by: $studentName'),
                      const SizedBox(height: 8),
                      Text(message),
                      const SizedBox(height: 8),
                      Text(
                        'Status: $status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: status.toLowerCase() == 'resolved'
                              ? Colors.green
                              : status.toLowerCase() == 'in progress'
                              ? Colors.blue
                              : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: status == 'In Progress'
                                ? null
                                : () => _updateStatus(
                                context, doc.id, 'In Progress'),
                            child: const Text('In Progress'),
                          ),
                          ElevatedButton.icon(
                            onPressed: status == 'Resolved'
                                ? null
                                : () => _updateStatus(
                                context, doc.id, 'Resolved'),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Resolve'),
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
      ),
    );
  }
}