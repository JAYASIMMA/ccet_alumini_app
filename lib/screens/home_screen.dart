import 'package:flutter/material.dart';

import '../services/auth_service.dart';
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
    'CCET Alumni Feed',
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
                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
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
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? Text(
                          (user?.displayName ?? "A")
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 40.0,
                            color: Color(0xFF6A11CB),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.newspaper,
                          color: Color(0xFF6A11CB),
                        ),
                        title: const Text('News & Updates'),
                        onTap: () => _navigateTo(const NewsScreen()),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.business_center,
                          color: Color(0xFF6A11CB),
                        ),
                        title: const Text('Jobs & Careers'),
                        onTap: () => _navigateTo(const JobsScreen()),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.volunteer_activism,
                          color: Color(0xFF6A11CB),
                        ),
                        title: const Text('Donations'),
                        onTap: () => _navigateTo(const DonationScreen()),
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
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('v1.0.0', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF5F7FA), Colors.white],
            ),
          ),
          child: _tabs[_currentIndex],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF6A11CB).withOpacity(0.2),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: Color(0xFF6A11CB)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(
                Icons.calendar_today,
                color: Color(0xFF6A11CB),
              ),
              label: 'Events',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people, color: Color(0xFF6A11CB)),
              label: 'Directory',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: Color(0xFF6A11CB)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
