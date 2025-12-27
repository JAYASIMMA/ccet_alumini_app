import 'package:ccet_alumini_app/services/api_service.dart';
import 'package:flutter/material.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  late Future<List<dynamic>> _usersFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usersFuture = ApiService.getAllUsers();
  }

  Future<void> _refreshUsers() async {
    setState(() {
      _usersFuture = ApiService.getAllUsers();
    });
  }

  Future<void> _deleteUser(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete this user? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.deleteUser(uid);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User deleted')));
      }
      _refreshUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showUserDialog({Map<String, dynamic>? user}) {
    final isEditing = user != null;
    final usernameController = TextEditingController(text: user?['username']);
    final emailController = TextEditingController(text: user?['email']);
    final passwordController = TextEditingController(text: user?['password']);
    final departmentController = TextEditingController(
      text: user?['department'] ?? 'CSE',
    );
    final completedYearController = TextEditingController(
      text: user?['completedYear'],
    );

    // Role & Student Fields
    String role = user?['role'] ?? 'student';
    String? currentYear = user?['currentYear'];

    // Default currentYear for new student
    if (currentYear == null && role == 'student' && !isEditing) {
      currentYear = '1st Year';
    }

    bool isObscured = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit User' : 'Add New User'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: ['student', 'alumni', 'admin', 'hod', 'faculty']
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(r.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        role = val!;
                        // Reset fields if role changes
                        if (role == 'student' && currentYear == null) {
                          currentYear = '1st Year';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscured ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            isObscured = !isObscured;
                          });
                        },
                      ),
                    ),
                    obscureText: isObscured,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: departmentController,
                    decoration: const InputDecoration(labelText: 'Department'),
                  ),
                  if (role == 'student') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Current Year',
                      ),
                      value: currentYear,
                      items: ['1st Year', '2nd Year', '3rd Year', '4th Year']
                          .map(
                            (y) => DropdownMenuItem(value: y, child: Text(y)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => currentYear = val),
                    ),
                  ] else if (role == 'alumni') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: completedYearController,
                      decoration: const InputDecoration(
                        labelText: 'Batch (Year)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ] else if (role == 'hod' || role == 'faculty') ...[
                    // HOD and Faculty might need Department or Designation, but for now standard fields apply
                    // You might want to ensure 'department' is editable if it was hidden or defaulted
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _saveUser(
                    isEditing: isEditing,
                    uid: user?['uid'],
                    username: usernameController.text.trim(),
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                    department: departmentController.text.trim(),
                    role: role,
                    currentYear: currentYear,
                    completedYear: completedYearController.text.trim(),
                  );
                },
                child: Text(isEditing ? 'Update' : 'Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveUser({
    required bool isEditing,
    String? uid,
    required String username,
    required String email,
    required String password,
    required String department,
    required String role,
    String? currentYear,
    String? completedYear,
  }) async {
    if (username.isEmpty || email.isEmpty || (password.isEmpty && !isEditing)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (isEditing) {
        final data = {
          'username': username,
          'email': email,
          'department': department,
          'role': role,
          'currentYear': currentYear,
          'completedYear': completedYear,
        };
        if (password.isNotEmpty) {
          data['password'] = password;
        }
        await ApiService.updateUser(uid!, data);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('User updated')));
        }
      } else {
        await ApiService.createUser({
          'username': username,
          'email': email,
          'password': password,
          'uid': 'user_${DateTime.now().millisecondsSinceEpoch}',
          'firstName': 'New',
          'lastName': 'User',
          'department': department,
          'rollNumber': '000',
          'phoneNumber': '0000000000',
          'resAddressLine1': 'Address',
          'resDistrict': 'City',
          'resPincode': '000000',
          'role': role,
          'currentYear': currentYear,
          'completedYear': completedYear,
          'isAlumni': role == 'alumni',
          'isAdmin': role == 'admin',
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('User created')));
        }
      }
      _refreshUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Operation failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final users = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: _refreshUsers,
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user['profileImageUrl'] != null
                        ? NetworkImage(user['profileImageUrl'])
                        : null,
                    child: user['profileImageUrl'] == null
                        ? Text((user['firstName']?[0] ?? 'U').toUpperCase())
                        : null,
                  ),
                  title: Text(
                    '${user['username'] ?? user['firstName']}',
                  ), // Use username or First Name
                  subtitle: Text(
                    '${user['email']} • ${user['role']?.toUpperCase() ?? 'UNK'}',
                  ),
                  onTap: () => _showUserDialog(user: user),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _isLoading
                        ? null
                        : () => _deleteUser(user['uid']),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
