
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TeacherNoticesScreen extends StatefulWidget {
  const TeacherNoticesScreen({super.key});

  @override
  State<TeacherNoticesScreen> createState() =>
      _TeacherNoticesScreenState();
}

class _TeacherNoticesScreenState extends State<TeacherNoticesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = 'Academic';
  String _priority = 'Important';
  DateTime? _selectedDate;
  bool _isSaving = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String get _formattedDate {
    if (_selectedDate == null) return '';
    return '${_selectedDate!.year}-'
        '${_selectedDate!.month.toString().padLeft(2, '0')}-'
        '${_selectedDate!.day.toString().padLeft(2, '0')}';
  }

  Future<void> _publishNotice() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a notice date')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('notices').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _category,
        'date': _formattedDate,
        'priority': _priority,
      });

      _titleController.clear();
      _descriptionController.clear();

      setState(() {
        _category = 'Academic';
        _priority = 'Important';
        _selectedDate = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notice published successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish notice: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Notices')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Notice',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Notice Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Enter notice title'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Enter notice description'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Academic',
                          child: Text('Academic'),
                        ),
                        DropdownMenuItem(
                          value: 'Examination',
                          child: Text('Examination'),
                        ),
                        DropdownMenuItem(
                          value: 'Events',
                          child: Text('Events'),
                        ),
                        DropdownMenuItem(
                          value: 'Fees',
                          child: Text('Fees'),
                        ),
                        DropdownMenuItem(
                          value: 'Attendance',
                          child: Text('Attendance'),
                        ),
                        DropdownMenuItem(
                          value: 'General',
                          child: Text('General'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _category = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _selectedDate == null
                            ? ''
                            : _formattedDate,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Notice Date',
                        hintText: 'Select date',
                        suffixIcon: Icon(Icons.calendar_month),
                        border: OutlineInputBorder(),
                      ),
                      onTap: _pickDate,
                      validator: (_) => _selectedDate == null
                          ? 'Select notice date'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Important',
                          child: Text('Important'),
                        ),
                        DropdownMenuItem(
                          value: 'Normal',
                          child: Text('Normal'),
                        ),
                        DropdownMenuItem(
                          value: 'Low',
                          child: Text('Low'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _priority = value);
                        }
                      },
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _publishNotice,
                        icon: const Icon(Icons.publish),
                        label: Text(
                          _isSaving ? 'Publishing...' : 'Publish Notice',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}