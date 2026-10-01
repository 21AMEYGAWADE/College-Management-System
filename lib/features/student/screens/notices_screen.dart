import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NoticesScreen extends StatelessWidget {

  String formatNoticeDate(dynamic value) {
    if (value == null) return '-';

    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day.toString().padLeft(2, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.year}';
    }

    return value.toString();
  }

  const NoticesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notices'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('notices')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load notices.'),
            );
          }

          final notices = snapshot.data?.docs ?? [];

          debugPrint('Notices received: ${notices.length}');

          for (final notice in notices) {
            debugPrint(
              'ID: ${notice.id}, Data: ${notice.data()}',
            );
          }

          if (notices.isEmpty) {
            return const Center(
              child: Text('No notices available.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final data = notices[index].data();

              final title = data['title'] ?? 'Notice';

              final description =
                  data['description'] ?? data['message'] ?? '';

              final date = formatNoticeDate(
                data['date'] ?? data['createdAt'],
              );

              final category = data['category'] ?? 'General';
              final priority = data['priority'] ?? 'Normal';

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
                            child: Icon(Icons.notifications_outlined),
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
                            label: Text(priority.toString()),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(description.toString()),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.category_outlined, size: 18),
                          const SizedBox(width: 6),
                          Text(category.toString()),
                          const Spacer(),
                          const Icon(Icons.calendar_today_outlined, size: 16),
                          const SizedBox(width: 6),
                          Text(date.toString()),
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