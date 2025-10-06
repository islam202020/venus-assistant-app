import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:shimmer/shimmer.dart';
import 'main.dart'; // For UserModel and launchExternalUrl

// --- REUSABLE WIDGETS ---

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color? color;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: color ?? Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// --- VIDEO & TRAINING SECTION ---

class VideoCard extends StatelessWidget {
  final String videoId;
  final String title;
  final String description;
  final VoidCallback onTap;

  const VideoCard(
      {required this.videoId,
      required this.title,
      required this.description,
      required this.onTap,
      super.key});

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  thumbnailUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 180,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : Container(
                          height: 180,
                          color: Colors.grey[200],
                          child:
                              const Center(child: CircularProgressIndicator())),
                  errorBuilder: (context, error, stack) => Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: const Center(
                          child: Icon(Icons.error_outline,
                              color: Colors.red, size: 40))),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 40),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TrainingSectionsScreen extends StatelessWidget {
  final UserModel user;
  final Function(Widget, {int bottomNavIndex}) onNavigate;
  const TrainingSectionsScreen(
      {required this.user, required this.onNavigate, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('training_sections')
          .orderBy('orderIndex')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _GridShimmer();
        }
        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const _EmptyState(
            icon: Icons.model_training_outlined,
            title: 'لا توجد أقسام',
            message: 'لم يقم الأدمن بإضافة أي أقسام تدريبية بعد.',
          );
        }

        return _buildGridView(context, snapshot.data!.docs);
      },
    );
  }

  Widget _buildGridView(
      BuildContext context, List<QueryDocumentSnapshot> docs) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final sectionName = doc['name'];

        void _incrementViewCount() {
          doc.reference.update({'viewCount': FieldValue.increment(1)});
        }

        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              _incrementViewCount();
              onNavigate(
                  VideoListScreen(sectionId: doc.id, sectionName: sectionName));
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.video_library_outlined,
                    size: 50, color: Colors.orange),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    sectionName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class VideoListScreen extends StatelessWidget {
  final String sectionId;
  final String sectionName;
  const VideoListScreen(
      {required this.sectionId, required this.sectionName, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('training_sections')
          .doc(sectionId)
          .collection('videos')
          .orderBy('orderIndex')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _VideoListShimmer();
        }
        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const _EmptyState(
            icon: Icons.videocam_off_outlined,
            title: 'لا توجد فيديوهات',
            message: 'لم يتم إضافة أي فيديوهات في هذا القسم بعد.',
          );
        }

        return _buildListView(context, snapshot.data!.docs);
      },
    );
  }

  Widget _buildListView(BuildContext context, List<DocumentSnapshot> docs) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final videoUrl = doc['youtubeUrl'];
        final title = doc['title'] ?? 'فيديو بدون عنوان';
        final description = doc['description'] ?? '';
        final videoId = YoutubePlayer.convertUrlToId(videoUrl);

        if (videoId == null) {
          return const SizedBox.shrink();
        }

        void _incrementViewCount() {
          doc.reference.update({'viewCount': FieldValue.increment(1)});
        }

        return VideoCard(
          videoId: videoId,
          title: title,
          description: description,
          onTap: () {
            _incrementViewCount();
            if (kIsWeb) {
              launchExternalUrl(context, videoUrl);
            } else {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(videoId: videoId)));
            }
          },
        );
      },
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  const VideoPlayerScreen({required this.videoId, super.key});
  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(autoPlay: true),
    );
  }

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("مشغل الفيديو"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
          child: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
      )),
    );
  }
}

// --- CONTENT SECTION (Instructions, Skills, Books) ---

class SectionContentBody extends StatefulWidget {
  final String sectionName;
  final UserModel user;

  const SectionContentBody({
    required this.sectionName,
    required this.user,
    super.key,
  });

  @override
  State<SectionContentBody> createState() => _SectionContentBodyState();
}

class _SectionContentBodyState extends State<SectionContentBody> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleItemTap(BuildContext context, DocumentSnapshot itemDoc) {
    itemDoc.reference.update({'viewCount': FieldValue.increment(1)});

    final itemData = itemDoc.data() as Map<String, dynamic>;
    final String title = itemData['title'] ?? 'تفاصيل';
    final String contentText = itemData['contentText'] ?? '';
    final String fileUrl = itemData['fileUrl'] ?? '';
    final String videoUrl = itemData['url'] ?? '';

