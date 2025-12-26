import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class DirectoryTab extends StatelessWidget {
  const DirectoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search alumni by name, batch, or profession...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: 15,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: AutoSizeText(
                    'A${index + 1}',
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: AutoSizeText(
                  'Alumni Name ${index + 1}',
                  maxLines: 1,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: AutoSizeText(
                  'Batch of ${2015 + index} • Software Engineer',
                  maxLines: 1,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                trailing: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.message_outlined,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () {
                      // Navigate to chat
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
