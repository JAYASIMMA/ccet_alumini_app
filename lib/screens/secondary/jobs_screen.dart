import 'package:ccet_alumini_app/screens/secondary/add_job_screen.dart';
import 'package:ccet_alumini_app/screens/secondary/edit_job_screen.dart';
import 'package:ccet_alumini_app/screens/secondary/job_viewer_screen.dart'; // Add import
import 'package:ccet_alumini_app/services/api_service.dart';
import 'package:ccet_alumini_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'package:quickalert/quickalert.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  late Future<List<dynamic>> _jobsFuture;
  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _jobsFuture = ApiService.getJobs();
  }

  Future<void> _refreshJobs() async {
    setState(() {
      _jobsFuture = ApiService.getJobs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search jobs...',
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
            : const Text('Jobs & Careers'),
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
          // Date Picker Action
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
              icon: const Icon(Icons.clear, color: Colors.white), // Clear Icon
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
                  // Clear search when closing
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
        future: _jobsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allJobs = snapshot.data ?? [];

          final jobs = allJobs.where((job) {
            final title = (job['title'] ?? '').toString().toLowerCase();
            final company = (job['company'] ?? '').toString().toLowerCase();

            bool matchesSearch =
                title.contains(_searchQuery) || company.contains(_searchQuery);

            bool matchesDate = true;
            if (_selectedDate != null) {
              if (job['createdAt'] != null) {
                final jobDate = DateTime.parse(job['createdAt']);
                matchesDate =
                    jobDate.year == _selectedDate!.year &&
                    jobDate.month == _selectedDate!.month &&
                    jobDate.day == _selectedDate!.day;
              } else {
                matchesDate = false;
              }
            }

            return matchesSearch && matchesDate;
          }).toList();

          if (jobs.isEmpty) {
            return const Center(
              child: Text(
                'No Jobs Posted Yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshJobs,
            child: AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: jobs.length,
                itemBuilder: (context, index) {
                  final job = jobs[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                                image:
                                    (job['images'] != null &&
                                        (job['images'] as List).isNotEmpty)
                                    ? DecorationImage(
                                        image: NetworkImage(
                                          ApiService.fixImageUrl(
                                            job['images'][0],
                                          )!,
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child:
                                  (job['images'] != null &&
                                      (job['images'] as List).isNotEmpty)
                                  ? null
                                  : const Icon(
                                      Icons.business_center,
                                      color: Colors.grey,
                                    ),
                            ),
                            title: AutoSizeText(
                              job['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                AutoSizeText(
                                  job['company'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: AutoSizeText(
                                        '${job['location']} • ${job['type']}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        minFontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                if (job['createdAt'] != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Posted ${timeago.format(DateTime.parse(job['createdAt']))}',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Edit Button (Visible to Admin or Owner)
                                if (AuthService().currentUser?.isAdmin ==
                                        true ||
                                    (AuthService().currentUser?.uid != null &&
                                        AuthService().currentUser!.uid ==
                                            job['postedBy']))
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditJobScreen(job: job),
                                        ),
                                      );
                                      if (result == true) {
                                        _refreshJobs();
                                      }
                                    },
                                  ),
                                // Delete Button (Visible to Admin or Owner)
                                if (AuthService().currentUser?.isAdmin ==
                                        true ||
                                    (AuthService().currentUser?.uid != null &&
                                        AuthService().currentUser!.uid ==
                                            job['postedBy']))
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      QuickAlert.show(
                                        context: context,
                                        type: QuickAlertType.confirm,
                                        text: 'Do you want to delete this job?',
                                        confirmBtnText: 'Delete',
                                        cancelBtnText: 'Cancel',
                                        confirmBtnColor: Colors.red,
                                        onConfirmBtnTap: () async {
                                          Navigator.pop(context);
                                          try {
                                            await ApiService.deleteJob(
                                              job['_id'],
                                            );
                                            _refreshJobs();
                                            if (context.mounted) {
                                              QuickAlert.show(
                                                context: context,
                                                type: QuickAlertType.success,
                                                text:
                                                    'Job deleted successfully!',
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              QuickAlert.show(
                                                context: context,
                                                type: QuickAlertType.error,
                                                text: 'Error deleting job: $e',
                                              );
                                            }
                                          }
                                        },
                                      );
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.share,
                                    color: Colors.green,
                                  ),
                                  onPressed: () {
                                    Share.share(
                                      'Check out this job: ${job['title']}\n'
                                      'Company: ${job['company']}\n'
                                      'Location: ${job['location']} (${job['type']})\n\n'
                                      '${job['description']}\n\n'
                                      'Apply here: ${job['link']}',
                                    );
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      JobViewerScreen(job: job),
                                ),
                              );
                            },
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
                // Check if user is Admin to use the specialized AddJobScreen,
                // OR we allow everyone to use it?
                // For now, let's open AddJobScreen for everyone allowed (or restricted version)
                // The current AddJobScreen might be admin-focused, but user requested feature for all.
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddJobScreen()),
                );
                if (result == true) {
                  _refreshJobs();
                }
              },
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
