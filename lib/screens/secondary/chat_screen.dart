import 'package:ccet_alumini_app/services/api_service.dart';
import 'package:ccet_alumini_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final String _currentUid = AuthService().currentUser?.uid ?? '';
  late Future<List<dynamic>> _connectionsFuture;
  late Future<List<dynamic>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _connectionsFuture = ApiService.getMyConnections(_currentUid);
      _requestsFuture = ApiService.getPendingRequests(_currentUid);
    });
  }

  Future<void> _handleRequest(String connectionId, String status) async {
    await ApiService.respondConnectionRequest(connectionId, status);
    _refreshData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'accepted' ? 'Request Accepted' : 'Request Declined',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AutoSizeText('Messaging', maxLines: 1),
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
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pending Requests Section
              FutureBuilder<List<dynamic>>(
                future: _requestsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty)
                    return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Connection Requests',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      ...snapshot.data!.map((req) {
                        final user = req['requesterUser'];
                        final firstName = user?['firstName'] ?? '';
                        final lastName = user?['lastName'] ?? '';
                        final name = '$firstName $lastName'.trim().isEmpty
                            ? (user?['username'] ?? 'Unknown User')
                            : '$firstName $lastName'.trim();
                        final connectionId = req['_id'];
                        final imageUrl = user?['profileImageUrl'];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: imageUrl != null
                                  ? NetworkImage(
                                      ApiService.fixImageUrl(imageUrl)!,
                                    )
                                  : null,
                              child: imageUrl == null
                                  ? Text(name[0].toUpperCase())
                                  : null,
                            ),
                            title: Text(name),
                            subtitle: const Text('Wants to connect'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.check,
                                    color: Colors.green,
                                  ),
                                  onPressed: () =>
                                      _handleRequest(connectionId, 'accepted'),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _handleRequest(connectionId, 'rejected'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      const Divider(),
                    ],
                  );
                },
              ),

              // Connections List
              FutureBuilder<List<dynamic>>(
                future: _connectionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return SizedBox(
                      height: 400,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 60,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No connections yet',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Find alumni in the Directory!',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Messages',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final user = snapshot.data![index];
                          final firstName = user['firstName'] ?? '';
                          final lastName = user['lastName'] ?? '';
                          final name = '$firstName $lastName'.trim().isEmpty
                              ? (user['username'] ?? 'Alumni')
                              : '$firstName $lastName'.trim();
                          final uid = user['uid'];
                          final imageUrl = user['profileImageUrl'];

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              backgroundImage: imageUrl != null
                                  ? NetworkImage(
                                      ApiService.fixImageUrl(imageUrl)!,
                                    )
                                  : null,
                              child: imageUrl == null
                                  ? Text(name[0].toUpperCase())
                                  : null,
                            ),
                            title: Text(name),
                            subtitle: const Text('Tap to chat'),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ChatDetailScreen(
                                    targetUid: uid,
                                    targetName: name,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
