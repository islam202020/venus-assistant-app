import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../reports_screens.dart'; // To reuse the ReportDetailScreen

// Screen 1: Shows a list of all quizzes for the admin
class AdminQuizReportsListScreen extends StatelessWidget {
  const AdminQuizReportsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقارير الاختبارات'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('quizzes')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا توجد اختبارات متاحة حالياً'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final quizDoc = snapshot.data!.docs[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: ListTile(
                  leading:
                      const Icon(Icons.quiz_outlined, color: Colors.indigo),
                  title: Text(quizDoc['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("المدة: ${quizDoc['duration']} دقيقة"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AdminQuizSubmissionsScreen(
                        quizId: quizDoc.id,
                        quizName: quizDoc['name'],
                      ),
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Screen 2: Shows all submissions for a specific quiz
class AdminQuizSubmissionsScreen extends StatelessWidget {
  final String quizId;
  final String quizName;
  const AdminQuizSubmissionsScreen(
      {required this.quizId, required this.quizName, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('نتائج: $quizName'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('quiz_results')
            .where('quizId', isEqualTo: quizId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('لم يقم أي مندوب بإجراء هذا الاختبار بعد.'));
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
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        score / total >= 0.5 ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                    child: Text("$score/$total"),
                  ),
                  title: Text(
                      "${reportData['delegateName'] ?? 'اسم غير مسجل'} (منفذ ${reportData['delegatePort']})",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      "كود: ${reportData['delegateCode']} - $formattedDate"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Reuse the existing ReportDetailScreen
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ReportDetailScreen(reportDoc: reportDoc),
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
