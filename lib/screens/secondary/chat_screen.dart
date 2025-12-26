import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

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
      body: ListView.builder(
        itemCount: 8,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple.shade100,
              child: AutoSizeText('U${index + 1}', maxLines: 1),
            ),
            title: AutoSizeText('User ${index + 1}', maxLines: 1),
            subtitle: const AutoSizeText(
              'Hey! How have you been?',
              maxLines: 1,
            ),
            trailing: AutoSizeText(
              '10:30 AM',
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chat detail not implemented yet'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
