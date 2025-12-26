import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'package:auto_size_text/auto_size_text.dart';

class UserDetailsScreen extends StatefulWidget {
  final String uid;
  final String email;

  const UserDetailsScreen({super.key, required this.uid, required this.email});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Basic Info Controllers
  final _rollNumberController = TextEditingController();
  final _completedYearController = TextEditingController();
  final _dobController = TextEditingController();
  String? _selectedDepartment;
  DateTime? _selectedDate;

  // Alumni Info Controllers
  File? _imageFile;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedCountryCode = '+91';

  // Residential Address
  final _resAddress1Controller = TextEditingController();
  final _resAddress2Controller = TextEditingController();
  final _resDistrictController = TextEditingController();
  final _resPincodeController = TextEditingController();

  // Placement Info
  bool _isPlaced = false;
  String? _placedIn; // On Campus / Off Campus
  final _designationController = TextEditingController();
  final _companyNameController = TextEditingController();

  // Permanent Address
  bool _sameAsResidential = false;
  final _permAddress1Controller = TextEditingController();
  final _permAddress2Controller = TextEditingController();
  final _permDistrictController = TextEditingController();
  final _permPincodeController = TextEditingController();

  final _linkedInController = TextEditingController();

  final List<String> _departments = [
    'CSE',
    'ECE',
    'EEE',
    'IT',
    'MECH',
    'CIVIL',
  ];
  final List<String> _countryCodes = ['+91', '+1', '+44', '+61'];

  @override
  void dispose() {
    _rollNumberController.dispose();
    _completedYearController.dispose();
    _dobController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _resAddress1Controller.dispose();
    _resAddress2Controller.dispose();
    _resDistrictController.dispose();
    _resPincodeController.dispose();
    _designationController.dispose();
    _companyNameController.dispose();
    _permAddress1Controller.dispose();
    _permAddress2Controller.dispose();
    _permDistrictController.dispose();
    _permPincodeController.dispose();
    _linkedInController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _onSameAsResidentialChanged(bool? value) {
    setState(() {
      _sameAsResidential = value ?? false;
      if (_sameAsResidential) {
        _permAddress1Controller.text = _resAddress1Controller.text;
        _permAddress2Controller.text = _resAddress2Controller.text;
        _permDistrictController.text = _resDistrictController.text;
        _permPincodeController.text = _resPincodeController.text;
      } else {
        _permAddress1Controller.clear();
        _permAddress2Controller.clear();
        _permDistrictController.clear();
        _permPincodeController.clear();
      }
    });
  }

  Future<String?> _uploadImage(String uid) async {
    if (_imageFile == null) return null;
    try {
      return await ApiService.uploadImage(_imageFile!);
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload a profile image')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        String? imageUrl = await _uploadImage(widget.uid);

        final userModel = UserModel(
          uid: widget.uid,
          email: widget.email,
          profileImageUrl: imageUrl,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          department: _selectedDepartment!,
          rollNumber: _rollNumberController.text.trim(),
          completedYear: _completedYearController.text.trim(),
          dateOfBirth: _selectedDate,
          phoneNumber: _phoneController.text.trim(),
          countryCode: _selectedCountryCode,
          resAddressLine1: _resAddress1Controller.text.trim(),
          resAddressLine2: _resAddress2Controller.text.trim(),
          resDistrict: _resDistrictController.text.trim(),
          resPincode: _resPincodeController.text.trim(),
          isPlaced: _isPlaced,
          placedIn: _placedIn,
          designation: _designationController.text.trim(),
          companyName: _companyNameController.text.trim(),
          isPermanentSameAsResidential: _sameAsResidential,
          permAddressLine1: _sameAsResidential
              ? _resAddress1Controller.text
              : _permAddress1Controller.text.trim(),
          permAddressLine2: _sameAsResidential
              ? _resAddress2Controller.text
              : _permAddress2Controller.text.trim(),
          permDistrict: _sameAsResidential
              ? _resDistrictController.text
              : _permDistrictController.text.trim(),
          permPincode: _sameAsResidential
              ? _resPincodeController.text
              : _permPincodeController.text.trim(),
          linkedInId: _linkedInController.text.trim(),
        );

        await _authService.saveUserDetails(userModel);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error submitting form: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AutoSizeText('Complete Your Profile', maxLines: 1),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Basic Information'),
                    _buildDropdown(
                      'Select Department',
                      _departments,
                      (val) => setState(() => _selectedDepartment = val),
                    ),
                    _buildTextField(_rollNumberController, 'Roll Number'),
                    _buildTextField(
                      _completedYearController,
                      'Completed Year (Optional)',
                    ),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: _buildTextField(_dobController, 'Date of Birth'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Alumni Information'),
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : null,
                          child: _imageFile == null
                              ? const Icon(
                                  Icons.add_a_photo,
                                  size: 40,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        'Upload Profile Image *',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(_firstNameController, 'First Name *'),
                    _buildTextField(_lastNameController, 'Last Name'),
                    Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: DropdownButtonFormField<String>(
                            value: _selectedCountryCode,
                            items: _countryCodes
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedCountryCode = val!),
                            decoration: const InputDecoration(
                              labelText: 'Code',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            _phoneController,
                            'Phone Number *',
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Residential Address'),
                    _buildTextField(_resAddress1Controller, 'Address Line 1'),
                    _buildTextField(_resAddress2Controller, 'Address Line 2'),
                    _buildTextField(_resDistrictController, 'District'),
                    _buildTextField(
                      _resPincodeController,
                      'Pincode',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text('Placed?', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 20),
                        DropdownButton<bool>(
                          value: _isPlaced,
                          items: const [
                            DropdownMenuItem(value: true, child: Text('Yes')),
                            DropdownMenuItem(value: false, child: Text('No')),
                          ],
                          onChanged: (val) => setState(() => _isPlaced = val!),
                        ),
                      ],
                    ),
                    if (_isPlaced) ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Placed In',
                        ),
                        value: _placedIn,
                        items: ['On Campus', 'Off Campus']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => _placedIn = val),
                      ),
                      _buildTextField(
                        _designationController,
                        'Designation / Course',
                      ),
                      _buildTextField(
                        _companyNameController,
                        'Name of Company',
                      ),
                    ],
                    const SizedBox(height: 20),
                    _buildSectionHeader('Permanent Address'),
                    CheckboxListTile(
                      title: const Text('Same as Residential Address'),
                      value: _sameAsResidential,
                      onChanged: _onSameAsResidentialChanged,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    if (!_sameAsResidential) ...[
                      _buildTextField(
                        _permAddress1Controller,
                        'Address Line 1',
                      ),
                      _buildTextField(
                        _permAddress2Controller,
                        'Address Line 2',
                      ),
                      _buildTextField(_permDistrictController, 'District'),
                      _buildTextField(
                        _permPincodeController,
                        'Pincode',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                    const SizedBox(height: 20),
                    _buildTextField(_linkedInController, 'LinkedIn ID'),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        child: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            'Submit Profile',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const Divider(thickness: 1.5),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: keyboardType,
        validator: (value) {
          if (label.contains('*') ||
              label == 'Roll Number' ||
              label == 'First Name' ||
              label == 'Phone Number') {
            // Simple required check
            if (value == null || value.isEmpty) return 'This field is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: label),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        validator: (val) => val == null ? 'Please select a department' : null,
      ),
    );
  }
}
