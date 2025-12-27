import 'dart:io';
import 'package:ccet_alumini_app/services/api_service.dart';
import 'package:ccet_alumini_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickalert/quickalert.dart';

class EditNewsScreen extends StatefulWidget {
  final Map<String, dynamic> news;

  const EditNewsScreen({super.key, required this.news});

  @override
  State<EditNewsScreen> createState() => _EditNewsScreenState();
}

class _EditNewsScreenState extends State<EditNewsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _departmentController;

  late TextEditingController _whatsappController;
  late TextEditingController _youtubeController;
  late TextEditingController _facebookController;
  late TextEditingController _instagramController;

  File? _imageFile;
  String? _existingImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.news['title']);
    _contentController = TextEditingController(text: widget.news['content']);
    _departmentController = TextEditingController(
      text: widget.news['department'],
    );

    final links = widget.news['links'] as Map<String, dynamic>?;
    _whatsappController = TextEditingController(text: links?['whatsapp']);
    _youtubeController = TextEditingController(text: links?['youtube']);
    _facebookController = TextEditingController(text: links?['facebook']);
    _instagramController = TextEditingController(text: links?['instagram']);

    _existingImageUrl = widget.news['image'];
  }

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

  Future<void> _updateNews() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl = _existingImageUrl;
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

      final updateData = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'department': _departmentController.text.trim().isNotEmpty
            ? _departmentController.text.trim()
            : 'General',
        'image': imageUrl,
        'links': links,
      };

      await ApiService.updateNews(widget.news['_id'], updateData);

      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          text: 'News updated successfully!',
          onConfirmBtnTap: () {
            Navigator.pop(context); // Close alert
            Navigator.pop(context, {
              ...widget.news,
              ...updateData,
            }); // Return updated data
          },
        );
      }
    } catch (e) {
      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          text: 'Error updating news: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit News')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    image: _imageFile != null
                        ? DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          )
                        : (_existingImageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(
                                    ApiService.fixImageUrl(_existingImageUrl)!,
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null),
                  ),
                  child: (_imageFile == null && _existingImageUrl == null)
                      ? const Icon(Icons.add_a_photo, size: 50)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Headline',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Enter headline' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                ),
                enabled:
                    AuthService().currentUser?.role ==
                    'admin', // Only admin can change department
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                ),
                maxLines: 8,
                validator: (v) => v!.isEmpty ? 'Enter content' : null,
              ),
              const SizedBox(height: 24),
              const Text(
                'Social Links',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildField(_whatsappController, 'WhatsApp', Icons.chat),
              _buildField(_youtubeController, 'YouTube', Icons.video_library),
              _buildField(_facebookController, 'Facebook', Icons.facebook),
              _buildField(_instagramController, 'Instagram', Icons.camera_alt),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateNews,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Update News'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String l, IconData i) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(
          labelText: l,
          prefixIcon: Icon(i),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
