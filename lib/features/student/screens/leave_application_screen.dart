import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LeaveApplicationScreen extends StatefulWidget {
  const LeaveApplicationScreen({super.key});

  @override
  State<LeaveApplicationScreen> createState() =>
      _LeaveApplicationScreenState();
}

class _LeaveApplicationScreenState extends State<LeaveApplicationScreen> {
  final _reasonController = TextEditingController();

  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isFromDate) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      initialDate: DateTime.now(),
    );

    if (date == null) return;

    setState(() {
      if (isFromDate) {
        _fromDate = date;
      } else {
        _toDate = date;
      }
    });
  }

  Future<void> _submitLeave() async {
    if (_reasonController.text.trim().isEmpty ||
        _fromDate == null ||
        _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields.'),
        ),
      );
      return;
    }

    if (_toDate!.isBefore(_fromDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('To date cannot be before from date.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance
          .collection('leaveApplications')
          .add({
        'studentUid': uid,
        'reason': _reasonController.text.trim(),
        'fromDate': _fromDate!.toIso8601String().split('T').first,
        'toDate': _toDate!.toIso8601String().split('T').first,
        'status': 'Pending',
        'appliedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _reasonController.clear();

      setState(() {
        _fromDate = null;
        _toDate = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave application submitted successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to submit leave application.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Application'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _reasonController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'Enter reason for leave',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(
              _fromDate == null
                  ? 'Select From Date'
                  : 'From: ${_fromDate!.toIso8601String().split('T').first}',
            ),
            onTap: () => _selectDate(true),
          ),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(
              _toDate == null
                  ? 'Select To Date'
                  : 'To: ${_toDate!.toIso8601String().split('T').first}',
            ),
            onTap: () => _selectDate(false),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submitLeave,
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('Submit Leave Application'),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'My Leave Applications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('leaveApplications')
                .where('studentUid', isEqualTo: uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return const Text('Unable to load leave applications.');
              }

              final applications = snapshot.data?.docs ?? [];

              if (applications.isEmpty) {
                return const Text('No leave applications found.');
              }

              return Column(
                children: applications.map((document) {
                  final data = document.data();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const Icon(Icons.event_available_outlined),
                      title: Text(data['reason'] ?? 'Leave'),
                      subtitle: Text(
                        '${data['fromDate'] ?? '-'} to ${data['toDate'] ?? '-'}',
                      ),
                      trailing: Text(
                        data['status'] ?? 'Pending',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}