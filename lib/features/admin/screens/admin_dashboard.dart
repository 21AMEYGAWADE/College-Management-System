
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'manage_users_screen.dart';
import 'manage_notices_screen.dart';

// Update this import if your LoginScreen is located elsewhere.
import '../../auth/screens/login_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  Stream<int> _countUsers(String role) {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> _countNotices() {
    return FirebaseFirestore.instance
        .collection('notices')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  Widget _statCard({
    required String title,
    required IconData icon,
    required Color color,
    required Stream<int> stream,
  }) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 12),
            StreamBuilder<int>(
              stream: stream,
              builder: (context, snapshot) {
                final count = snapshot.data;
                return Text(
                  snapshot.hasError
                      ? '--'
                      : count?.toString() ?? '...',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade50,
          child: Icon(icon, color: Colors.indigo),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature module is coming next.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, Admin!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              user?.email ?? 'College Administrator',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),

            const Text(
              'College Overview',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                _statCard(
                  title: 'Students',
                  icon: Icons.school,
                  color: Colors.blue,
                  stream: _countUsers('student'),
                ),
                _statCard(
                  title: 'Teachers',
                  icon: Icons.person,
                  color: Colors.green,
                  stream: _countUsers('teacher'),
                ),
                _statCard(
                  title: 'Notices',
                  icon: Icons.campaign,
                  color: Colors.orange,
                  stream: _countNotices(),
                ),
                _statCard(
                  title: 'Admins',
                  icon: Icons.admin_panel_settings,
                  color: Colors.purple,
                  stream: _countUsers('admin'),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              'Administration',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _menuCard(
              context: context,
              title: 'Manage Students & Teachers',
              subtitle: 'View and manage college profiles',
              icon: Icons.groups,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManageUsersScreen(),
                  ),
                );
              },
            ),
            _menuCard(
              context: context,
              title: 'Manage College Notices',
              subtitle: 'Create, edit and delete notices',
              icon: Icons.notifications_active,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManageNoticesScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}