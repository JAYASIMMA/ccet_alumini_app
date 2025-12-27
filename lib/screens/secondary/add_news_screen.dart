import 'dart:io';

import 'package:ccet_alumini_app/services/api_service.dart';
import 'package:ccet_alumini_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickalert/quickalert.dart';

class AddNewsScreen extends StatefulWidget {
  const AddNewsScreen({super.key});

  @override
  State<AddNewsScreen> createState() => _AddNewsScreenState();
}

class _AddNewsScreenState extends State<AddNewsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _departmentController = TextEditingController();

  // Social Links Controllers
  final _whatsappController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _departmentController.dispose();
    _whatsappController.dispose();
    _youtubeController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

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

  Future<void> _submitNews() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await ApiService.uploadContentImage(_imageFile!);
      }

      final links = {
        if (_whatsappController.text.trim().isNotEmpty)
          'whatsapp': _whatsappController.text.trim(),
        if (_youtubeController.text.trim().isNotEmpty)
          'youtube': _youtubeController.text.trim(),
        if (_facebookController.text.trim().isNotEmpty)
          'facebook': _facebookController.text.trim(),
        if (_instagramController.text.trim().isNotEmpty)
          'instagram': _instagramController.text.trim(),
      };

      final newsData = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'department': _departmentController.text.trim().isNotEmpty
            ? _departmentController.text.trim()
            : 'General',
        'author': currentUser.uid,
        if (imageUrl != null) 'image': imageUrl,
        if (links.isNotEmpty) 'links': links,
      };

      await ApiService.createNews(newsData);

      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          text: 'News added successfully!',
          onConfirmBtnTap: () {
            Navigator.pop(context); // Close alert
            Navigator.pop(
              context,
              true,
            ); // Return to previous screen with success
          },
        );
      }
    } catch (e) {
      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          text: 'Error adding news: $e',
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
        title: const Text('Add News'),
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                    image: _imageFile != null
                        ? DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 50,
                              color: Colors.grey.shade600,
                            ),
                            Text(
                              'Tap to add an image (Optional)',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              if (_imageFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _imageFile = null),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text(
                        'Remove Image',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'News Headline',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.article),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a headline';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                  hintText: 'e.g., CSE, ECE, or leave blank for General',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'News Content',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the content';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Social Links (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildSocialField(
                _whatsappController,
                'WhatsApp Link',
                Icons.chat,
              ),
              const SizedBox(height: 8),
              _buildSocialField(
                _youtubeController,
                'YouTube Link',
                Icons.video_library,
              ),
              const SizedBox(height: 8),
              _buildSocialField(
                _facebookController,
                'Facebook Link',
                Icons.facebook,
              ),
              const SizedBox(height: 8),
              _buildSocialField(
                _instagramController,
                'Instagram Link',
                Icons.camera_alt,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitNews,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Publish News',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
