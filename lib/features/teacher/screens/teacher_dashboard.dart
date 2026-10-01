import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'teacher_attendance_screen.dart';
import 'teacher_assignments_screen.dart';
import 'teacher_exams_screen.dart';
import 'teacher_notices_screen.dart';
import 'teacher_leave_requests_screen.dart';
import 'teacher_complaints_screen.dart';
import 'teacher_study_materials_screen.dart';
import 'teacher_results_screen.dart';

import '../../auth/screens/login_screen.dart';


class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'Teacher';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.school_outlined, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'Welcome, Teacher!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(email),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Teaching Modules',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _TeacherCard(
            icon: Icons.assignment_outlined,
            title: 'Assignments',
            subtitle: 'Create and manage assignments',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TeacherAssignmentsScreen(),
                ),
              );
            },
          ),
          _TeacherCard(
            icon: Icons.fact_check_outlined,
            title: 'Attendance',
            subtitle: 'Manage student attendance',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TeacherAttendanceScreen(),
                ),
              );
            },
          ),
          _TeacherCard(
            icon: Icons.menu_book_outlined,
            title: 'Study Materials',
            subtitle: 'Share learning materials',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TeacherStudyMaterialsScreen(),
                ),
              );
            },
          ),
          _TeacherCard(
            icon: Icons.event_note_outlined,
            title: 'Exams',
            subtitle: 'Manage exams',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TeacherExamsScreen(),
                ),
              );
            },
          ),

          _TeacherCard(
            icon: Icons.event_note_outlined,
            title: 'Results',
            subtitle: 'Manage marks',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TeacherResultsScreen(),
                ),
              );
            },
          ),

          _TeacherCard(
            icon: Icons.notifications_outlined,
            title: 'Notices',
            subtitle: 'Publish student notices',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TeacherNoticesScreen(),
                ),
              );
            },
          ),

          _TeacherCard(
            icon: Icons.event_note,
            title: 'Leave Requests',
            subtitle: 'Review student leave applications',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TeacherLeaveRequestsScreen(),
                ),
              );
            },
          ),

          _TeacherCard(
            icon: Icons.report_problem_outlined,
            title: 'Student Complaints',
            subtitle: 'View and resolve student complaints',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TeacherComplaintsScreen(),
                ),
              );
            },
          ),


        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String module) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$module module is not available yet.')),
    );
  }
}

class _TeacherCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TeacherCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          child: Icon(icon),
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
}