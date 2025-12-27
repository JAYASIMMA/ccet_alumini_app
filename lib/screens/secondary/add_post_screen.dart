import 'package:ccet_alumini_app/services/api_service.dart';
import 'package:ccet_alumini_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _contentController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  bool _autoDelete = false;
  DateTime? _expirationDate;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitPost() async {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Content is required')));
      return;
    }

    setState(() => _isLoading = true);
    final user = AuthService().currentUser!;

    try {
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await ApiService.uploadContentImage(_imageFile!);
      }

      await ApiService.createPost({
        'authorName': user.displayName,
        'authorImage': user.photoURL,
        'content': _contentController.text,
        'imageUrl': imageUrl,
        'expiresAt': _autoDelete && _expirationDate != null
            ? _expirationDate!.toIso8601String()
            : null,
      });
      if (mounted) {
        Navigator.pop(context, true); // Return true to refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add News/Update'),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 50,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Add Feature Image",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Post Content',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto-Delete post?'),
              subtitle: const Text(
                'Automatically remove this post at a set time',
              ),
              value: _autoDelete,
              onChanged: (val) => setState(() => _autoDelete = val),
            ),
            if (_autoDelete)
              ListTile(
                title: Text(
                  _expirationDate == null
                      ? 'Select Expiration Date & Time'
                      : 'Expires: ${_expirationDate.toString().split('.')[0]}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null && mounted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        _expirationDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isLoading ? null : _submitPost,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Post Update', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
