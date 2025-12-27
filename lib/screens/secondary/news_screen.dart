import 'package:auto_size_text/auto_size_text.dart';
import 'package:ccet_alumini_app/screens/secondary/add_news_screen.dart';
import 'package:ccet_alumini_app/services/api_service.dart';
import 'package:ccet_alumini_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/quickalert.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<dynamic>> _newsFuture;
  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _refreshNews();
  }

  void _refreshNews() {
    setState(() {
      _newsFuture = ApiService.getNews();
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search news...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              )
            : const AutoSizeText('News & Updates', maxLines: 1),
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_today,
              color: _selectedDate != null ? Colors.yellow : Colors.white,
            ),
            onPressed: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (pickedDate != null && pickedDate != _selectedDate) {
                setState(() {
                  _selectedDate = pickedDate;
                });
              }
            },
          ),
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedDate = null;
                });
              },
              tooltip: 'Clear Date Filter',
            ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _newsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allNews = snapshot.data ?? [];

          final newsList = allNews.where((news) {
            final title = (news['title'] ?? '').toString().toLowerCase();
            final content = (news['content'] ?? '').toString().toLowerCase();
            final department = (news['department'] ?? '')
                .toString()
                .toLowerCase();

            bool matchesSearch =
                title.contains(_searchQuery) ||
                content.contains(_searchQuery) ||
                department.contains(_searchQuery);

            bool matchesDate = true;
            if (_selectedDate != null) {
              // Priority to 'date' field (News Date), fallback to maybe match Logic if needed.
              // Schema has 'date' field.
              if (news['date'] != null) {
                final newsDate = DateTime.parse(news['date']);
                matchesDate =
                    newsDate.year == _selectedDate!.year &&
                    newsDate.month == _selectedDate!.month &&
                    newsDate.day == _selectedDate!.day;
              } else {
                matchesDate = false;
              }
            }

            return matchesSearch && matchesDate;
          }).toList();

          if (newsList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.newspaper, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No News Yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    'Stay tuned for updates!',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refreshNews(),
            child: AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: newsList.length,
                itemBuilder: (context, index) {
                  final news = newsList[index];
                  final links = news['links'] as Map<String, dynamic>?;

                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // News Image
                              if (news['image'] != null &&
                                  news['image'].toString().isNotEmpty)
                                SizedBox(
                                  height: 200,
                                  width: double.infinity,
                                  child: Image.network(
                                    ApiService.fixImageUrl(news['image'])!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: Colors.grey.shade200,
                                              child: const Center(
                                                child: Icon(Icons.broken_image),
                                              ),
                                            ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            news['title'],
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        // Delete Button (Admin or Author)
                                        if (AuthService()
                                                    .currentUser
                                                    ?.isAdmin ==
                                                true ||
                                            (news['author'] != null &&
                                                AuthService()
                                                        .currentUser
                                                        ?.uid ==
                                                    news['author']['_id']))
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              QuickAlert.show(
                                                context: context,
                                                type: QuickAlertType.confirm,
                                                text: 'Delete this news?',
                                                confirmBtnText: 'Delete',
                                                cancelBtnText: 'Cancel',
                                                confirmBtnColor: Colors.red,
                                                onConfirmBtnTap: () async {
                                                  Navigator.pop(context);
                                                  try {
                                                    await ApiService.deleteNews(
                                                      news['_id'],
                                                    );
                                                    _refreshNews();
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Error: $e',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (news['department'] != null &&
                                        news['department'] != 'General')
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          news['department'],
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      news['content'],
                                      style: const TextStyle(fontSize: 15),
                                    ),

                                    // Social Media Links
                                    if (links != null && links.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      const Divider(),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          if (links['whatsapp'] != null)
                                            _buildSocialIcon(
                                              Icons.chat,
                                              Colors.green,
                                              links['whatsapp'],
                                            ),
                                          if (links['youtube'] != null)
                                            _buildSocialIcon(
                                              Icons.video_library,
                                              Colors.red,
                                              links['youtube'],
                                            ),
                                          if (links['facebook'] != null)
                                            _buildSocialIcon(
                                              Icons.facebook,
                                              Colors.blue.shade900,
                                              links['facebook'],
                                            ),
                                          if (links['instagram'] != null)
                                            _buildSocialIcon(
                                              Icons.camera_alt,
                                              Colors.purple,
                                              links['instagram'],
                                            ),
                                        ],
                                      ),
                                    ],

                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat.yMMMd().add_jm().format(
                                            DateTime.parse(news['date']),
                                          ),
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        // "Posted ago" logic
                                        if (news['date'] != null)
                                          Text(
                                            ' • ${timeago.format(DateTime.parse(news['date']))}',
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (news['author'] != null)
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.person,
                                                size: 14,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                news['author']['username'] ??
                                                    'Unknown',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: (AuthService().currentUser?.role != 'student')
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddNewsScreen(),
                  ),
                );
                if (result == true) {
                  _refreshNews();
                }
              },
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color, String url) {
    return IconButton(
      icon: Icon(icon, color: color, size: 28),
      onPressed: () => _launchUrl(url),
    );
  }
}
