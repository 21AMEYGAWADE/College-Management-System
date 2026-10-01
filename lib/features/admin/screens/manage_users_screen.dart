
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedRole = 'all';

  final CollectionReference users =
  FirebaseFirestore.instance.collection('users');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addUser() async {
    final formKey = GlobalKey<FormState>();
    final uidController = TextEditingController();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final idController = TextEditingController();

    String role = 'student';
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Student / Teacher'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: uidController,
                        decoration: const InputDecoration(
                          labelText: 'Firebase Auth UID',
                          hintText: 'Enter existing user UID',
                        ),
                        validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'UID is required'
                            : null,
                      ),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                        ),
                        validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Name is required'
                            : null,
                      ),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!value.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: role,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'student',
                            child: Text('Student'),
                          ),
                          DropdownMenuItem(
                            value: 'teacher',
                            child: Text('Teacher'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => role = value);
                          }
                        },
                      ),
                      TextFormField(
                        controller: idController,
                        decoration: InputDecoration(
                          labelText: role == 'student'
                              ? 'Student ID (optional)'
                              : 'Employee ID (optional)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'The Firebase Authentication account must '
                            'already exist. Use its exact UID.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                    if (!formKey.currentState!.validate()) return;

                    setDialogState(() => isSaving = true);

                    final uid = uidController.text.trim();

                    try {
                      final doc = users.doc(uid);
                      final existing = await doc.get();

                      if (existing.exists) {
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(this.context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'A profile with this UID already exists.',
                            ),
                          ),
                        );
                        return;
                      }

                      final data = <String, dynamic>{
                        'name': nameController.text.trim(),
                        'email': emailController.text.trim(),
                        'role': role,
                      };

                      if (idController.text.trim().isNotEmpty) {
                        data[role == 'student'
                            ? 'studentId'
                            : 'employeeId'] =
                            idController.text.trim();
                      }

                      await doc.set(data);

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }

                      if (this.mounted) {
                        ScaffoldMessenger.of(this.context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text('Profile added successfully.'),
                          ),
                        );
                      }
                    } catch (e) {
                      setDialogState(() => isSaving = false);
                      ScaffoldMessenger.of(this.context)
                          .showSnackBar(
                        SnackBar(
                          content: Text('Failed to add profile: $e'),
                        ),
                      );
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    uidController.dispose();
    nameController.dispose();
    emailController.dispose();
    idController.dispose();
  }

  void _showUserDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        final role = data['role']?.toString() ?? '';
        final id = role == 'student'
            ? data['studentId']
            : data['employeeId'];

        return AlertDialog(
          title: Text(data['name']?.toString() ?? 'User Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: ${data['email'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Role: ${role.toUpperCase()}'),
              if (id != null && id.toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  role == 'student'
                      ? 'Student ID: $id'
                      : 'Employee ID: $id',
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Students & Teachers'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addUser,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Profile'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Filter by role',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'all',
                  child: Text('All Users'),
                ),
                DropdownMenuItem(
                  value: 'student',
                  child: Text('Students'),
                ),
                DropdownMenuItem(
                  value: 'teacher',
                  child: Text('Teachers'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedRole = value);
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: users.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Unable to load profiles.'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final search =
                _searchController.text.trim().toLowerCase();

                final profiles = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final role = data['role']?.toString().toLowerCase() ?? '';
                  final name = data['name']?.toString().toLowerCase() ?? '';
                  final email =
                      data['email']?.toString().toLowerCase() ?? '';

                  final matchesRole =
                      _selectedRole == 'all' || role == _selectedRole;
                  final matchesSearch =
                      name.contains(search) || email.contains(search);

                  return matchesRole &&
                      matchesSearch &&
                      (role == 'student' || role == 'teacher');
                }).toList();

                if (profiles.isEmpty) {
                  return const Center(
                    child: Text('No matching profiles found.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  itemCount: profiles.length,
                  itemBuilder: (context, index) {
                    final doc = profiles[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final role = data['role']?.toString() ?? '';
                    final name =
                        data['name']?.toString() ?? 'Unnamed User';
                    final email =
                        data['email']?.toString() ?? 'No email';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: role == 'student'
                              ? Colors.blue.shade100
                              : Colors.green.shade100,
                          child: Icon(
                            role == 'student'
                                ? Icons.school
                                : Icons.person,
                            color: role == 'student'
                                ? Colors.blue
                                : Colors.green,
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '$email\n${role.toUpperCase()}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showUserDetails(data),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}