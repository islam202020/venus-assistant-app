import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'main.dart'; // To access UserModel

// Screen 1: Shows the list of quiz reports
class ReportsScreen extends StatefulWidget {
  final UserModel user;
  const ReportsScreen({required this.user, super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Query _query;

  @override
  void initState() {
    super.initState();
    // Admin sees all reports. Manager sees only reports from their sector.
    if (widget.user.role == 'Admin') {
      _query = FirebaseFirestore.instance
          .collection('quiz_results')
          .orderBy('timestamp', descending: true);
    } else {
      // Manager
      _query = FirebaseFirestore.instance
          .collection('quiz_results')
          // --- FIX: Use sectorId for managers ---
          .where('sector', isEqualTo: widget.user.sectorId)
          .orderBy('timestamp', descending: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('لا توجد تقارير اختبارات حالياً'));
        }

        final reports = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final reportDoc = reports[index];
            final reportData = reportDoc.data() as Map<String, dynamic>;
            final score = reportData['score'] ?? 0;
            final total = reportData['totalQuestions'] ?? 0;
            final timestamp = reportData['timestamp'] as Timestamp?;
            final formattedDate = timestamp != null
                ? DateFormat('yyyy-MM-dd – kk:mm').format(timestamp.toDate())
                : 'غير معروف';

            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: score / (total == 0 ? 1 : total) >= 0.5
                      ? Colors.green
                      : Colors.red,
                  foregroundColor: Colors.white,
                  child: Text("$score/$total"),
                ),
                title: Text(
                    "${reportData['delegateName'] ?? 'اسم غير مسجل'} (منفذ ${reportData['delegatePort'] ?? 'N/A'})",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    "اختبار: ${reportData['quizName']}\nكود: ${reportData['delegateCode']} - $formattedDate"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ReportDetailScreen(reportDoc: reportDoc),
                  ));
                },
              ),
            );
          },
        );
      },
    );
  }
}

// Screen 2: Shows the detailed breakdown of a single quiz report
class ReportDetailScreen extends StatelessWidget {
  final DocumentSnapshot reportDoc;
  const ReportDetailScreen({required this.reportDoc, super.key});

  @override
  Widget build(BuildContext context) {
    final data = reportDoc.data() as Map<String, dynamic>;
    final List<dynamic> detailedReport = data['detailedReport'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text("تفاصيل اختبار ${data['delegateName'] ?? ''}"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: detailedReport.length,
        itemBuilder: (context, index) {
          final item = detailedReport[index] as Map<String, dynamic>;
          final bool isCorrect = item['isCorrect'] ?? false;
          final String selectedAnswer =
              item['selectedAnswer'] ?? 'لم تتم الإجابة';
          final String correctAnswer = item['correctAnswer'] ?? 'غير محدد';

          return Card(
            color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("السؤال ${index + 1}: ${item['question']}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text.rich(TextSpan(children: [
                    const TextSpan(
                        text: "إجابة المندوب: ",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: selectedAnswer,
                        style: TextStyle(
                            color: isCorrect ? Colors.green : Colors.red)),
                  ])),
                  if (!isCorrect)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text.rich(TextSpan(children: [
                        const TextSpan(
                            text: "الإجابة الصحيحة: ",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(
                            text: correctAnswer,
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold)),
                      ])),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
