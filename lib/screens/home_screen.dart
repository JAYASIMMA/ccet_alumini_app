import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'welcome_screen.dart';

// Tabs
import 'tabs/feed_tab.dart';
import 'tabs/events_tab.dart';
import 'tabs/directory_tab.dart';
import 'tabs/profile_tab.dart';

// Secondary Screens
import 'secondary/chat_screen.dart';
import 'secondary/news_screen.dart';
import 'secondary/jobs_screen.dart';
import 'secondary/donation_screen.dart';
import 'secondary/settings_screen.dart';
import 'secondary/admin_user_manage_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _tabs = const [
    FeedTab(),
    EventsTab(),
    DirectoryTab(),
    ProfileTab(),
  ];

  final List<String> _titles = const [
    'Chettinad Tech Alumni Feed',
    'Events',
    'Directory',
    'Profile',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).pop(); // Close drawer
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(_titles[_currentIndex]),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2575FC), Color(0xFF00C6FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.message_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ChatScreen()),
                );
              },
            ),
          ],
        ),
        drawer: Drawer(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(
                  user?.displayName ?? "Alumni Member",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                accountEmail: Text(user?.email ?? ""),
                currentAccountPicture: Builder(
                  builder: (context) {
                    final fixedUrl = ApiService.fixImageUrl(user?.photoURL);
                    final hasValidUrl = fixedUrl != null && fixedUrl.isNotEmpty;
                    final imageProvider = hasValidUrl
                        ? NetworkImage(fixedUrl)
                        : null;

                    return CircleAvatar(
                      backgroundColor: Theme.of(context).cardColor,
                      backgroundImage: imageProvider,
                      onBackgroundImageError: imageProvider != null
                          ? (_, __) {}
                          : null,
                      child: !hasValidUrl
                          ? Text(
                              (user?.displayName ?? "A")
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 40.0,
                                color: Color(0xFF2575FC),
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    );
                  },
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2575FC), Color(0xFF00C6FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(
                    context,
                  ).scaffoldBackgroundColor, // Dynamic color
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.newspaper,
                          color: Color(0xFF2575FC),
                        ),
                        title: const Text('News & Updates'),
                        onTap: () => _navigateTo(const NewsScreen()),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.business_center,
                          color: Color(0xFF2575FC),
                        ),
                        title: const Text('Jobs & Careers'),
                        onTap: () => _navigateTo(const JobsScreen()),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.volunteer_activism,
                          color: Color(0xFF2575FC),
                        ),
                        title: const Text('Donations'),
                        onTap: () => _navigateTo(const DonationScreen()),
                      ),
                      const Divider(),
                      if (user?.isAdmin == true)
                        ListTile(
                          leading: const Icon(
                            Icons.admin_panel_settings,
                            color: Color(0xFF2575FC),
                          ),
                          title: const Text('Manage Users'),
                          onTap: () =>
                              _navigateTo(const AdminUserManagementScreen()),
                        ),
                      if (user?.role == 'hod')
                        ListTile(
                          leading: const Icon(
                            Icons.people_alt,
                            color: Color(0xFF2575FC),
                          ),
                          title: const Text('Department Users'),
                          onTap: () {
                            Navigator.pop(context); // Close drawer
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminUserManagementScreen(
                                  restrictedDepartment: user?.department,
                                ),
                              ),
                            );
                          },
                        ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.settings, color: Colors.grey),
                        title: const Text('Settings'),
                        onTap: () => _navigateTo(const SettingsScreen()),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(
                          Icons.logout,
                          color: Colors.redAccent,
                        ),
                        title: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.redAccent),
                        ),
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
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'v1.0.0',
                  style: TextStyle(
                    color:
                        Theme.of(context).textTheme.bodySmall?.color ??
                        Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: Theme.of(context).brightness == Brightness.dark
                ? null // No gradient in dark mode, let scaffold color show
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF5F7FA), Colors.white],
                  ),
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: _tabs[_currentIndex],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor:
              Theme.of(context).bottomAppBarTheme.color ??
              Theme.of(context).cardColor,
          indicatorColor: const Color(0xFF2575FC).withOpacity(0.2),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: Color(0xFF2575FC)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(
                Icons.calendar_today,
                color: Color(0xFF2575FC),
              ),
              label: 'Events',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people, color: Color(0xFF2575FC)),
              label: 'Directory',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: Color(0xFF2575FC)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
