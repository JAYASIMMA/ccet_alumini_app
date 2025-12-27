import 'package:ccet_alumini_app/services/api_service.dart';
import 'package:ccet_alumini_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:quickalert/quickalert.dart';
import 'dart:io';

class AddJobScreen extends StatefulWidget {
  const AddJobScreen({super.key});

  @override
  State<AddJobScreen> createState() => _AddJobScreenState();
}

class _AddJobScreenState extends State<AddJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  final _linkController = TextEditingController();
  final _descController = TextEditingController();
  String _jobType = 'Full-time';
  bool _isLoading = false;
  final List<String> _imageUrls = [];
  final List<String> _attachmentUrls = []; // PDF URLs

  final List<String> _types = [
    'Full-time',
    'Part-time',
    'Internship',
    'Contract',
  ];

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = AuthService().currentUser!;

    try {
      await ApiService.createJob({
        'title': _titleController.text,
        'company': _companyController.text,
        'location': _locationController.text,
        'type': _jobType,
        'link': _linkController.text,
        'description': _descController.text,
        'postedBy': user.uid,
        'images': _imageUrls,
        'attachments': _attachmentUrls,
      });
      if (mounted) {
        await QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          text: 'Job posted successfully!',
        );
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          text: 'Error: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result != null) {
      setState(() => _isLoading = true);
      for (var file in result.files) {
        if (file.path != null) {
          final url = await ApiService.uploadContentImage(File(file.path!));
          if (url != null) {
            setState(() => _imageUrls.add(url));
          }
        }
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );
    if (result != null) {
      setState(() => _isLoading = true);
      for (var file in result.files) {
        if (file.path != null) {
          final url = await ApiService.uploadDocument(File(file.path!));
          if (url != null) {
            setState(() => _attachmentUrls.add(url));
          }
        }
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Job'),
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
                decoration: const InputDecoration(
                  labelText: 'Job Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Job Type',
                  border: OutlineInputBorder(),
                ),
                value: _jobType,
                items: _types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setState(() => _jobType = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'Application Link (URL)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              // Image Picker
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.image),
                      label: const Text('Add Images'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickAttachments,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Add PDF'),
                    ),
                  ),
                ],
              ),
              if (_imageUrls.isNotEmpty || _attachmentUrls.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_imageUrls.isNotEmpty)
                        Text('${_imageUrls.length} Images selected'),
                      if (_attachmentUrls.isNotEmpty)
                        Text('${_attachmentUrls.length} PDFs selected'),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : _submitJob,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Post Job'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
