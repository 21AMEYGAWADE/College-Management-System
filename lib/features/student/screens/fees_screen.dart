import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FeesScreen extends StatelessWidget {
  const FeesScreen({super.key});

  Future<DocumentSnapshot<Map<String, dynamic>>> _getFees() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('fees')
        .doc(uid)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fees'),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _getFees(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load fee details.'),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Fee details not found.'),
            );
          }

          final data = snapshot.data!.data()!;

          final totalFees = (data['totalFees'] ?? 0).toDouble();
          final paidFees = (data['paidFees'] ?? 0).toDouble();
          final pendingFees = (data['pendingFees'] ?? 0).toDouble();
          final status = data['status'] ?? 'Pending';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 55,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Pending Fees',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${pendingFees.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Chip(
                          label: Text(status.toString()),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _FeeCard(
                        title: 'Total Fees',
                        value: '₹${totalFees.toStringAsFixed(0)}',
                        icon: Icons.receipt_long_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FeeCard(
                        title: 'Paid',
                        value: '₹${paidFees.toStringAsFixed(0)}',
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Fee Information'),
                    subtitle: Text(
                      'Please contact the college office for payment details.',
                    ),
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

class _FeeCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _FeeCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 30),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}