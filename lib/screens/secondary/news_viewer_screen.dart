import 'package:auto_size_text/auto_size_text.dart';
import 'package:ccet_alumini_app/screens/secondary/edit_news_screen.dart';
import 'package:ccet_alumini_app/services/api_service.dart';
import 'package:ccet_alumini_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:quickalert/quickalert.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsViewerScreen extends StatefulWidget {
  final Map<String, dynamic> news;

  const NewsViewerScreen({super.key, required this.news});

  @override
  State<NewsViewerScreen> createState() => _NewsViewerScreenState();
}

class _NewsViewerScreenState extends State<NewsViewerScreen> {
  late Map<String, dynamic> _currentNews;

  @override
  void initState() {
    super.initState();
    _currentNews = widget.news;
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

  bool _canManage() {
    final user = AuthService().currentUser;
    if (user == null) return false;
    if (user.isAdmin) return true;

    // HOD/Faculty can manage if it's their department
    if (user.role == 'hod' || user.role == 'faculty') {
      return _currentNews['department'] == user.department;
    }

    return false;
  }

  void _showFullImage() {
    final imageUrl = ApiService.fixImageUrl(_currentNews['image']);
    if (imageUrl == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PhotoView(
            imageProvider: NetworkImage(imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2.0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final links = _currentNews['links'] as Map<String, dynamic>?;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _currentNews['image'] != null
                  ? GestureDetector(
                      onTap: _showFullImage,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            ApiService.fixImageUrl(_currentNews['image'])!,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.newspaper,
                        size: 80,
                        color: Colors.white54,
                      ),
                    ),
            ),
            actions: [
              if (_canManage()) ...[
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditNewsScreen(news: _currentNews),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _currentNews = result;
                      });
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    QuickAlert.show(
                      context: context,
                      type: QuickAlertType.confirm,
                      text: 'Delete this news permanently?',
                      confirmBtnText: 'Delete',
                      confirmBtnColor: Colors.red,
                      onConfirmBtnTap: () async {
                        Navigator.pop(context);
                        try {
                          await ApiService.deleteNews(_currentNews['_id']);
                          if (mounted) Navigator.pop(context, true);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ],
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_currentNews['department'] != null &&
                          _currentNews['department'] != 'General')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _currentNews['department'],
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat.yMMMd().format(
                          DateTime.parse(_currentNews['date']),
                        ),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _currentNews['title'],
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.grey.shade200,
                        child: const Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'By ${_currentNews['author']?['username'] ?? 'Admin'}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(),
                  ),
                  Text(
                    _currentNews['content'],
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.6,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (links != null && links.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    const Text(
                      'Connected Links',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (links['whatsapp'] != null)
                          _buildLinkIcon(
                            Icons.chat,
                            Colors.green,
                            links['whatsapp'],
                          ),
                        if (links['youtube'] != null)
                          _buildLinkIcon(
                            Icons.video_library,
                            Colors.red,
                            links['youtube'],
                          ),
                        if (links['facebook'] != null)
                          _buildLinkIcon(
                            Icons.facebook,
                            Colors.blue.shade900,
                            links['facebook'],
                          ),
                        if (links['instagram'] != null)
                          _buildLinkIcon(
                            Icons.camera_alt,
                            Colors.purple,
                            links['instagram'],
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkIcon(IconData icon, Color color, String url) {
    return Container(
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: () => _launchUrl(url),
      ),
    );
  }
}
