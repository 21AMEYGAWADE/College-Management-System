import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load events.'),
            );
          }

          final events = snapshot.data?.docs ?? [];

          if (events.isEmpty) {
            return const Center(
              child: Text('No events available.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final data = events[index].data();

              final title = data['title'] ?? 'Event';
              final description = data['description'] ?? '';
              final date = data['date'] ?? '-';
              final time = data['time'] ?? '-';
              final venue = data['venue'] ?? '-';
              final category = data['category'] ?? 'General';

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
                            child: Icon(Icons.event_outlined),
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
                            label: Text(category.toString()),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(description.toString()),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(date.toString()),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_outlined,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(time.toString()),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(venue.toString()),
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