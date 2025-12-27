import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:ccet_alumini_app/screens/secondary/admin_user_manage_screen.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../secondary/edit_profile_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  Widget build(BuildContext context) {
    // Listen to user changes to rebuild UI
    return StreamBuilder(
      stream: AuthService().authStateChanges,
      initialData: AuthService().currentUser,
      builder: (context, snapshot) {
        final user = AuthService().currentUser; // Or snapshot.data

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
                  backgroundColor: Theme.of(context).cardColor,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(
                          ApiService.fixImageUrl(user!.photoURL!) ?? '',
                        )
                      : null,
                  onBackgroundImageError: (_, __) {},
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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                user?.designation?.isNotEmpty == true
                    ? user!.designation!
                    : 'Not Set',
                context,
              ),
              _buildProfileTile(
                Icons.school,
                'Graduation Year',
                user?.completedYear?.isNotEmpty == true
                    ? user!.completedYear!
                    : 'Not Set',
                context,
              ),
              _buildProfileTile(
                Icons.book,
                'Course',
                user?.department?.isNotEmpty == true
                    ? user!.department!
                    : 'Not Set',
                context,
              ),
              _buildProfileTile(
                Icons.location_on,
                'Location',
                user?.resAddressLine1?.isNotEmpty == true
                    ? user!.resAddressLine1!
                    : 'Not Set',
                context,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const AutoSizeText('Edit Profile', maxLines: 1),
              ),
              if (user?.isAdmin == true) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AdminUserManagementScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Admin Panel (Manage Users)'),
                ),
              ],
            ],
          ),
        );
      },
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
