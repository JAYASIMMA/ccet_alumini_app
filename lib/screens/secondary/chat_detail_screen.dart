import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';

class ChatDetailScreen extends StatefulWidget {
  final String targetUid;
  final String targetName;

  const ChatDetailScreen({
    super.key,
    required this.targetUid,
    required this.targetName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String _currentUid = AuthService().currentUser?.uid ?? '';
  List<dynamic> _messages = [];
  Timer? _pollingTimer;
  final ImagePicker _picker = ImagePicker();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    // Poll for new messages every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchMessages();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    final messages = await ApiService.getMessages(
      _currentUid,
      widget.targetUid,
    );
    // Mark incoming messages as read only if there are unread ones
    final hasUnread = messages.any(
      (m) => m['sender'] == widget.targetUid && m['readStatus'] != true,
    );

    if (hasUnread) {
      await ApiService.markMessagesAsRead(_currentUid, widget.targetUid);
    }

    if (mounted) {
      setState(() {
        _messages = messages;
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    await ApiService.sendMessage(_currentUid, widget.targetUid, content);
    _fetchMessages();
  }

  Future<void> _pickAndSendImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isSending = true);
    try {
      final String? imageUrl = await ApiService.uploadContentImage(
        File(image.path),
      );
      if (imageUrl != null) {
        await ApiService.sendMessage(
          _currentUid,
          widget.targetUid,
          null,
          imageUrl: imageUrl,
        );
        _fetchMessages();
      }
    } catch (e) {
      if (mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showZoomedImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PhotoView(
            imageProvider: NetworkImage(ApiService.fixImageUrl(imageUrl)!),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
    }
  }

  List<InlineSpan> _parseContent(String text, bool isMe) {
    final List<InlineSpan> spans = [];
    final urlRegExp = RegExp(r'(https?:\/\/[^\s]+)', caseSensitive: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int start = 0;
    urlRegExp.allMatches(text).forEach((match) {
      if (match.start > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, match.start),
            style: TextStyle(
              color: isMe
                  ? Colors.white
                  : (isDark ? Colors.white : Colors.black87),
            ),
          ),
        );
      }

      final url = match.group(0)!;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: () => _launchUrl(url),
            child: Text(
              url,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.blue,
                decoration: TextDecoration.underline,
                decorationColor: isMe ? Colors.white : Colors.blue,
              ),
            ),
          ),
        ),
      );
      start = match.end;
    });

    if (start < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(start),
          style: TextStyle(
            color: isMe
                ? Colors.white
                : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      );
    }

    return spans;
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    String label;
    if (msgDate == today) {
      label = 'Today';
    } else if (msgDate == yesterday) {
      label = 'Yesterday';
    } else {
      label = DateFormat.yMMMMd().format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade300
                  : Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.targetName),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2575FC), Color(0xFF00C6FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['sender'] == _currentUid;
                if (msg['timestamp'] == null) return const SizedBox.shrink();
                final DateTime messageDate = DateTime.parse(
                  msg['timestamp'],
                ).toLocal();
                final time = DateFormat('hh:mm a').format(messageDate);
                final isRead = msg['readStatus'] == true;

                // Date grouping logic
                bool showDateHeader = false;
                if (index == 0) {
                  showDateHeader = true;
                } else {
                  final prevMsg = _messages[index - 1];
                  final DateTime prevDate = DateTime.parse(
                    prevMsg['timestamp'],
                  ).toLocal();
                  if (messageDate.year != prevDate.year ||
                      messageDate.month != prevDate.month ||
                      messageDate.day != prevDate.day) {
                    showDateHeader = true;
                  }
                }

                return Column(
                  children: [
                    if (showDateHeader) _buildDateHeader(messageDate),
                    Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.only(
                          left: 12,
                          right: 12,
                          top: 8,
                          bottom: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xFF2575FC)
                              : (isDark
                                    ? const Color(0xFF333333)
                                    : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isMe
                                ? Radius.zero
                                : const Radius.circular(16),
                            bottomLeft: isMe
                                ? const Radius.circular(16)
                                : Radius.zero,
                          ),
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (msg['imageUrl'] != null &&
                                msg['imageUrl'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: GestureDetector(
                                  onTap: () =>
                                      _showZoomedImage(msg['imageUrl']),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      ApiService.fixImageUrl(msg['imageUrl'])!,
                                      width: double.infinity,
                                      height: 150,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.broken_image),
                                    ),
                                  ),
                                ),
                              ),
                            if (msg['content'] != null &&
                                msg['content'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: RichText(
                                  text: TextSpan(
                                    children: _parseContent(
                                      msg['content']!,
                                      isMe,
                                    ),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isMe
                                          ? Colors.white
                                          : (isDark
                                                ? Colors.white
                                                : Colors.black87),
                                    ),
                                  ),
                                ),
                              ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  time,
                                  style: TextStyle(
                                    color: isMe
                                        ? Colors.white70
                                        : (isDark
                                              ? Colors.white60
                                              : Colors.black54),
                                    fontSize: 10,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    isRead ? Icons.done_all : Icons.done,
                                    size: 15,
                                    color: isRead
                                        ? Colors.lightBlueAccent
                                        : Colors.white, // Blue tick for read
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom:
                  45, // Increased bottom padding to lift input area significantly
            ),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.image,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  onPressed: _pickAndSendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey.shade500 : Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF2C2C2C)
                          : Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF2575FC),
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _sendMessage,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
