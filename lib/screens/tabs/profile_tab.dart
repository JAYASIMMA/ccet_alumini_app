import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../services/auth_service.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? Icon(
                      Icons.person,
                      size: 50,
                      color: Theme.of(context).primaryColor,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          AutoSizeText(
            user?.displayName ?? 'User Name',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
          ),
          AutoSizeText(
            user?.email ?? 'email@example.com',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            maxLines: 1,
          ),
          const SizedBox(height: 24),
          _buildProfileTile(
            Icons.work,
            'Profession',
            'Software Engineer',
            context,
          ),
          _buildProfileTile(Icons.school, 'Graduation Year', '2020', context),
          _buildProfileTile(Icons.book, 'Course', 'B.Tech - CSE', context),
          _buildProfileTile(
            Icons.location_on,
            'Location',
            'Bangalore, India',
            context,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit),
            label: const AutoSizeText('Edit Profile', maxLines: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTile(
    IconData icon,
    String title,
    String subtitle,
    BuildContext context,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: AutoSizeText(title, maxLines: 1),
        subtitle: AutoSizeText(
          subtitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
