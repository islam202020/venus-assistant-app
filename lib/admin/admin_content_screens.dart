import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart'; // For UserModel

// --- HUB for Content Management ---
class AdminContentManagementHub extends StatelessWidget {
  const AdminContentManagementHub({super.key});

  @override
  Widget build(BuildContext context) {
    final contentSections = [
      {
        'title': 'إدارة التعليمات',
        'icon': Icons.integration_instructions,
        'page': AdminContentManager(sectionName: 'التعليمات')
      },
      {
        'title': 'إدارة التدريب',
        'icon': Icons.model_training,
        'page': const AdminTrainingManagementScreen()
      },
      {
        'title': 'إدارة المهارات',
        'icon': Icons.psychology,
        'page': AdminContentManager(sectionName: 'تنمية المهارات')
      },
      {
        'title': 'إدارة الدفاتر',
        'icon': Icons.menu_book,
        'page': AdminContentManager(sectionName: 'الدفاتر')
      },
    ];

    return Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المحتوى'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: contentSections.length,
          itemBuilder: (context, index) {
            final section = contentSections[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading:
                    Icon(section['icon'] as IconData, color: Colors.indigo),
                title: Text(section['title'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => section['page'] as Widget));
                },
              ),
            );
          },
        ));
  }
}

// --- A complete manager for content sections (Add, Edit, Delete, Reorder) ---
class AdminContentManager extends StatefulWidget {
  final String sectionName;
  const AdminContentManager({required this.sectionName, super.key});

  @override
  State<AdminContentManager> createState() => _AdminContentManagerState();
}

class _AdminContentManagerState extends State<AdminContentManager> {
  void _showContentEditor({DocumentSnapshot? doc}) {
    final titleController = TextEditingController(text: doc?['title']);
    final contentController = TextEditingController(text: doc?['contentText']);
    final urlController = TextEditingController(text: doc?['url']);
    final fileUrlController = TextEditingController(text: doc?['fileUrl']);

    showDialog(
      context: context,
      builder: (context) {
        bool isVideoSection = widget.sectionName == 'تنمية المهارات';
        return AlertDialog(
          title: Text(doc == null ? "إضافة محتوى جديد" : "تعديل المحتوى"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'العنوان')),
                const SizedBox(height: 16),
                if (!isVideoSection)
                  TextField(
                      controller: contentController,
                      decoration:
                          const InputDecoration(labelText: 'المحتوى الكتابي'),
                      maxLines: 5),
                if (isVideoSection)
                  TextField(
                      controller: urlController,
                      decoration:
                          const InputDecoration(labelText: 'رابط يوتيوب')),
                const SizedBox(height: 16),
                if (!isVideoSection)
                  TextField(
                      controller: fileUrlController,
                      decoration: const InputDecoration(
                          labelText: 'رابط الصورة أو PDF (اختياري)')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("إلغاء")),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('الرجاء إدخال عنوان')));
                  return;
                }

                final contentData = {
                  'title': titleController.text,
                  'contentText': contentController.text,
                  'url': urlController.text,
                  'fileUrl': fileUrlController.text,
                  'section': widget.sectionName,
                  'timestamp': FieldValue.serverTimestamp(),
                };

                final collection =
                    FirebaseFirestore.instance.collection('content');

