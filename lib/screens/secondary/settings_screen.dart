import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ccet_alumini_app/services/auth_service.dart';
import 'package:ccet_alumini_app/screens/welcome_screen.dart';
import 'package:ccet_alumini_app/providers/theme_provider.dart'; // Import ThemeProvider

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text(
              'Account',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Personal Information'),
            trailing: Icon(Icons.chevron_right),
          ),
          const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('Privacy & Security'),
            trailing: Icon(Icons.chevron_right),
          ),
          const Divider(),
          const ListTile(
            title: Text(
              'App Settings',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Push Notifications'),
            value: _notificationsEnabled,
            onChanged: (val) {
              setState(() {
                _notificationsEnabled = val;
              });
            },
          ),
          // Theme Selector
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('App Theme'),
            subtitle: Text(
              themeProvider.themeMode == ThemeMode.system
                  ? 'System Default'
                  : themeProvider.themeMode == ThemeMode.light
                  ? 'Light Theme'
                  : 'Dark Theme',
            ),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ListTile(
                        leading: const Icon(Icons.brightness_auto),
                        title: const Text('System Default'),
                        onTap: () {
                          themeProvider.setThemeMode(ThemeMode.system);
                          Navigator.pop(context);
                        },
                        trailing: themeProvider.themeMode == ThemeMode.system
                            ? const Icon(Icons.check, color: Colors.blue)
                            : null,
                      ),
                      ListTile(
                        leading: const Icon(Icons.brightness_5),
                        title: const Text('Light Theme'),
                        onTap: () {
                          themeProvider.setThemeMode(ThemeMode.light);
                          Navigator.pop(context);
                        },
                        trailing: themeProvider.themeMode == ThemeMode.light
                            ? const Icon(Icons.check, color: Colors.blue)
                            : null,
                      ),
                      ListTile(
                        leading: const Icon(Icons.brightness_2),
                        title: const Text('Dark Theme'),
                        onTap: () {
                          themeProvider.setThemeMode(ThemeMode.dark);
                          Navigator.pop(context);
                        },
                        trailing: themeProvider.themeMode == ThemeMode.dark
                            ? const Icon(Icons.check, color: Colors.blue)
                            : null,
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                },
              );
            },
          ),
          // Font Selector
          ListTile(
            leading: const Icon(Icons.font_download),
            title: const Text('Font Style'),
            subtitle: Text(themeProvider.fontFamily),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ListTile(
                        title: const Text(
                          'Poppins (Default)',
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                        onTap: () {
                          themeProvider.setFontFamily('Poppins');
                          Navigator.pop(context);
                        },
                        trailing: themeProvider.fontFamily == 'Poppins'
                            ? const Icon(Icons.check, color: Colors.blue)
                            : null,
                      ),
                      ListTile(
                        title: const Text(
                          'Plus Jakarta Sans',
                          style: TextStyle(fontFamily: 'Plus Jakarta Sans'),
                        ),
                        onTap: () {
                          themeProvider.setFontFamily('Plus Jakarta Sans');
                          Navigator.pop(context);
                        },
                        trailing:
                            themeProvider.fontFamily == 'Plus Jakarta Sans'
                            ? const Icon(Icons.check, color: Colors.blue)
                            : null,
                      ),
                      ListTile(
                        title: const Text(
                          'Satoshi (Style)',
                          style: TextStyle(fontFamily: 'Outfit'),
                        ),
                        subtitle: const Text(
                          'Using Outfit as Satoshi alternative',
                        ),
                        onTap: () {
                          themeProvider.setFontFamily('Satoshi (Outfit)');
                          Navigator.pop(context);
                        },
                        trailing: themeProvider.fontFamily == 'Satoshi (Outfit)'
                            ? const Icon(Icons.check, color: Colors.blue)
                            : null,
                      ),
                      ListTile(
                        title: const Text(
                          'Playfair Display (Serif)',
                          style: TextStyle(fontFamily: 'Playfair Display'),
                        ),
                        onTap: () {
                          themeProvider.setFontFamily('Playfair Display');
                          Navigator.pop(context);
                        },
                        trailing: themeProvider.fontFamily == 'Playfair Display'
                            ? const Icon(Icons.check, color: Colors.blue)
                            : null,
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                },
              );
            },
          ),
          // Text Size Slider
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Text Size'),
            subtitle: Slider(
              value: themeProvider.textScaleFactor,
              min: 0.8,
              max: 1.3,
              divisions: 5,
              label: themeProvider.textScaleFactor.toStringAsFixed(1),
              onChanged: (value) {
                themeProvider.setTextScaleFactor(value);
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await AuthService().signOut();
              if (mounted) {
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
