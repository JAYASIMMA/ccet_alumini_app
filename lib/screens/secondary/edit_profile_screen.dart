import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ccet_alumini_app/services/api_service.dart';
import 'package:ccet_alumini_app/services/auth_service.dart';
import 'package:ccet_alumini_app/models/user_model.dart';
import '../home_screen.dart'; // Import HomeScreen

class EditProfileScreen extends StatefulWidget {
  final bool isOnboarding;
  final String? selectedRole; // Add this

  const EditProfileScreen({
    super.key,
    this.isOnboarding = false,
    this.selectedRole,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _rollNumberController;
  late TextEditingController _completedYearController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _resAddressLine1Controller;
  late TextEditingController _resAddressLine2Controller;
  late TextEditingController _resDistrictController;
  late TextEditingController _resPincodeController;
  late TextEditingController _designationController; // Or Course
  late TextEditingController _companyNameController;
  late TextEditingController _permAddressLine1Controller;
  late TextEditingController _permAddressLine2Controller;
  late TextEditingController _permDistrictController;
  late TextEditingController _permPincodeController;
  late TextEditingController _linkedInIdController;

  // State Variables
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  UserModel? _currentUser;
  bool _isLoading = false;

  // Dropdown Values
  String? _selectedDepartment;
  String _selectedCountryCode = '+91';
  String? _selectedBloodGroup; // Add blood group state
  bool _isPlaced = false;
  String? _placedIn; // On Campus/Off Campus
  bool _isPermanentSameAsResidential = false;
  DateTime? _dateOfBirth;

  final List<String> _departments = [
    'CSE', 'IT', 'ECE', 'EEE', 'MECH', 'CIVIL', 'MBA', // Add actual departments
  ];
  final List<String> _countryCodes = ['+91', '+1', '+44', '+61']; // Add more
  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];
  final List<String> _placedInOptions = ['On Campus', 'Off Campus'];

  @override
  void initState() {
    super.initState();
    _currentUser = AuthService().currentUser;
    _initializeControllers();
  }

  void _initializeControllers() {
    final user = _currentUser;
    _firstNameController = TextEditingController(text: user?.firstName);
    _lastNameController = TextEditingController(text: user?.lastName);
    _rollNumberController = TextEditingController(text: user?.rollNumber);
    _completedYearController = TextEditingController(text: user?.completedYear);
    _phoneNumberController = TextEditingController(text: user?.phoneNumber);
    _resAddressLine1Controller = TextEditingController(
      text: user?.resAddressLine1,
    );
    _resAddressLine2Controller = TextEditingController(
      text: user?.resAddressLine2,
    );
    _resDistrictController = TextEditingController(text: user?.resDistrict);
    _resPincodeController = TextEditingController(text: user?.resPincode);
    // If student -> Course, If Alumni -> Designation. Using one controller.
    _designationController = TextEditingController(
      text: user?.designation ?? user?.department,
    );
    // Note: department field in backend is strictly Department (CSE etc), but designation is job title.
    // User requested "Designation/Course". I will map Course to Department if Student?
    // Wait, the requirement says "Select your Department" (Dropdown) AND "Designation/Course".
    // "Designation/Course" likely means: "Manager" or "B.Tech CSE".
    // I'll keep _designationController for the text input "Designation/Course".

    _companyNameController = TextEditingController(text: user?.companyName);
    _permAddressLine1Controller = TextEditingController(
      text: user?.permAddressLine1,
    );
    _permAddressLine2Controller = TextEditingController(
      text: user?.permAddressLine2,
    );
    _permDistrictController = TextEditingController(text: user?.permDistrict);
    _permPincodeController = TextEditingController(text: user?.permPincode);
    _linkedInIdController = TextEditingController(text: user?.linkedInId);

    _selectedDepartment = user?.department;
    // Fix for DropdownButton error: Ensure selected value is in the items list
    if (_selectedDepartment != null &&
        !_departments.contains(_selectedDepartment)) {
      _selectedDepartment = null;
    }

    _selectedCountryCode = user?.countryCode ?? '+91';
    if (!_countryCodes.contains(_selectedCountryCode)) {
      _selectedCountryCode = '+91';
    }
    _selectedBloodGroup = user?.bloodGroup;
    if (_selectedBloodGroup != null &&
        !_bloodGroups.contains(_selectedBloodGroup)) {
      _selectedBloodGroup = null;
    }
    _isPlaced = user?.isPlaced ?? false;
    _placedIn = user?.placedIn;
    _isPermanentSameAsResidential = user?.isPermanentSameAsResidential ?? false;
    _dateOfBirth = user?.dateOfBirth;

    // Special handling: Department in user model is String.
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _rollNumberController.dispose();
    _completedYearController.dispose();
    _phoneNumberController.dispose();
    _resAddressLine1Controller.dispose();
    _resAddressLine2Controller.dispose();
    _resDistrictController.dispose();
    _resPincodeController.dispose();
    _designationController.dispose();
    _companyNameController.dispose();
    _permAddressLine1Controller.dispose();
    _permAddressLine2Controller.dispose();
    _permDistrictController.dispose();
    _permPincodeController.dispose();
    _linkedInIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _deleteImage() async {
    if (_currentUser == null) return;
    setState(() => _isLoading = true);
    try {
      await ApiService.deleteProfileImage(_currentUser!.uid);
      final response = await ApiService.get('/user/${_currentUser!.uid}');
      final updatedUser = UserModel.fromMap(response);
      AuthService().updateCurrentUser(updatedUser);
      setState(() {
        _imageFile = null;
        _currentUser = updatedUser;
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture removed')),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields')),
      );
      return;
    }

    if (_imageFile == null && _currentUser?.profileImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile Image is Required')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? photoUrl = _currentUser!.profileImageUrl;

      if (_imageFile != null) {
        final uploadedUrl = await ApiService.uploadImage(_imageFile!);
        if (uploadedUrl != null) photoUrl = uploadedUrl;
      }

      bool isAlumni = false;
      if (_completedYearController.text.isNotEmpty) {
        int? year = int.tryParse(_completedYearController.text.trim());
        if (year != null && year <= DateTime.now().year) {
          isAlumni = true;
        }
      }

      final updatedUser = UserModel(
        uid: _currentUser!.uid,
        username: _currentUser!.username,
        email: _currentUser!.email,
        profileImageUrl: photoUrl,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        department: _selectedDepartment ?? '',
        rollNumber: _rollNumberController.text.trim(),
        completedYear: _completedYearController.text.trim(),
        dateOfBirth: _dateOfBirth,
        phoneNumber: _phoneNumberController.text.trim(),
        countryCode: _selectedCountryCode,
        bloodGroup: _selectedBloodGroup,
        resAddressLine1: _resAddressLine1Controller.text.trim(),
        resAddressLine2: _resAddressLine2Controller.text.trim(),
        resDistrict: _resDistrictController.text.trim(),
        resPincode: _resPincodeController.text.trim(),
        isPlaced: _isPlaced,
        placedIn: _isPlaced ? _placedIn : null,
        designation: _designationController.text.trim(),
        companyName: _companyNameController.text.trim(),
        isPermanentSameAsResidential: _isPermanentSameAsResidential,
        permAddressLine1: _isPermanentSameAsResidential
            ? _resAddressLine1Controller.text.trim()
            : _permAddressLine1Controller.text.trim(),
        permAddressLine2: _isPermanentSameAsResidential
            ? _resAddressLine2Controller.text.trim()
            : _permAddressLine2Controller.text.trim(),
        permDistrict: _isPermanentSameAsResidential
            ? _resDistrictController.text.trim()
            : _permDistrictController.text.trim(),
        permPincode: _isPermanentSameAsResidential
            ? _resPincodeController.text.trim()
            : _permPincodeController.text.trim(),
        linkedInId: _linkedInIdController.text.trim(),
        isAdmin: _currentUser!.isAdmin,
        isAlumni: isAlumni,
        role: widget.selectedRole ?? _currentUser?.role ?? 'alumni',
        currentYear: _currentUser?.currentYear,
        semester: _currentUser?.semester,
      );

      await AuthService().saveUserDetails(updatedUser);

      if (mounted) {
        if (widget.isOnboarding) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Setup'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Profile Image (Center)
                    Center(
                      child: Stack(
                        children: [
                          Builder(
                            builder: (context) {
                              final fixedUrl = ApiService.fixImageUrl(
                                _currentUser?.profileImageUrl,
                              );
                              final hasValidUrl =
                                  fixedUrl != null && fixedUrl.isNotEmpty;
                              // Prioritize selected file, then network image
                              final ImageProvider? imageProvider =
                                  _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : (hasValidUrl
                                        ? NetworkImage(fixedUrl)
                                        : null);

                              return CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: imageProvider,
                                onBackgroundImageError: imageProvider != null
                                    ? (_, __) {}
                                    : null,
                                child: (_imageFile == null && !hasValidUrl)
                                    ? const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey,
                                      )
                                    : null,
                              );
                            },
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              radius: 20,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_currentUser?.photoURL != null || _imageFile != null)
                      Center(
                        child: TextButton(
                          onPressed: _deleteImage,
                          child: const Text(
                            'Remove Picture',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    _buildSectionHeader('Basic Information'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'First Name *',
                            _firstNameController,
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            'Last Name',
                            _lastNameController,
                          ),
                        ),
                      ],
                    ),
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Department'),
                      value: _selectedDepartment,
                      items: _departments
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedDepartment = val),
                      validator: (val) => val == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField('Roll Number', _rollNumberController),
                    if (widget.selectedRole == 'student' ||
                        (_currentUser?.role == 'student')) ...[
                      // Student Specific Fields
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration('Current Year'),
                        value: _currentUser
                            ?.currentYear, // You might need a controller/variable for this if new
                        items: ['1st Year', '2nd Year', '3rd Year', '4th Year']
                            .map(
                              (y) => DropdownMenuItem(value: y, child: Text(y)),
                            )
                            .toList(),
                        onChanged: (val) {
                          // Handle change (add to state/controller)
                        },
                      ),
                      const SizedBox(height: 16),
                      // Hide Completed Year, or make it "Expected Graduation"
                    ] else ...[
                      // Alumni Specific Fields (keep existing)
                      _buildTextField(
                        'Completed Year',
                        _completedYearController,
                        keyboardType: TextInputType.number,
                      ),
                    ],

                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: _inputDecoration('Date of Birth')
                              .copyWith(
                                suffixIcon: const Icon(Icons.calendar_today),
                              ),
                          controller: TextEditingController(
                            text: _dateOfBirth != null
                                ? DateFormat('dd-MM-yyyy').format(_dateOfBirth!)
                                : '',
                          ),
                          validator: (val) =>
                              val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Blood Group'),
                      value: _selectedBloodGroup,
                      items: _bloodGroups
                          .map(
                            (bg) =>
                                DropdownMenuItem(value: bg, child: Text(bg)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedBloodGroup = val),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionHeader('Contact Information'),
                    Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: DropdownButtonFormField<String>(
                            decoration: _inputDecoration('Code'),
                            value: _selectedCountryCode,
                            items: _countryCodes
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedCountryCode = val!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            'Phone Number *',
                            _phoneNumberController,
                            keyboardType: TextInputType.phone,
                            required: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField('LinkedIn ID', _linkedInIdController),
                    const SizedBox(height: 16),

                    _buildSectionHeader('Residential Address'),
                    _buildTextField(
                      'Address Line 1 *',
                      _resAddressLine1Controller,
                      required: true,
                    ),
                    _buildTextField(
                      'Address Line 2',
                      _resAddressLine2Controller,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'District *',
                            _resDistrictController,
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            'Pincode *',
                            _resPincodeController,
                            required: true,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _isPermanentSameAsResidential,
                          onChanged: (val) => setState(
                            () => _isPermanentSameAsResidential = val ?? false,
                          ),
                        ),
                        const Text('Permanent Address same as Residential'),
                      ],
                    ),
                    if (!_isPermanentSameAsResidential) ...[
                      _buildSectionHeader('Permanent Address'),
                      _buildTextField(
                        'Address Line 1',
                        _permAddressLine1Controller,
                      ),
                      _buildTextField(
                        'Address Line 2',
                        _permAddressLine2Controller,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              'District',
                              _permDistrictController,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              'Pincode',
                              _permPincodeController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (widget.selectedRole == 'alumni' ||
                        (_currentUser?.role == 'alumni')) ...[
                      _buildSectionHeader('Placement & Career'),
                      // ... (Placement fields)
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration('Placed?'),
                        value: _isPlaced ? 'Yes' : 'No',
                        items: ['Yes', 'No']
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                        onChanged: (val) => setState(() {
                          _isPlaced = val == 'Yes';
                          if (!_isPlaced) _placedIn = null;
                        }),
                      ),
                      // ... rest of placement fields
                      const SizedBox(height: 16),
                      if (_isPlaced)
                        DropdownButtonFormField<String>(
                          decoration: _inputDecoration('Placed In'),
                          value: _placedIn,
                          items: _placedInOptions
                              .map(
                                (v) =>
                                    DropdownMenuItem(value: v, child: Text(v)),
                              )
                              .toList(),
                          onChanged: (val) => setState(() => _placedIn = val),
                        ),
                      const SizedBox(height: 16),
                      _buildTextField('Designation', _designationController),
                      _buildTextField(
                        'Name of Company',
                        _companyNameController,
                      ),
                    ],

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading ? null : _saveProfile,
                        child: Text(
                          _isLoading ? 'Saving...' : 'Save Profile',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          Divider(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration(label),
        keyboardType: keyboardType,
        validator: required
            ? (value) => value == null || value.isEmpty ? 'Required' : null
            : null,
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