                if (doc == null) {
                  final query = await collection
                      .where('section', isEqualTo: widget.sectionName)
                      .get();
                  contentData['orderIndex'] = query.docs.length;
                  contentData['viewCount'] =
                      0; // **NEW**: Initialize view count
                  await collection.add(contentData);
                } else {
                  await doc.reference.update(contentData);
                }
                if (mounted) Navigator.of(context).pop();
              },
              child: const Text("حفظ"),
            ),
          ],
        );
      },
    );
  }

  void _deleteContent(DocumentReference docRef) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد الحذف"),
        content: const Text("هل أنت متأكد من رغبتك في حذف هذا العنصر نهائياً؟"),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("إلغاء")),
          TextButton(
            onPressed: () {
              docRef.delete();
              Navigator.of(context).pop();
            },
            child: const Text("حذف", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة: ${widget.sectionName}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('content')
            .where('section', isEqualTo: widget.sectionName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text("لا يوجد محتوى. اضغط على زر + للإضافة."));
          }

          List<DocumentSnapshot> items = snapshot.data!.docs;

          items.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>?;
            final bData = b.data() as Map<String, dynamic>?;
            final int orderA = aData?.containsKey('orderIndex') ?? false
                ? aData!['orderIndex']
                : items.length;
            final int orderB = bData?.containsKey('orderIndex') ?? false
                ? bData!['orderIndex']
                : items.length;
            return orderA.compareTo(orderB);
          });

          return ReorderableListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final doc = items[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                key: ValueKey(doc.id),
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.drag_handle),
                  title: Text(data['title'] ?? 'بلا عنوان'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showContentEditor(doc: doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteContent(doc.reference),
                      ),
                    ],
                  ),
                ),
              );
            },
            onReorder: (oldIndex, newIndex) {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final item = items.removeAt(oldIndex);
              items.insert(newIndex, item);

              final batch = FirebaseFirestore.instance.batch();
              for (int i = 0; i < items.length; i++) {
                batch.update(items[i].reference, {'orderIndex': i});
              }
              batch.commit();
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showContentEditor(),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- Training Sections Management Screen ---
class AdminTrainingManagementScreen extends StatefulWidget {
  const AdminTrainingManagementScreen({super.key});

  @override
  _AdminTrainingManagementScreenState createState() =>
      _AdminTrainingManagementScreenState();
}

class _AdminTrainingManagementScreenState
    extends State<AdminTrainingManagementScreen> {
  void _showSectionEditor({DocumentSnapshot? doc}) {
    final controller = TextEditingController(text: doc?['name']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(doc == null ? "إضافة قسم جديد" : "تعديل اسم القسم"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "اسم القسم"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final data = {
                  'name': controller.text,
                  'timestamp': FieldValue.serverTimestamp(),
                };

                final collection =
                    FirebaseFirestore.instance.collection('training_sections');

                if (doc == null) {
                  final query = await collection.get();
                  data['orderIndex'] = query.docs.length;
                  await collection.add(data);
                } else {
                  await doc.reference.update(data);
                }
                if (mounted) Navigator.of(context).pop();
              }
            },
            child: const Text("حفظ"),
          ),
        ],
      ),
    );
  }

  void _deleteSection(DocumentReference docRef) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد الحذف"),
        content:
            const Text("هل أنت متأكد؟ سيتم حذف القسم وكل الفيديوهات بداخله."),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("إلغاء")),
          TextButton(
            onPressed: () {
              docRef.delete();
              Navigator.of(context).pop();
            },
            child: const Text("حذف", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة أقسام التدريب'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('training_sections')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return const Center(
                child: Text('لا توجد أقسام. قم بإضافة قسم جديد.'));

          List<DocumentSnapshot> items = snapshot.data!.docs;

          items.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>?;
            final bData = b.data() as Map<String, dynamic>?;
            final int orderA = aData?.containsKey('orderIndex') ?? false
                ? aData!['orderIndex']
                : items.length;
            final int orderB = bData?.containsKey('orderIndex') ?? false
                ? bData!['orderIndex']
                : items.length;
            return orderA.compareTo(orderB);
          });

          return ReorderableListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final doc = items[index];
              return Card(
                key: ValueKey(doc.id),
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.drag_handle),
                  title: Text(doc['name']),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AdminVideoManagerScreen(
                          sectionId: doc.id, sectionName: doc['name']))),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showSectionEditor(doc: doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteSection(doc.reference),
                      ),
                    ],
                  ),
                ),
              );
            },
            onReorder: (oldIndex, newIndex) {
              if (oldIndex < newIndex) newIndex -= 1;
              final item = items.removeAt(oldIndex);
              items.insert(newIndex, item);

              final batch = FirebaseFirestore.instance.batch();
              for (int i = 0; i < items.length; i++) {
                batch.update(items[i].reference, {'orderIndex': i});
              }
              batch.commit();
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSectionEditor(),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- Video Management Screen ---
class AdminVideoManagerScreen extends StatelessWidget {
  final String sectionId;
  final String sectionName;
  const AdminVideoManagerScreen(
      {required this.sectionId, required this.sectionName, super.key});

  void _showVideoEditor(BuildContext context, {DocumentSnapshot? doc}) {
    final titleController = TextEditingController(text: doc?['title']);
    final descController = TextEditingController(text: doc?['description']);
    final urlController = TextEditingController(text: doc?['youtubeUrl']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(doc == null ? "إضافة فيديو جديد" : "تعديل الفيديو"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleController,
                  decoration: const InputDecoration(hintText: "اسم الفيديو")),
              TextField(
                  controller: descController,
                  decoration: const InputDecoration(hintText: "وصف (اختياري)")),
              TextField(
                  controller: urlController,
                  decoration: const InputDecoration(hintText: "رابط يوتيوب")),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  urlController.text.isNotEmpty) {
                final videoData = {
                  'title': titleController.text,
                  'description': descController.text,
                  'youtubeUrl': urlController.text,
                  'timestamp': FieldValue.serverTimestamp(),
                };

                final collectionRef = FirebaseFirestore.instance
                    .collection('training_sections')
                    .doc(sectionId)
                    .collection('videos');

                if (doc == null) {
                  final query = await collectionRef.get();
                  videoData['orderIndex'] = query.docs.length;
                  videoData['viewCount'] = 0; // **NEW**: Initialize view count
                  collectionRef.add(videoData);
                } else {
                  doc.reference.update(videoData);
                }

                if (context.mounted) Navigator.of(context).pop();
              }
            },
            child: const Text("حفظ"),
          ),
        ],
      ),
    );
  }

  void _deleteVideo(BuildContext context, DocumentReference docRef) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد الحذف"),
        content: const Text("هل أنت متأكد من رغبتك في حذف هذا الفيديو؟"),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("إلغاء")),
          TextButton(
            onPressed: () {
              docRef.delete();
              Navigator.of(context).pop();
            },
            child: const Text("حذف", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("إدارة فيديوهات: $sectionName"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('training_sections')
            .doc(sectionId)
            .collection('videos')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return const Center(
                child: Text('لا توجد فيديوهات. اضغط على زر + للإضافة'));

          List<DocumentSnapshot> items = snapshot.data!.docs;

          items.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>?;
            final bData = b.data() as Map<String, dynamic>?;
            final int orderA = aData?.containsKey('orderIndex') ?? false
                ? aData!['orderIndex']
                : items.length;
            final int orderB = bData?.containsKey('orderIndex') ?? false
                ? bData!['orderIndex']
                : items.length;
            return orderA.compareTo(orderB);
          });

          return ReorderableListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final doc = items[index];
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                key: ValueKey(doc.id),
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.drag_handle),
                  title: Text(data['title'] ?? ''),
                  subtitle: Text(data['description'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showVideoEditor(context, doc: doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteVideo(context, doc.reference),
                      ),
                    ],
                  ),
                ),
              );
            },
            onReorder: (oldIndex, newIndex) {
              if (oldIndex < newIndex) newIndex -= 1;
              final item = items.removeAt(oldIndex);
              items.insert(newIndex, item);

              final batch = FirebaseFirestore.instance.batch();
              for (int i = 0; i < items.length; i++) {
                batch.update(items[i].reference, {'orderIndex': i});
              }
              batch.commit();
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showVideoEditor(context),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// =================================================================
// START: ADMIN QUIZ AND NOTIFICATIONS SCREENS
// =================================================================

class AdminQuizScreen extends StatefulWidget {
  const AdminQuizScreen({super.key});

  @override
  State<AdminQuizScreen> createState() => _AdminQuizScreenState();
}

class _AdminQuizScreenState extends State<AdminQuizScreen> {
  // MODIFIED: _addQuiz now includes delegate selection
  void _addQuiz() {
    final nameController = TextEditingController();
    final durationController = TextEditingController();
    List<UserModel> selectedDelegates = [];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("إنشاء اختبار جديد"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: "اسم الاختبار")),
                    TextField(
                        controller: durationController,
                        decoration:
                            const InputDecoration(labelText: "المدة بالدقائق"),
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    const Text("توجيه الاختبار إلى (اختياري):"),
                    // A button to open the delegate selection dialog
                    ActionChip(
                      avatar: const Icon(Icons.group_add),
                      label: Text("اختيار ${selectedDelegates.length} مناديب"),
                      onPressed: () async {
                        final result = await showDialog<List<UserModel>>(
                          context: context,
                          builder: (_) => const _DelegateSelectionDialog(),
                        );
                        if (result != null) {
                          setDialogState(() {
                            selectedDelegates = result;
                          });
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("إلغاء")),
            ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty &&
                      durationController.text.isNotEmpty) {
                    // Save selected delegate IDs (portId)
                    final targetDelegateIds = selectedDelegates
                        .map((user) => user.portId)
                        .where((id) => id != null)
                        .cast<String>()
                        .toList();

                    FirebaseFirestore.instance.collection('quizzes').add({
                      'name': nameController.text,
                      'duration': int.tryParse(durationController.text) ?? 0,
                      'timestamp': FieldValue.serverTimestamp(),
                      'targetDelegates': targetDelegateIds, // NEW FIELD
                    });
                    Navigator.of(context).pop();
                  }
                },
                child: const Text("إنشاء")),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الاختبارات'),
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
            return const Center(
                child: Text('لا توجد اختبارات. قم بإنشاء اختبار جديد.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final quizDoc = snapshot.data!.docs[index];
              final data = quizDoc.data() as Map<String, dynamic>;
              final targets = data.containsKey('targetDelegates')
                  ? (data['targetDelegates'] as List).length
                  : 0;

              return ListTile(
                title: Text(quizDoc['name']),
                subtitle: Text(
                    "المدة: ${quizDoc['duration']} دقيقة\nالمستهدفون: ${targets > 0 ? '$targets مناديب' : 'الكل'}"),
                isThreeLine: true,
                trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => quizDoc.reference.delete()),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => AdminQuestionListScreen(
                        quizId: quizDoc.id, quizName: quizDoc['name']))),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addQuiz,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AdminQuestionListScreen extends StatefulWidget {
  final String quizId;
  final String quizName;
  const AdminQuestionListScreen(
      {required this.quizId, required this.quizName, super.key});

  @override
  State<AdminQuestionListScreen> createState() =>
      _AdminQuestionListScreenState();
}

class _AdminQuestionListScreenState extends State<AdminQuestionListScreen> {
  int _correctAnswerIndex = 0;

  void _addQuestion() {
    final questionController = TextEditingController();
    final option1Controller = TextEditingController();
    final option2Controller = TextEditingController();
    final option3Controller = TextEditingController();
    final option4Controller = TextEditingController();
    _correctAnswerIndex = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("إضافة سؤال جديد"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: questionController,
                      decoration:
                          const InputDecoration(labelText: "نص السؤال")),
                  const SizedBox(height: 10),
                  _buildOptionField(option1Controller, 0, _correctAnswerIndex,
                      (val) => setDialogState(() => _correctAnswerIndex = val)),
                  _buildOptionField(option2Controller, 1, _correctAnswerIndex,
                      (val) => setDialogState(() => _correctAnswerIndex = val)),
                  _buildOptionField(option3Controller, 2, _correctAnswerIndex,
                      (val) => setDialogState(() => _correctAnswerIndex = val)),
                  _buildOptionField(option4Controller, 3, _correctAnswerIndex,
                      (val) => setDialogState(() => _correctAnswerIndex = val)),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("إلغاء")),
              ElevatedButton(
                  onPressed: () {
                    FirebaseFirestore.instance
                        .collection('quizzes')
                        .doc(widget.quizId)
                        .collection('questions')
                        .add({
                      'questionText': questionController.text,
                      'options': [
                        option1Controller.text,
                        option2Controller.text,
                        option3Controller.text,
                        option4Controller.text,
                      ],
                      'correctAnswerIndex': _correctAnswerIndex,
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text("إضافة السؤال")),
            ],
          );
        });
      },
    );
  }

  Widget _buildOptionField(TextEditingController controller, int index,
      int groupValue, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Radio<int>(
          value: index,
          groupValue: groupValue,
          onChanged: (value) => onChanged(value!),
        ),
        Expanded(
            child: TextField(
                controller: controller,
                decoration: InputDecoration(hintText: "خيار ${index + 1}"))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("أسئلة: ${widget.quizName}"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('quizzes')
            .doc(widget.quizId)
            .collection('questions')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return const Center(
                child: Text('لا توجد أسئلة. قم بإضافة سؤال جديد.'));

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final options = doc['options'] as List<dynamic>;
              return ListTile(
                title: Text(doc['questionText']),
                subtitle: Text(
                    "الإجابة الصحيحة: ${options[doc['correctAnswerIndex']]}"),
                trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => doc.reference.delete()),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addQuestion,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// MODIFIED: AdminNotificationsScreen to include 'مشرف' in search
class AdminNotificationsScreen extends StatefulWidget {
  final UserModel user;
  const AdminNotificationsScreen({required this.user, super.key});
  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _messageController = TextEditingController();
  final _fileUrlController = TextEditingController();
  bool _isSending = false;

  String _searchQuery = '';
  String _searchType = 'مندوب'; // 'مندوب', 'مشرف', or 'مدير'

  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  List<UserModel> _selectedUsers = [];
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final users =
          snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
      if (mounted) {
        setState(() {
          _allUsers = users;
          _filterUsers();
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to load users: $e')));
      }
    }
  }

  void _filterUsers() {
    final query = _searchQuery.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final roleMatch = user.role == _searchType;
        if (!roleMatch) return false;

        if (query.isEmpty) return true;

        final nameMatch = user.name.toLowerCase().contains(query);
        final idMatch = (user.portId?.contains(query) ?? false) ||
            (user.sectorId?.toLowerCase().contains(query) ?? false);

        return nameMatch || idMatch;
      }).toList();
    });
  }

  Future<void> _sendNotification() async {
    if (_messageController.text.isEmpty && _fileUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('الرجاء كتابة رسالة أو إرفاق رابط ملف')));
      return;
    }
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار مستخدم واحد على الأقل')));
      return;
    }

    setState(() => _isSending = true);

    // MODIFIED: Logic to get correct ID based on role
    final recipientIds = _selectedUsers
        .map((user) {
          if (user.role == 'مندوب') return user.portId;
          // For 'مشرف' and 'مدير', we use their unique UID
          return user.uid;
        })
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toList();

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'sender': widget.user.name,
        'recipients': recipientIds,
        'message': _messageController.text,
        'fileUrl': _fileUrlController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [],
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال الإشعار بنجاح')));
      _messageController.clear();
      _fileUrlController.clear();
      setState(() {
        _selectedUsers = [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('فشل الإرسال: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إرسال إشعارات'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingUsers
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                            _filterUsers();
                          },
                          decoration: InputDecoration(
                              hintText: 'ابحث عن $_searchType...',
                              prefixIcon: const Icon(Icons.search)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // MODIFIED: Added 'مشرف' button
                      ToggleButtons(
                        borderRadius: BorderRadius.circular(8),
                        isSelected: [
                          _searchType == 'مندوب',
                          _searchType == 'مشرف',
                          _searchType == 'مدير'
                        ],
                        onPressed: (index) {
                          setState(() {
                            if (index == 0) _searchType = 'مندوب';
                            if (index == 1) _searchType = 'مشرف';
                            if (index == 2) _searchType = 'مدير';
                            _selectedUsers.clear();
                            _filterUsers();
                          });
                        },
                        children: const [
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('مندوب')),
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('مشرف')),
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('مدير'))
                        ],
                      )
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        return CheckboxListTile(
                          title: Text(user.name),
                          subtitle: Text(user.role == 'مندوب'
                              ? 'منفذ: ${user.portId ?? "N/A"}'
                              : '${user.role}: ${user.sectorId ?? "N/A"}'),
                          value: _selectedUsers.contains(user),
                          onChanged: (isSelected) {
                            setState(() {
                              if (isSelected!) {
                                _selectedUsers.add(user);
                              } else {
                                _selectedUsers.remove(user);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(labelText: 'نص الإشعار'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _fileUrlController,
                    decoration:
                        const InputDecoration(labelText: 'رابط مرفق (اختياري)'),
                  ),
                  const SizedBox(height: 16),
                  if (_isSending)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      onPressed: _sendNotification,
                      label: Text("إرسال إلى ${_selectedUsers.length} مستخدم"),
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50)),
                    ),
                ],
              ),
            ),
    );
  }
}

