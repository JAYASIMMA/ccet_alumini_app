import 'package:ccet_alumini_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/quickalert.dart';

import 'dart:io';
import 'package:file_picker/file_picker.dart';

class EditEventScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _dateController;
  late TextEditingController _locationController;
  late TextEditingController _imageController;
  DateTime? _selectedDate;
  File? _newDocFile;
  List<String> _existingAttachments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event['title']);
    _descriptionController = TextEditingController(
      text: widget.event['description'],
    );
    _locationController = TextEditingController(text: widget.event['location']);
    _imageController = TextEditingController(text: widget.event['imageUrl']);
    _existingAttachments = List<String>.from(widget.event['attachments'] ?? []);

    // Parse existing date
    try {
      _selectedDate = DateTime.parse(widget.event['date']);
      _dateController = TextEditingController(
        text: DateFormat('yyyy-MM-dd HH:mm').format(_selectedDate!),
      );
    } catch (e) {
      _selectedDate = DateTime.now();
      _dateController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _dateController.text = DateFormat(
            'yyyy-MM-dd HH:mm',
          ).format(_selectedDate!);
        });
      }
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() {
        _newDocFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _updateEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? newDocUrl;
      print('Debug: _newDocFile is ${_newDocFile?.path}');
      if (_newDocFile != null) {
        newDocUrl = await ApiService.uploadDocument(_newDocFile!);
        print('Debug: Uploaded newDocUrl: $newDocUrl');
      }

      final List<String> finalAttachments = [..._existingAttachments];
      if (newDocUrl != null) {
        finalAttachments.add(newDocUrl);
      }
      print('Debug: Final Attachments list for Update: $finalAttachments');

      final updatedData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'date': _selectedDate!.toIso8601String(),
        'location': _locationController.text,
        'imageUrl': _imageController.text,
        'attachments': finalAttachments,
      };

      await ApiService.updateEvent(widget.event['_id'], updatedData);
      if (mounted) {
        await QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          text: 'Event updated successfully!',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          text: 'Failed to update event: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Event Title'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Please enter title' : null,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'Date & Time',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: (val) => val == null || val.isEmpty
                        ? 'Please select date'
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Please enter location' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  hintText: 'https://example.com/image.jpg',
                ),
              ),
              const SizedBox(height: 16),
              // Attachments UI
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Attachments',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              if (_existingAttachments.isEmpty && _newDocFile == null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'No attachments',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ..._existingAttachments.map(
                (url) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: Text(
                    url.split('/').last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _existingAttachments.remove(url);
                      });
                    },
                  ),
                ),
              ),
              if (_newDocFile != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.green),
                  title: Text(
                    "New: ${_newDocFile!.path.split(Platform.pathSeparator).last}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _newDocFile = null;
                      });
                    },
                  ),
                ),
              TextButton.icon(
                onPressed: _pickDocument,
                icon: const Icon(Icons.upload_file),
                label: const Text('Add PDF Attachment'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (val) => val == null || val.isEmpty
                    ? 'Please enter description'
                    : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Update Event',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
