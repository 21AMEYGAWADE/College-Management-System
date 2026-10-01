
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TeacherLeaveRequestsScreen extends StatelessWidget {
  const TeacherLeaveRequestsScreen({super.key});

  Future<void> _updateStatus(
      BuildContext context,
      String documentId,
      String status,
      ) async {
    try {
      await FirebaseFirestore.instance
          .collection('leaveApplications')
          .doc(documentId)
          .update({
        'status': status,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Leave request $status')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update request: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave Requests')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('leaveApplications')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
                child: Text('Unable to load leave requests.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No leave requests found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final status = data['status']?.toString() ?? 'Pending';
              final studentName =
                  data['studentName']?.toString() ?? 'Student';
              final reason = data['reason']?.toString() ??
                  data['description']?.toString() ??
                  'No reason provided';
              final leaveDate = data['leaveDate']?.toString() ??
                  data['date']?.toString() ??
                  'Not specified';

              final isPending = status.toLowerCase() == 'pending';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(studentName,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text('Leave date: $leaveDate'),
                      const SizedBox(height: 4),
                      Text('Reason: $reason'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Status: '),
                          Text(status,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: status.toLowerCase() == 'approved'
                                    ? Colors.green
                                    : status.toLowerCase() == 'rejected'
                                    ? Colors.red
                                    : Colors.orange,
                              )),
                        ],
                      ),
                      if (isPending) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _updateStatus(
                                  context, doc.id, 'Approved'),
                              icon: const Icon(Icons.check),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _updateStatus(
                                  context, doc.id, 'Rejected'),
                              icon: const Icon(Icons.close),
                              label: const Text('Reject'),
                            ),
                          ],
                        ),
                      ],
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