// NEW: Delegate Selection Dialog for Quizzes
class _DelegateSelectionDialog extends StatefulWidget {
  const _DelegateSelectionDialog();

  @override
  __DelegateSelectionDialogState createState() =>
      __DelegateSelectionDialogState();
}

class __DelegateSelectionDialogState extends State<_DelegateSelectionDialog> {
  List<UserModel> _allDelegates = [];
  List<UserModel> _filteredDelegates = [];
  List<UserModel> _selectedDelegates = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchDelegates();
  }

  Future<void> _fetchDelegates() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'مندوب')
          .get();
      final users =
          snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
      if (mounted) {
        setState(() {
          _allDelegates = users;
          _filteredDelegates = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterDelegates() {
    final query = _searchQuery.toLowerCase();
    setState(() {
      _filteredDelegates = _allDelegates.where((user) {
        if (query.isEmpty) return true;
        return user.name.toLowerCase().contains(query) ||
            (user.portId?.contains(query) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("اختيار المناديب"),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      _filterDelegates();
                    },
                    decoration: const InputDecoration(
                      labelText: 'بحث بالاسم أو الكود',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredDelegates.length,
                      itemBuilder: (context, index) {
                        final user = _filteredDelegates[index];
                        return CheckboxListTile(
                          title: Text(user.name),
                          subtitle: Text('منفذ: ${user.portId}'),
                          value: _selectedDelegates.contains(user),
                          onChanged: (isSelected) {
                            setState(() {
                              if (isSelected!) {
                                _selectedDelegates.add(user);
                              } else {
                                _selectedDelegates.remove(user);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء')),
        ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_selectedDelegates),
            child: const Text('تأكيد')),
      ],
    );
  }
}
