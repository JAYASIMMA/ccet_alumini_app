import 'package:carousel_slider/carousel_slider.dart';
import 'package:ccet_alumini_app/screens/secondary/admin_user_manage_screen.dart';
import 'package:ccet_alumini_app/screens/secondary/chat_screen.dart';
import 'package:ccet_alumini_app/screens/secondary/add_post_screen.dart';
import 'package:ccet_alumini_app/screens/secondary/jobs_screen.dart';
import 'package:ccet_alumini_app/screens/secondary/news_screen.dart';
import 'package:ccet_alumini_app/screens/tabs/events_tab.dart';
import 'package:ccet_alumini_app/screens/tabs/profile_tab.dart';
import 'package:ccet_alumini_app/services/api_service.dart';
import 'package:ccet_alumini_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FeedTab extends StatefulWidget {
  const FeedTab({super.key});

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  late Future<List<dynamic>> _postsFuture;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _postsFuture = ApiService.getPosts();
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _postsFuture = ApiService.getPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<dynamic>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final posts = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: _refreshPosts,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              // Carousel(0) (includes Grid), Empty(1) or Posts(1..N).
              itemCount: posts.isEmpty ? 2 : posts.length + 1,
              itemBuilder: (context, index) {
                // --- 1. Header: Carousel + Quick Access ---
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 250.0,
                          autoPlay: true,
                          enlargeCenterPage: true,
                          aspectRatio: 16 / 9,
                          autoPlayCurve: Curves.fastOutSlowIn,
                          enableInfiniteScroll: true,
                          autoPlayAnimationDuration: const Duration(
                            milliseconds: 800,
                          ),
                          viewportFraction: 0.9,
                          enlargeFactor: 0.15,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _current = index;
                            });
                          },
                        ),
                        items:
                            [
                              'assets/images/banner_1.png',
                              'assets/images/banner_2.png',
                              'assets/images/banner_3.png',
                              'assets/images/banner_4.png',
                              'assets/images/banner_5.png',
                              'assets/images/banner_6.png',
                              'assets/images/banner_7.png',
                            ].map((i) {
                              return Builder(
                                builder: (BuildContext context) {
                                  return Container(
                                    width: MediaQuery.of(context).size.width,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 5.0,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          spreadRadius: 2,
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                      image: DecorationImage(
                                        image: AssetImage(i),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:
                            [
                              'assets/images/banner_1.png',
                              'assets/images/banner_2.png',
                              'assets/images/banner_3.png',
                              'assets/images/banner_4.png',
                              'assets/images/banner_5.png',
                              'assets/images/banner_6.png',
                              'assets/images/banner_7.png',
                            ].asMap().entries.map((entry) {
                              return Container(
                                width: _current == entry.key ? 12.0 : 8.0,
                                height: 8.0,
                                margin: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 4.0,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      (Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Theme.of(context).primaryColor)
                                          .withOpacity(
                                            _current == entry.key ? 0.9 : 0.4,
                                          ),
                                ),
                              );
                            }).toList(),
                      ),
                      // --- Quick Access Grid (Moved here) ---
                      const Padding(
                        padding: EdgeInsets.fromLTRB(0, 24, 0, 16),
                        child: Text(
                          "Quick Access",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3, // Increased to 3 to fit more items
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.1,
                        children: [
                          _buildGridCard(
                            context,
                            "Job Portal",
                            Icons.work_outline,
                            Colors.blueAccent,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const JobsScreen(),
                              ),
                            ),
                          ),
                          _buildGridCard(
                            context,
                            "News",
                            Icons.article_outlined,
                            Colors.orangeAccent,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NewsScreen(),
                              ),
                            ),
                          ),
                          _buildGridCard(
                            context,
                            "Profile",
                            Icons.person_outline,
                            Colors.purpleAccent,
                            // Navigate to ProfileTab (view mode)
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Scaffold(
                                  appBar: AppBar(
                                    title: const Text("My Profile"),
                                    centerTitle: true,
                                    flexibleSpace: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue,
                                            Colors.deepPurple,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                    ),
                                  ),
                                  body: const ProfileTab(),
                                ),
                              ),
                            ),
                          ),
                          _buildGridCard(
                            context,
                            "Events",
                            Icons.calendar_month_outlined,
                            Colors.teal,
                            // Navigate to EventsTab
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Scaffold(
                                  appBar: AppBar(
                                    title: const Text("Events"),
                                    centerTitle: true,
                                    flexibleSpace: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue,
                                            Colors.deepPurple,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                    ),
                                  ),
                                  body: const EventsTab(),
                                ),
                              ),
                            ),
                          ),
                          _buildGridCard(
                            context,
                            "Chat",
                            Icons.chat_bubble_outline,
                            Colors.pinkAccent,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ChatScreen(),
                              ),
                            ),
                          ),
                          if (AuthService().currentUser?.isAdmin == true ||
                              AuthService().currentUser?.role == 'hod')
                            _buildGridCard(
                              context,
                              "Manage Users",
                              Icons.manage_accounts_outlined,
                              Colors.redAccent,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminUserManagementScreen(),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      if (posts.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                            "Latest Updates",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  );
                }

                // --- 2. Empty State (Index 1) ---
                if (posts.isEmpty) {
                  return SizedBox(
                    height: 250,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.feed_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No posts yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            'Check back later for updates!',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // --- 4. Post Card (Index 1..N) ---
                final post = posts[index - 1];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post['imageUrl'] != null)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.network(
                            ApiService.fixImageUrl(post['imageUrl'])!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(Icons.broken_image, size: 50),
                                ),
                              );
                            },
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage: post['authorImage'] != null
                                      ? NetworkImage(post['authorImage'])
                                      : null,
                                  child: post['authorImage'] == null
                                      ? Text(
                                          (post['authorName'] ?? 'A')[0]
                                              .toUpperCase(),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post['authorName'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (post['createdAt'] != null)
                                      Text(
                                        DateFormat.yMMMd().format(
                                          DateTime.parse(post['createdAt']),
                                        ),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                                const Spacer(),
                                if (AuthService().currentUser?.isAdmin == true)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Delete Post'),
                                          content: const Text(
                                            'Are you sure you want to delete this post?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        try {
                                          await ApiService.deletePost(
                                            post['_id'],
                                          );
                                          _refreshPosts();
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text('Post deleted'),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text('Error: $e'),
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              post['content'] ?? '',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton:
          (AuthService().currentUser?.isAdmin == true ||
              AuthService().currentUser?.role == 'hod')
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddPostScreen(),
                  ),
                );
                if (result == true) {
                  _refreshPosts();
                }
              },
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildGridCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
