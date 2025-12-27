import 'package:ccet_alumini_app/services/api_service.dart';
import 'package:flutter/material.dart';

class AdminUserManagementScreen extends StatefulWidget {
  final String? restrictedDepartment;

  const AdminUserManagementScreen({super.key, this.restrictedDepartment});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  late Future<List<dynamic>> _usersFuture;
  bool _isLoading = false;
  String _searchQuery = '';
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _usersFuture = ApiService.getAllUsers(
      department: widget.restrictedDepartment,
    );
  }

  Future<void> _refreshUsers() async {
    setState(() {
      _usersFuture = ApiService.getAllUsers(
        department: widget.restrictedDepartment,
      );
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

    // Auto-fill department if restricted (HOD)
    final initialDept = widget.restrictedDepartment != null
        ? widget.restrictedDepartment
        : (user?['department'] ?? 'CSE');

    final departmentController = TextEditingController(text: initialDept);

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
                        .where((r) {
                          // If HOD, remove 'admin' and 'hod' from choices (can't create other HODs/Admins)
                          if (widget.restrictedDepartment != null) {
                            return r != 'admin' && r != 'hod';
                          }
                          return true;
                        })
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
                    enabled:
                        widget.restrictedDepartment == null, // Disable if HOD
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
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final users = snapshot.data ?? [];
                final filteredUsers = users.where((user) {
                  final username = (user['username'] ?? '')
                      .toString()
                      .toLowerCase();
                  final email = (user['email'] ?? '').toString().toLowerCase();
                  final name = (user['firstName'] ?? '')
                      .toString()
                      .toLowerCase();
                  return username.contains(_searchQuery) ||
                      email.contains(_searchQuery) ||
                      name.contains(_searchQuery);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                return RefreshIndicator(
                  onRefresh: _refreshUsers,
                  child: _isGridView
                      ? GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return _buildUserGridItem(user);
                          },
                        )
                      : ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return _buildUserListItem(user);
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserListItem(Map<String, dynamic> user) {
    return ListTile(
      leading: _buildUserAvatar(user, 24),
      title: Text('${user['username'] ?? user['firstName']}'),
      subtitle: Text(
        '${user['email']} • ${user['role']?.toUpperCase() ?? 'UNK'}',
      ),
      onTap: () => _showUserDialog(user: user),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: _isLoading ? null : () => _deleteUser(user['uid']),
      ),
    );
  }

  Widget _buildUserGridItem(Map<String, dynamic> user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showUserDialog(user: user),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildUserAvatar(user, 30),
              const SizedBox(height: 8),
              Text(
                '${user['username'] ?? user['firstName']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                user['email'] ?? '',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                user['role']?.toUpperCase() ?? 'UNK',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: _isLoading ? null : () => _deleteUser(user['uid']),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(Map<String, dynamic> user, double radius) {
    return Builder(
      builder: (context) {
        final fixedUrl = ApiService.fixImageUrl(user['profileImageUrl']);
        final hasValidUrl = fixedUrl != null && fixedUrl.isNotEmpty;
        final imageProvider = hasValidUrl ? NetworkImage(fixedUrl) : null;

        return CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
          onBackgroundImageError: imageProvider != null ? (_, __) {} : null,
          child: !hasValidUrl
              ? Text((user['firstName']?[0] ?? 'U').toUpperCase())
              : null,
        );
      },
    );
  }
}
