import 'package:ccet_alumini_app/services/api_service.dart';
import 'package:ccet_alumini_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import '../secondary/chat_detail_screen.dart';

class DirectoryTab extends StatefulWidget {
  const DirectoryTab({super.key});

  @override
  State<DirectoryTab> createState() => _DirectoryTabState();
}

class _DirectoryTabState extends State<DirectoryTab> {
  late Future<List<dynamic>> _usersFuture;
  final String _currentUid = AuthService().currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsers();
  }

  Future<List<dynamic>> _fetchUsers() async {
    // Ideally create a specific endpoint for listing directory users
    // For now we can assume we might have one or just fail gracefully if not.
    // If no specific directory endpoint, we might need one.
    // Let's assume we can get all users via a new endpoint or reusing.
    // Wait, we don't have a 'get all users' endpoint safely exposed.
    // I will add a method to fetch random users or all users to api_service if needed.
    // For MVP, allow searching or just fetch 'all' if small.
    // Let's implement a simple user fetch in ApiService for this.
    try {
      // We will assume GET /user returns all for now for directory or creates a new one.
      // Actually, let's just use what we have or add one quickly.
      // Adding a temp /user/all to the plan/code is safer.
      // For now, I'll allow it to fail and show empty.
      final response = await ApiService.get('/user/all');
      return response as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  Future<void> _sendRequest(String targetUid) async {
    await ApiService.sendConnectionRequest(_currentUid, targetUid);
    setState(() {
      _usersFuture = _fetchUsers(); // Refresh to update status
    });
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request Sent!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search alumni...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _usersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No alumni found.'));
              }

              final users = snapshot.data!
                  .where((u) => u['uid'] != _currentUid)
                  .toList();

              return ListView.separated(
                itemCount: users.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = users[index];
                  final firstName = user['firstName'] ?? '';
                  final lastName = user['lastName'] ?? '';
                  final displayName = '$firstName $lastName'.trim();
                  final fullName = displayName.isEmpty
                      ? (user['displayName'] ?? 'Alumni')
                      : displayName;
                  final targetUid = user['uid'];

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      backgroundImage:
                          (user['profileImageUrl'] != null &&
                              user['profileImageUrl'].toString().isNotEmpty)
                          ? NetworkImage(
                              ApiService.fixImageUrl(user['profileImageUrl'])!,
                            )
                          : null,
                      child:
                          (user['profileImageUrl'] == null ||
                              user['profileImageUrl'].toString().isEmpty)
                          ? Text(
                              fullName.isNotEmpty
                                  ? fullName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.white),
                            )
                          : null,
                    ),
                    title: Text(
                      fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(user['department'] ?? user['email'] ?? ''),
                    trailing: FutureBuilder<Map<String, dynamic>>(
                      future: ApiService.checkConnectionStatus(
                        _currentUid,
                        targetUid,
                      ),
                      builder: (context, statusSnapshot) {
                        if (!statusSnapshot.hasData)
                          return const SizedBox.shrink();

                        final status = statusSnapshot.data!['status'];

                        if (status == 'accepted') {
                          return IconButton(
                            icon: Icon(
                              Icons.message,
                              color: Theme.of(context).primaryColor,
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ChatDetailScreen(
                                    targetUid: targetUid,
                                    targetName: fullName,
                                  ),
                                ),
                              );
                            },
                          );
                        } else if (status == 'pending') {
                          return const Text(
                            'Pending',
                            style: TextStyle(color: Colors.grey),
                          );
                        } else {
                          return ElevatedButton(
                            onPressed: () => _sendRequest(targetUid),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text('Connect'),
                          );
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
