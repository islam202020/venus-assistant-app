import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart'; // To access UserModel
import 'dart:async';

// Screen 1: Shows the list of available quizzes
class DelegateQuizListScreen extends StatelessWidget {
  final UserModel user;
  const DelegateQuizListScreen({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
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
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.quiz_outlined, color: Colors.indigo),
                title: Text(quizDoc['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("المدة: ${quizDoc['duration']} دقيقة"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        QuizInfoScreen(user: user, quizDoc: quizDoc),
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

// Screen 2: Asks for delegate's name and code before starting
class QuizInfoScreen extends StatefulWidget {
  final UserModel user;
  final DocumentSnapshot quizDoc;
  const QuizInfoScreen({required this.user, required this.quizDoc, super.key});

  @override
  State<QuizInfoScreen> createState() => _QuizInfoScreenState();
}

class _QuizInfoScreenState extends State<QuizInfoScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _startQuiz() {
    if (_nameController.text.isEmpty || _codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء إدخال الاسم والكود')));
      return;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => QuizTakingScreen(
        user: widget.user,
        quizDoc: widget.quizDoc,
        delegateName: _nameController.text,
        delegateCode: _codeController.text,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.quizDoc['name'])),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("للبدء، الرجاء إدخال بياناتك",
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 30),
            TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "الاسم الثلاثي")),
            const SizedBox(height: 16),
            TextField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: "الكود")),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _startQuiz,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text("بدء الاختبار"),
            )
          ],
        ),
      ),
    );
  }
}

// Screen 3: The actual quiz-taking interface
class QuizTakingScreen extends StatefulWidget {
  final UserModel user;
  final DocumentSnapshot quizDoc;
  final String delegateName;
  final String delegateCode;

  const QuizTakingScreen({
    required this.user,
    required this.quizDoc,
    required this.delegateName,
    required this.delegateCode,
    super.key,
  });

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  List<QueryDocumentSnapshot> _questions = [];
  bool _isLoading = true;
  int _currentQuestionIndex = 0;
  Timer? _timer;
  int _timeRemaining = 0;
  final Map<int, int> _selectedAnswers =
      {}; // questionIndex -> selectedOptionIndex

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.quizDoc.id)
        .collection('questions')
        .get();
    if (mounted) {
      setState(() {
        _questions = snapshot.docs;
        _timeRemaining = (widget.quizDoc['duration'] as int) * 60;
        _isLoading = false;
      });
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        if (mounted) setState(() => _timeRemaining--);
      } else {
        _timer?.cancel();
        _submitQuiz();
      }
    });
  }

  // --- UPDATED FUNCTION ---
  Future<String> _findSectorNameForDelegate(String delegatePort) async {
    try {
      // Find the outlet document by its number
      final outletQuery = await FirebaseFirestore.instance
          .collection('outlets')
          .where('number', isEqualTo: delegatePort)
          .limit(1)
          .get();

      if (outletQuery.docs.isNotEmpty) {
        final outletDoc = outletQuery.docs.first;
        final sectorId = outletDoc.data()['sectorId'] as String?;

        if (sectorId != null) {
          // Find the sector document by its ID
          final sectorDoc = await FirebaseFirestore.instance
              .collection('sectors')
              .doc(sectorId)
              .get();
          if (sectorDoc.exists) {
            return sectorDoc.data()?['name'] ?? 'قطاع غير معروف';
          }
        }
      }
    } catch (e) {
      debugPrint('Error finding sector for delegate: $e');
    }
    return 'قطاع غير معروف'; // Fallback
  }

  Future<void> _submitQuiz() async {
    // Made async
    _timer?.cancel();
    int score = 0;
    List<Map<String, dynamic>> detailedReport = [];

    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final correctAnswerIndex = question['correctAnswerIndex'];
      final selectedAnswerIndex = _selectedAnswers[i];
      final isCorrect = correctAnswerIndex == selectedAnswerIndex;
      if (isCorrect) {
        score++;
      }
      detailedReport.add({
        'question': question['questionText'],
        'selectedAnswer': selectedAnswerIndex != null
            ? question['options'][selectedAnswerIndex]
            : 'لم تتم الإجابة',
        'correctAnswer': question['options'][correctAnswerIndex],
        'isCorrect': isCorrect,
      });
    }

    // --- UPDATED LOGIC ---
    final String sectorName =
        await _findSectorNameForDelegate(widget.user.portId!);

    await FirebaseFirestore.instance.collection('quiz_results').add({
      'quizName': widget.quizDoc['name'],
      'quizId': widget.quizDoc.id,
      'delegateName': widget.delegateName,
      'delegateCode': widget.delegateCode,
      'delegatePort': widget.user.portId,
      'sector': sectorName, // Now reads from Firestore
      'score': score,
      'totalQuestions': _questions.length,
      'detailedReport': detailedReport,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) =>
            QuizResultScreen(score: score, totalQuestions: _questions.length),
      ));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
          appBar: AppBar(title: Text(widget.quizDoc['name'])),
          body: const Center(child: CircularProgressIndicator()));
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final options = currentQuestion['options'] as List<dynamic>;

    String timerText =
        '${(_timeRemaining ~/ 60).toString().padLeft(2, '0')}:${(_timeRemaining % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quizDoc['name']),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
                child: Text(timerText,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold))),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / _questions.length,
                color: Colors.green,
                backgroundColor: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
                "السؤال ${_currentQuestionIndex + 1}: ${currentQuestion['questionText']}",
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            ...options.asMap().entries.map((entry) {
              int idx = entry.key;
              String text = entry.value as String;
              return RadioListTile<int>(
                title: Text(text),
                value: idx,
                groupValue: _selectedAnswers[_currentQuestionIndex],
                onChanged: (value) {
                  setState(
                      () => _selectedAnswers[_currentQuestionIndex] = value!);
                },
              );
            }),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                if (_currentQuestionIndex < _questions.length - 1) {
                  setState(() => _currentQuestionIndex++);
                } else {
                  _submitQuiz();
                }
              },
              child: Text(_currentQuestionIndex < _questions.length - 1
                  ? "التالي"
                  : "إنهاء وتسليم"),
            ),
          ],
        ),
      ),
    );
  }
}

// Screen 4: Shows the final result to the delegate
class QuizResultScreen extends StatelessWidget {
  final int score;
  final int totalQuestions;
  const QuizResultScreen(
      {required this.score, required this.totalQuestions, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("النتيجة"), automaticallyImplyLeading: false),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("لقد أكملت الاختبار!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text("نتيجتك هي", style: TextStyle(fontSize: 20)),
            Text("$score / $totalQuestions",
                style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.green)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text("العودة إلى الصفحة الرئيسية"),
            ),
          ],
        ),
      ),
    );
  }
}
