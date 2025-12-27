import 'dart:io';
import 'package:ccet_alumini_app/services/api_service.dart';
import 'package:ccet_alumini_app/widgets/full_screen_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class JobViewerScreen extends StatefulWidget {
  final Map<String, dynamic> job;

  const JobViewerScreen({super.key, required this.job});

  @override
  State<JobViewerScreen> createState() => _JobViewerScreenState();
}

class _JobViewerScreenState extends State<JobViewerScreen> {
  bool _downloading = false;

  Future<void> _openPdf(String url) async {
    setState(() => _downloading = true);
    try {
      final fixedUrl = ApiService.fixImageUrl(url)!;
      final response = await http.get(Uri.parse(fixedUrl));
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File(
          '${dir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PdfViewerPage(path: file.path),
            ),
          );
        }
      } else {
        throw Exception('Failed to download PDF');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final images = List<String>.from(job['images'] ?? []);
    final attachments = List<String>.from(job['attachments'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: Text(job['title']),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Carousel
            if (images.isNotEmpty)
              Container(
                height: 250,
                child: PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final imageUrl = ApiService.fixImageUrl(images[index])!;
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                FullScreenImageViewer(imageUrl: imageUrl),
                          ),
                        );
                      },
                      child: Hero(
                        tag: 'job-image-$index-${job['_id'] ?? job['title']}',
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    );
                  },
                ),
              ),

            AnimationLimiter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 375),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: [
                      Text(
                        job['company'],
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            job['location'],
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.work, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            job['type'],
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (job['link'] != null &&
                          job['link'].toString().isNotEmpty) ...[
                        const Text(
                          "Application Link:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          job['link'],
                          style: const TextStyle(color: Colors.blue),
                        ),
                        const SizedBox(height: 16),
                      ],

                      const Text(
                        "Description",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        job['description'],
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 24),

                      if (attachments.isNotEmpty) ...[
                        const Text(
                          "Attachments",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...attachments
                            .map(
                              (url) => Card(
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.picture_as_pdf,
                                    color: Colors.red,
                                  ),
                                  title: const Text("View Attachment (PDF)"),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                  onTap: () => _openPdf(url),
                                ),
                              ),
                            )
                            .toList(),
                      ],
                      if (_downloading)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PdfViewerPage extends StatelessWidget {
  final String path;
  const PdfViewerPage({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PDF Viewer")),
      body: PDFView(filePath: path),
    );
  }
}