    if (contentText.isNotEmpty) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ContentDetailScreen(
                title: title,
                content: contentText,
                imageUrl: fileUrl.isNotEmpty &&
                        (fileUrl.endsWith('.png') ||
                            fileUrl.endsWith('.jpg') ||
                            fileUrl.endsWith('.jpeg'))
                    ? fileUrl
                    : null,
              )));
      return;
    }

    if (videoUrl.isNotEmpty) {
      final videoId = YoutubePlayer.convertUrlToId(videoUrl);
      if (videoId != null) {
        if (kIsWeb) {
          launchExternalUrl(context, videoUrl);
        } else {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(videoId: videoId)));
        }
        return;
      }
    }

    if (fileUrl.isNotEmpty) {
      final path = Uri.parse(fileUrl).path.toLowerCase();
      if (path.endsWith('.pdf')) {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                NetworkPdfViewerScreen(url: fileUrl, title: title)));
        return;
      }
      if (path.endsWith('.jpg') ||
          path.endsWith('.png') ||
          path.endsWith('.jpeg')) {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ImageViewerScreen(url: fileUrl, title: title)));
        return;
      }
    }

    if (fileUrl.isNotEmpty) {
      launchExternalUrl(context, fileUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ابحث في ${widget.sectionName}...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('content')
                .where('section', isEqualTo: widget.sectionName)
                .orderBy('orderIndex')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _ListShimmer();
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.docs.isEmpty) {
                return _EmptyState(
                  icon: Icons.article_outlined,
                  title: 'لا يوجد محتوى',
                  message:
                      'لم يقم الأدمن بإضافة أي محتوى في قسم "${widget.sectionName}" بعد.',
                );
              }

              return _buildListView(context, snapshot.data!.docs);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListView(BuildContext context, List<DocumentSnapshot> allItems) {
    final filteredItems = _searchQuery.isEmpty
        ? allItems
        : allItems.where((doc) {
            final itemData = doc.data() as Map<String, dynamic>;
            final title = (itemData['title'] ?? '').toString().toLowerCase();
            return title.contains(_searchQuery);
          }).toList();

    if (filteredItems.isEmpty) {
      return const Center(child: Text("لا توجد نتائج بحث مطابقة."));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final itemDoc = filteredItems[index];
        final itemData = itemDoc.data() as Map<String, dynamic>;
        final title = itemData['title'] ?? 'بلا عنوان';

        final fileUrl = itemData['fileUrl'] ?? '';
        final isImage = fileUrl.toLowerCase().endsWith('.jpg') ||
            fileUrl.toLowerCase().endsWith('.png') ||
            fileUrl.toLowerCase().endsWith('.jpeg');

        return StyledListItem(
          index: index + 1,
          title: title,
          imageUrl: isImage ? fileUrl : null,
          onTap: () => _handleItemTap(context, itemDoc),
        );
      },
    );
  }
}

class StyledListItem extends StatelessWidget {
  final int index;
  final String title;
  final String? imageUrl;
  final VoidCallback onTap;

  const StyledListItem({
    required this.index,
    required this.title,
    this.imageUrl,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Row(
            children: [
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  child: Image.network(
                    imageUrl!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey),
                  ),
                ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: ClipPath(
                        clipper: AngledShapeClipper(),
                        child: Container(
                          width: 90,
                          color: imageUrl != null
                              ? Colors.orange.withOpacity(0.85)
                              : Colors.orange,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 15,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Text(
                          index.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 100, left: 16),
                          child: Text(
                            title,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AngledShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.lineTo(size.width * 0.3, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class ContentDetailScreen extends StatelessWidget {
  final String title;
  final String content;
  final String? imageUrl;

  const ContentDetailScreen(
      {required this.title, required this.content, this.imageUrl, super.key});

  List<Widget> _buildContentWidgets(String rawContent) {
    final List<Widget> widgets = [];
    final lines = rawContent.split('\n').map((line) => line.trim()).toList();

    for (var line in lines) {
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 10.0));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6.0, left: 8.0),
                  child: Icon(Icons.circle, size: 8, color: Colors.orange),
                ),
                Expanded(
                  child: Text(
                    line.substring(2),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              line,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 17,
                height: 1.6,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              if (imageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _buildContentWidgets(content),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ImageViewerScreen extends StatelessWidget {
  final String url;
  final String title;
  const ImageViewerScreen({required this.url, required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(title),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white),
      backgroundColor: Colors.black,
      body: Center(
          child: InteractiveViewer(
        panEnabled: false,
        boundaryMargin: const EdgeInsets.all(80),
        minScale: 0.5,
        maxScale: 4,
        child: Image.network(
          url,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
                child: Icon(Icons.error, color: Colors.red, size: 50));
          },
        ),
      )),
    );
  }
}

class NetworkPdfViewerScreen extends StatefulWidget {
  final String url;
  final String title;
  const NetworkPdfViewerScreen(
      {required this.url, required this.title, super.key});

  @override
  State<NetworkPdfViewerScreen> createState() => _NetworkPdfViewerScreenState();
}

class _NetworkPdfViewerScreenState extends State<NetworkPdfViewerScreen> {
  String? _localPath;
  bool _isLoading = true;
  String _loadingMessage = "جاري تحميل الملف...";

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.url));
      final dir = await getApplicationDocumentsDirectory();
      final fileName = widget.url.split('/').last;
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);
      if (mounted) {
        setState(() {
          _localPath = file.path;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = "فشل تحميل الملف: $e";
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("فشل تحميل الملف: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _isLoading
          ? Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(_loadingMessage),
              ],
            ))
          : _localPath != null
              ? PDFView(filePath: _localPath!)
              : Center(child: Text(_loadingMessage)),
    );
  }
}

// --- SHIMMER WIDGETS ---

class _ListShimmer extends StatelessWidget {
  const _ListShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }
}

class _GridShimmer extends StatelessWidget {
  const _GridShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }
}

class _VideoListShimmer extends StatelessWidget {
  const _VideoListShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 180, color: Colors.white),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 18, width: 200, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 14, width: 150, color: Colors.white),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
