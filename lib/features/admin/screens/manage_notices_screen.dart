
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageNoticesScreen extends StatefulWidget {
  const ManageNoticesScreen({super.key});

  @override
  State<ManageNoticesScreen> createState() =>
      _ManageNoticesScreenState();
}

class _ManageNoticesScreenState extends State<ManageNoticesScreen> {
  final CollectionReference notices =
  FirebaseFirestore.instance.collection('notices');

  final TextEditingController _searchController =
  TextEditingController();

  String _selectedCategory = 'All';

  final List<String> _categories = [
    'Academic',
    'Examination',
    'Events',
    'Fees',
    'Attendance',
    'General',
  ];

  final List<String> _priorities = [
    'Important',
    'Normal',
    'Low',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showNoticeDialog({
    String? docId,
    Map<String, dynamic>? existingData,
  }) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(
      text: existingData?['title']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: existingData?['description']?.toString() ?? '',
    );
    final dateController = TextEditingController(
      text: existingData?['date']?.toString() ?? '',
    );

    String category =
        existingData?['category']?.toString() ?? 'Academic';
    String priority =
        existingData?['priority']?.toString() ?? 'Normal';
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                docId == null ? 'Add Notice' : 'Edit Notice',
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Notice Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter a title'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter a description'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories.map((item) {
                          return DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => category = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: dateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Notice Date',
                          hintText: 'YYYY-MM-DD',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_month),
                        ),
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: dialogContext,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );

                          if (selected != null) {
                            final formatted =
                                '${selected.year.toString().padLeft(4, '0')}-'
                                '${selected.month.toString().padLeft(2, '0')}-'
                                '${selected.day.toString().padLeft(2, '0')}';
                            dateController.text = formatted;
                          }
                        },
                        validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Select a date'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: priority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                        ),
                        items: _priorities.map((item) {
                          return DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => priority = value);
                          }
                        },
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
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    setDialogState(() => isSaving = true);

                    final noticeData = <String, dynamic>{
                      'title': titleController.text.trim(),
                      'description':
                      descriptionController.text.trim(),
                      'category': category,
                      'date': dateController.text.trim(),
                      'priority': priority,
                    };

                    try {
                      if (docId == null) {
                        await notices.add(noticeData);
                      } else {
                        await notices.doc(docId).update(noticeData);
                      }

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(this.context)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                              docId == null
                                  ? 'Notice added successfully.'
                                  : 'Notice updated successfully.',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      setDialogState(() => isSaving = false);
                      ScaffoldMessenger.of(this.context)
                          .showSnackBar(
                        SnackBar(
                          content: Text('Error saving notice: $e'),
                        ),
                      );
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : Text(docId == null ? 'Add' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
    dateController.dispose();
  }

  Future<void> _deleteNotice(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Notice'),
        content: const Text(
          'Are you sure you want to delete this notice?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await notices.doc(docId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notice deleted successfully.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting notice: $e')),
        );
      }
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'Important':
        return Colors.red;
      case 'Normal':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage College Notices'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNoticeDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Notice'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search notices',
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
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Filter by category',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: 'All',
                  child: Text('All Categories'),
                ),
                ..._categories.map(
                      (item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: notices.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Unable to load notices.'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final search =
                _searchController.text.trim().toLowerCase();

                final filtered = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title =
                      data['title']?.toString().toLowerCase() ?? '';
                  final description =
                      data['description']?.toString().toLowerCase() ?? '';
                  final category =
                      data['category']?.toString() ?? '';

                  final matchesSearch =
                      title.contains(search) ||
                          description.contains(search);
                  final matchesCategory =
                      _selectedCategory == 'All' ||
                          category == _selectedCategory;

                  return matchesSearch && matchesCategory;
                }).toList();

                filtered.sort((a, b) {
                  final aDate =
                      (a.data() as Map<String, dynamic>)['date']
                          ?.toString() ??
                          '';
                  final bDate =
                      (b.data() as Map<String, dynamic>)['date']
                          ?.toString() ??
                          '';
                  return bDate.compareTo(aDate);
                });

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No notices found.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final title =
                        data['title']?.toString() ?? 'Untitled Notice';
                    final description =
                        data['description']?.toString() ?? '';
                    final category =
                        data['category']?.toString() ?? 'General';
                    final date = data['date']?.toString() ?? '';
                    final priority =
                        data['priority']?.toString() ?? 'Normal';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showNoticeDialog(
                                        docId: doc.id,
                                        existingData: data,
                                      );
                                    } else if (value == 'delete') {
                                      _deleteNotice(doc.id);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Delete'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(description),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(
                                  avatar: const Icon(
                                    Icons.category,
                                    size: 16,
                                  ),
                                  label: Text(category),
                                ),
                                Chip(
                                  avatar: const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                  ),
                                  label: Text(date),
                                ),
                                Chip(
                                  avatar: Icon(
                                    Icons.flag,
                                    size: 16,
                                    color: _priorityColor(priority),
                                  ),
                                  label: Text(priority),
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
          ),
        ],
      ),
    );
  }
}