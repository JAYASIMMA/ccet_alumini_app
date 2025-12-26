import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../services/auth_service.dart';
import '../welcome_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AutoSizeText('Settings', maxLines: 1),
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
      body: ListView(
        children: [
          const ListTile(
            title: AutoSizeText(
              'Account',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              maxLines: 1,
            ),
          ),
          const ListTile(
            leading: Icon(Icons.person_outline),
            title: AutoSizeText('Personal Information', maxLines: 1),
            trailing: Icon(Icons.chevron_right),
          ),
          const ListTile(
            leading: Icon(Icons.lock_outline),
            title: AutoSizeText('Privacy & Security', maxLines: 1),
            trailing: Icon(Icons.chevron_right),
          ),
          const Divider(),
          const ListTile(
            title: AutoSizeText(
              'App Settings',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              maxLines: 1,
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const AutoSizeText('Push Notifications', maxLines: 1),
            value: true,
            onChanged: (val) {},
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const AutoSizeText('Dark Mode', maxLines: 1),
            value: false,
            onChanged: (val) {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const AutoSizeText(
              'Logout',
              style: TextStyle(color: Colors.red),
              maxLines: 1,
            ),
            onTap: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
