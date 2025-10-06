import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart'; // **NEW**: Import shimmer

// A model to hold the calculated score for each delegate
class _DelegateScore {
  final String name;
  final String portId;
  final double averageScore;
  final int quizCount;

  _DelegateScore({
    required this.name,
    required this.portId,
    required this.averageScore,
    required this.quizCount,
  });
}

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<List<_DelegateScore>> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = _calculateLeaderboard();
  }

  Future<List<_DelegateScore>> _calculateLeaderboard() async {
    // 1. Fetch all quiz results
    final snapshot =
        await FirebaseFirestore.instance.collection('quiz_results').get();

    if (snapshot.docs.isEmpty) {
      return [];
    }

    // 2. Group results by delegate portId
    final Map<String, List<QueryDocumentSnapshot>> delegateResults = {};
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final portId = data['delegatePort'] as String?;
      if (portId != null) {
        if (!delegateResults.containsKey(portId)) {
          delegateResults[portId] = [];
        }
        delegateResults[portId]!.add(doc);
      }
    }

    // 3. Calculate average score for each delegate
    final List<_DelegateScore> scores = [];
    delegateResults.forEach((portId, results) {
      double totalScore = 0;
      double totalPossibleScore = 0;
      String delegateName =
          (results.first.data() as Map<String, dynamic>)['delegateName'] ??
              'اسم غير معروف';

      for (var result in results) {
        final data = result.data() as Map<String, dynamic>;
        totalScore += (data['score'] as num?)?.toDouble() ?? 0.0;
        totalPossibleScore +=
            (data['totalQuestions'] as num?)?.toDouble() ?? 1.0;
      }

      double average = (totalPossibleScore == 0)
          ? 0.0
          : (totalScore / totalPossibleScore) * 100;

      scores.add(_DelegateScore(
        name: delegateName,
        portId: portId,
        averageScore: average,
        quizCount: results.length,
      ));
    });

    // 4. Sort the list by average score
    scores.sort((a, b) => b.averageScore.compareTo(a.averageScore));

    return scores;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_DelegateScore>>(
      future: _leaderboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // **NEW**: Show shimmer effect while loading
          return const _LeaderboardShimmer();
        }
        if (snapshot.hasError) {
          // **NEW**: Improved error state
          return _EmptyState(
            icon: Icons.error_outline,
            title: 'حدث خطأ',
            message: 'لا يمكن تحميل لوحة الصدارة الآن. حاول مرة أخرى.',
            color: Colors.red.shade400,
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // **NEW**: Show custom empty state
          return const _EmptyState(
            icon: Icons.leaderboard_outlined,
            title: 'لوحة الصدارة فارغة',
            message:
                'لم يقم أي مندوب بإجراء اختبارات بعد. كن أول من يتصدر القائمة!',
          );
        }

        final leaderboard = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: leaderboard.length,
          itemBuilder: (context, index) {
            final entry = leaderboard[index];
            final rank = index + 1;

            Widget rankWidget;
            Color cardColor = Colors.white;

            if (rank == 1) {
              rankWidget = Icon(Icons.emoji_events, color: Colors.amber[700]);
              cardColor = Colors.amber.shade50;
            } else if (rank == 2) {
              rankWidget = Icon(Icons.emoji_events, color: Colors.grey[400]);
              cardColor = Colors.grey.shade100;
            } else if (rank == 3) {
              rankWidget = Icon(Icons.emoji_events, color: Colors.brown[300]);
              cardColor = Colors.brown.shade50;
            } else {
              rankWidget = CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey.shade200,
                child: Text('$rank',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54)),
              );
            }

            return Card(
              color: cardColor,
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: ListTile(
                leading: rankWidget,
                title: Text(
                  '${entry.name} (منفذ ${entry.portId})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('أكمل ${entry.quizCount} اختبارات'),
                trailing: Text(
                  '${entry.averageScore.toStringAsFixed(1)}%',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green.shade700),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// **NEW**: Shimmer loading widget
class _LeaderboardShimmer extends StatelessWidget {
  const _LeaderboardShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: 8, // Display 8 shimmer items
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: ListTile(
              leading:
                  const CircleAvatar(radius: 12, backgroundColor: Colors.white),
              title: Container(
                height: 16,
                width: 150,
                color: Colors.white,
              ),
              subtitle: Container(
                height: 12,
                width: 100,
                color: Colors.white,
              ),
              trailing: Container(
                height: 20,
                width: 50,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }
}

// **NEW**: Custom empty state widget
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
