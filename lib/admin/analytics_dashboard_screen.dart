import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_quiz_reports.dart'; // **NEW**: Import the new reports screen

// --- Analytics Dashboard Screen with Live Data ---
class AdminAnalyticsDashboard extends StatefulWidget {
  const AdminAnalyticsDashboard({super.key});

  @override
  State<AdminAnalyticsDashboard> createState() =>
      _AdminAnalyticsDashboardState();
}

class _AdminAnalyticsDashboardState extends State<AdminAnalyticsDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير والإحصائيات'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("نظرة عامة",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.indigo, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  // **NEW**: Made the card tappable
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const AdminQuizReportsListScreen(),
                      ));
                    },
                    child: FutureBuilder<double>(
                      future: _calculateAverageScore(),
                      builder: (context, snapshot) {
                        final title = "متوسط الدرجات (اضغط للتفاصيل)";
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const _AnalyticsCard(
                              title: "متوسط الدرجات (اضغط للتفاصيل)",
                              value: "...",
                              icon: Icons.star,
                              color: Colors.amber);
                        }
                        final score = snapshot.data ?? 0.0;
                        final percentage = score * 100;
                        return _AnalyticsCard(
                            title: title,
                            value: "${percentage.toStringAsFixed(1)}%",
                            icon: Icons.star,
                            color: Colors.amber);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FutureBuilder<int>(
                      future: _calculateTotalOutlets(),
                      builder: (context, snapshot) {
                        return _AnalyticsCard(
                            title: "إجمالي المنافذ",
                            value: snapshot.data?.toString() ?? '...',
                            icon: Icons.store,
                            color: Colors.blue);
                      }),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text("المحتوى الأكثر مشاهدة",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.indigo, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FutureBuilder<List<_ContentData>>(
                    future: _getTopViewedContent(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                            child: Text('حدث خطأ: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                            child: Text('لا توجد بيانات مشاهدات لعرضها.'));
                      }
                      return _BarChart(data: snapshot.data!);
                    }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<double> _calculateAverageScore() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('quiz_results').get();
    if (snapshot.docs.isEmpty) {
      return 0.0;
    }
    double totalScore = 0;
    double totalQuestions = 0;
    for (var doc in snapshot.docs) {
      totalScore += (doc.data()['score'] as num?)?.toDouble() ?? 0.0;
      totalQuestions +=
          (doc.data()['totalQuestions'] as num?)?.toDouble() ?? 1.0;
    }
    if (totalQuestions == 0) return 0.0;
    return totalScore / totalQuestions;
  }

  Future<int> _calculateTotalOutlets() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('outlets').get();
    return snapshot.docs.length;
  }

  Future<List<_ContentData>> _getTopViewedContent() async {
    List<_ContentData> allContent = [];

    try {
      final contentSnapshot =
          await FirebaseFirestore.instance.collection('content').get();
      for (var doc in contentSnapshot.docs) {
        final data = doc.data();
        final title = data['title'] ?? 'بدون عنوان';
        final viewCount = (data['viewCount'] as int?) ?? 0;
        allContent.add(_ContentData(title, viewCount));
      }
    } catch (e) {
      // Handle error
    }

    try {
      final trainingSectionsSnapshot = await FirebaseFirestore.instance
          .collection('training_sections')
          .get();
      for (var sectionDoc in trainingSectionsSnapshot.docs) {
        final sectionData = sectionDoc.data();
        final sectionName = sectionData['name'] ?? 'قسم تدريب';
        final sectionViewCount = (sectionData['viewCount'] as int?) ?? 0;
        allContent.add(_ContentData(sectionName, sectionViewCount));

        final videosSnapshot =
            await sectionDoc.reference.collection('videos').get();
        for (var videoDoc in videosSnapshot.docs) {
          final videoData = videoDoc.data();
          final videoTitle = videoData['title'] ?? 'فيديو بدون عنوان';
          final videoViewCount = (videoData['viewCount'] as int?) ?? 0;
          allContent.add(_ContentData(videoTitle, videoViewCount));
        }
      }
    } catch (e) {
      // Handle error
    }

    allContent.sort((a, b) => b.value.compareTo(a.value));
    return allContent.take(10).toList();
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentData {
  final String label;
  final int value;
  _ContentData(this.label, this.value);
}

class _BarChart extends StatelessWidget {
  final List<_ContentData> data;
  const _BarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxValue = data.isEmpty ? 1 : data.map((d) => d.value).reduce(max);
    return Column(
      children: data.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  item.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final barWidth = maxValue == 0
                        ? 0
                        : (item.value / maxValue) * constraints.maxWidth;
                    return Stack(
                      children: [
                        Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        Container(
                          height: 20,
                          width: barWidth.toDouble(),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(item.value.toString(),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
