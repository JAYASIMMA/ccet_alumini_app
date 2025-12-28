import 'package:ccet_alumini_app/screens/secondary/add_event_screen.dart';
import 'package:ccet_alumini_app/screens/secondary/edit_event_screen.dart';
import 'package:ccet_alumini_app/screens/secondary/event_viewer_screen.dart';
import 'package:ccet_alumini_app/services/api_service.dart';
import 'package:ccet_alumini_app/services/auth_service.dart';
import 'package:ccet_alumini_app/widgets/full_screen_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:quickalert/quickalert.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;

class EventsTab extends StatefulWidget {
  const EventsTab({super.key});

  @override
  State<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<EventsTab> {
  late Future<List<dynamic>> _eventsFuture;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _eventsFuture = ApiService.getEvents();
  }

  Future<void> _refreshEvents() async {
    setState(() {
      _eventsFuture = ApiService.getEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search and Date Filter Section
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search events...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2C2C2C)
                          : Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _selectedDate != null
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : (Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2C2C2C)
                              : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.calendar_today,
                      color: _selectedDate != null
                          ? Theme.of(context).primaryColor
                          : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600),
                    ),
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: Theme.of(context).primaryColor,
                                onPrimary: Colors.white,
                                surface: Theme.of(context).cardColor,
                                onSurface: Theme.of(
                                  context,
                                ).textTheme.bodyLarge!.color!,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickedDate != null && pickedDate != _selectedDate) {
                        setState(() {
                          _selectedDate = pickedDate;
                        });
                      }
                    },
                    tooltip: 'Filter by Date',
                  ),
                ),
                if (_selectedDate != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedDate = null;
                      });
                    },
                    tooltip: 'Clear Date',
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _eventsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allEvents = snapshot.data ?? [];

                final events = allEvents.where((event) {
                  final title = (event['title'] ?? '').toString().toLowerCase();
                  final location = (event['location'] ?? '')
                      .toString()
                      .toLowerCase();
                  final desc = (event['description'] ?? '')
                      .toString()
                      .toLowerCase();

                  bool matchesSearch =
                      title.contains(_searchQuery) ||
                      location.contains(_searchQuery) ||
                      desc.contains(_searchQuery);

                  bool matchesDate = true;
                  if (_selectedDate != null) {
                    if (event['date'] != null) {
                      final eventDate = DateTime.parse(event['date']);
                      matchesDate =
                          eventDate.year == _selectedDate!.year &&
                          eventDate.month == _selectedDate!.month &&
                          eventDate.day == _selectedDate!.day;
                    } else {
                      matchesDate = false;
                    }
                  }

                  return matchesSearch && matchesDate;
                }).toList();

                if (events.isEmpty) {
                  return const Center(
                    child: Text(
                      'No Upcoming Events',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshEvents,
                  child: AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
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
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Event Image (if available)
                                    if (event['imageUrl'] != null &&
                                        event['imageUrl'].toString().isNotEmpty)
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(12),
                                            ),
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    FullScreenImageViewer(
                                                      imageUrl:
                                                          event['imageUrl'],
                                                    ),
                                              ),
                                            );
                                          },
                                          child: Hero(
                                            tag: 'event-${event['imageUrl']}',
                                            child: Image.network(
                                              ApiService.fixImageUrl(
                                                event['imageUrl'],
                                              )!,
                                              height: 150,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      height: 150,
                                                      color: Colors.grey[200],
                                                      child: const Icon(
                                                        Icons
                                                            .image_not_supported,
                                                        color: Colors.grey,
                                                        size: 40,
                                                      ),
                                                    );
                                                  },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      leading: Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            AutoSizeText(
                                              DateFormat('d').format(
                                                DateTime.parse(event['date']),
                                              ),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Theme.of(
                                                  context,
                                                ).primaryColor,
                                              ),
                                              maxLines: 1,
                                            ),
                                            AutoSizeText(
                                              DateFormat('MMM')
                                                  .format(
                                                    DateTime.parse(
                                                      event['date'],
                                                    ),
                                                  )
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(
                                                  context,
                                                ).primaryColor,
                                              ),
                                              maxLines: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                      title: AutoSizeText(
                                        event['title'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          AutoSizeText(
                                            DateFormat.jm().format(
                                              DateTime.parse(event['date']),
                                            ),
                                            maxLines: 1,
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.location_on,
                                                      size: 14,
                                                      color: Colors.grey,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: AutoSizeText(
                                                        event['location'],
                                                        style: const TextStyle(
                                                          color: Colors.grey,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                        minFontSize: 10,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (event['createdAt'] != null)
                                                Text(
                                                  'Posted ${timeago.format(DateTime.parse(event['createdAt']))}',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade500,
                                                    fontSize: 10,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Edit Button
                                          if (AuthService()
                                                      .currentUser
                                                      ?.isAdmin ==
                                                  true ||
                                              (AuthService().currentUser?.uid !=
                                                      null &&
                                                  AuthService()
                                                          .currentUser!
                                                          .uid ==
                                                      event['organizerId']))
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Colors.blue,
                                              ),
                                              onPressed: () async {
                                                final result =
                                                    await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            EditEventScreen(
                                                              event: event,
                                                            ),
                                                      ),
                                                    );
                                                if (result == true) {
                                                  _refreshEvents();
                                                }
                                              },
                                            ),
                                          // Delete Button
                                          if (AuthService()
                                                      .currentUser
                                                      ?.isAdmin ==
                                                  true ||
                                              (AuthService().currentUser?.uid !=
                                                      null &&
                                                  AuthService()
                                                          .currentUser!
                                                          .uid ==
                                                      event['organizerId']))
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              onPressed: () {
                                                QuickAlert.show(
                                                  context: context,
                                                  type: QuickAlertType.confirm,
                                                  text:
                                                      'Do you want to delete this event?',
                                                  confirmBtnText: 'Delete',
                                                  cancelBtnText: 'Cancel',
                                                  confirmBtnColor: Colors.red,
                                                  onConfirmBtnTap: () async {
                                                    Navigator.pop(context);
                                                    try {
                                                      await ApiService.deleteEvent(
                                                        event['_id'],
                                                      );
                                                      _refreshEvents();
                                                      if (context.mounted) {
                                                        QuickAlert.show(
                                                          context: context,
                                                          type: QuickAlertType
                                                              .success,
                                                          text:
                                                              'Deleted successfully!',
                                                        );
                                                      }
                                                    } catch (e) {
                                                      if (context.mounted) {
                                                        QuickAlert.show(
                                                          context: context,
                                                          type: QuickAlertType
                                                              .error,
                                                          text:
                                                              'Error deleting: $e',
                                                        );
                                                      }
                                                    }
                                                  },
                                                );
                                              },
                                            ),
                                          // Share Button
                                          IconButton(
                                            icon: const Icon(
                                              Icons.share,
                                              color: Colors.green,
                                            ),
                                            onPressed: () {
                                              Share.share(
                                                'Check out this event: ${event['title']}\n'
                                                'Date: ${DateFormat.yMMMMEEEEd().format(DateTime.parse(event['date']))} at ${DateFormat.jm().format(DateTime.parse(event['date']))}\n'
                                                'Location: ${event['location']}\n\n'
                                                '${event['description']}',
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
                                                EventViewerScreen(event: event),
                                          ),
                                        );
                                      },
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
          ),
        ],
      ),
      floatingActionButton:
          (AuthService().currentUser?.isAdmin == true ||
              [
                'alumni',
                'hod',
                'faculty',
              ].contains(AuthService().currentUser?.role))
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEventScreen(),
                  ),
                );
                if (result == true) {
                  _refreshEvents();
                }
              },
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
