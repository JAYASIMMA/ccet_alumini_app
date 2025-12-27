import 'package:ccet_alumini_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';

class EditJobScreen extends StatefulWidget {
  final Map<String, dynamic> job;

  const EditJobScreen({super.key, required this.job});

  @override
  State<EditJobScreen> createState() => _EditJobScreenState();
}

class _EditJobScreenState extends State<EditJobScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _companyController;
  late TextEditingController _locationController;
  late TextEditingController _typeController;
  late TextEditingController _linkController;
  late TextEditingController _descriptionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.job['title']);
    _companyController = TextEditingController(text: widget.job['company']);
    _locationController = TextEditingController(text: widget.job['location']);
    _typeController = TextEditingController(text: widget.job['type']);
    _linkController = TextEditingController(text: widget.job['link']);
    _descriptionController = TextEditingController(
      text: widget.job['description'],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _typeController.dispose();
    _linkController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final updatedData = {
      'title': _titleController.text,
      'company': _companyController.text,
      'location': _locationController.text,
      'type': _typeController.text,
      'link': _linkController.text,
      'description': _descriptionController.text,
    };

    try {
      await ApiService.updateJob(widget.job['_id'], updatedData);
      if (mounted) {
        await QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          text: 'Job updated successfully!',
        );
        Navigator.pop(context, true); // Return true to trigger refresh
      }
    } catch (e) {
      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          text: 'Failed to update job: $e',
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
        title: const Text('Edit Job'),
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
                decoration: const InputDecoration(labelText: 'Job Title'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Please enter title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(labelText: 'Company'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Please enter company' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Please enter location' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _typeController.text.isNotEmpty
                    ? _typeController.text
                    : null,
                decoration: const InputDecoration(labelText: 'Job Type'),
                items: ['Full-time', 'Part-time', 'Contract', 'Internship']
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _typeController.text = val!),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Please select type' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'Application Link (Optional)',
                ),
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
                  onPressed: _isLoading ? null : _updateJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Update Job',
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
