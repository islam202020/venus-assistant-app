import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Note: You might need to adjust these import paths if your file structure is different
// For example, if you moved the project to 'venus' folder.
import 'package:venus_assistant_app/admin/analytics_dashboard_screen.dart';
import 'package:venus_assistant_app/admin/data_management_screen.dart';
import 'package:venus_assistant_app/admin/user_management_screen.dart';
import 'package:venus_assistant_app/admin/admin_content_screens.dart';
import 'package:venus_assistant_app/content_screens.dart';
import 'package:venus_assistant_app/leaderboard_screen.dart';
import 'package:venus_assistant_app/services/fcm_service.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_animations/simple_animations.dart';
import 'quiz_screens.dart';
import 'reports_screens.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:cached_network_image/cached_network_image.dart';

bool? showIntro;

// --- Top Level Helper Functions ---
Future<void> launchExternalUrl(BuildContext context, String urlString) async {
  final Uri url = Uri.parse(urlString);
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $urlString')),
      );
    }
  }
}

// --- Main Entry Point ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  showIntro = prefs.getBool('showIntro') ?? true;

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  if (!kIsWeb) {
    await FcmService().initialize();
  }
  runApp(const VenusApp());
}

// --- Root Application Widget ---
class VenusApp extends StatelessWidget {
  const VenusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Venus Delegate Assistant',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', ''), // Arabic
      ],
      locale: const Locale('ar', ''), // Force app to be in Arabic
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'Cairo',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: const Color(0xFFF4F4F4),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: showIntro! ? const IntroScreen() : const AuthWrapper(),
    );
  }
}

// --- INTRO SCREEN ---
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with AnimationMixin {
  late Animation<double> contentOpacity;
  late Animation<double> contentSlide;
  late Animation<double> manOpacity;
  late Animation<double> manSlide;

  @override
  void initState() {
    super.initState();
    controller.duration = const Duration(milliseconds: 1800);

    contentOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: controller,
          curve: const Interval(0.2, 0.8, curve: Curves.easeOut)),
    );
    contentSlide = Tween(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
          parent: controller,
          curve: const Interval(0.2, 1.0, curve: Curves.easeOut)),
    );

    manOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: controller,
          curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );
    manSlide = Tween(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(
          parent: controller,
          curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
    );

    controller.play();
  }

  Future<void> _onStartPressed(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showIntro', false);
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // --- Left Side: Person Image ---
          Expanded(
            flex: 4,
            child: Opacity(
              opacity: manOpacity.value,
              child: Transform.translate(
                offset: Offset(manSlide.value, 0),
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/person.png'),
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // --- Right Side: Content (Completely rebuilt for better layout) ---
          Expanded(
            flex: 5,
            child: Opacity(
              opacity: contentOpacity.value,
              child: Transform.translate(
                offset: Offset(0, contentSlide.value),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 40.0, 24.0, 40.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment
                        .stretch, // Stretch items horizontally
                    children: [
                      // Top Spacer to push logo down
                      const Spacer(flex: 2),

                      // Logo, moved up and enlarged
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo.jpeg',
                            width: 200, // Enlarged logo
                            height: 100,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Main Title Texts
                      const Text(
                        'VENUS',
                        style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF39C12),
                            height: 1.1),
                      ),
                      const Text(
                        'SALES TRAINING',
                        style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w300,
                            color: Color(0xFF0D253F),
                            height: 1.1),
                      ),

                      const SizedBox(height: 16),

                      // Subtitle
                      const Text(
                        'Sales Training  VENUS Company',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                        ),
                      ),

                      // Middle Spacer to push button down
                      const Spacer(flex: 3),

                      // Button, wrapped in Align to control its width
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton(
                          onPressed: () => _onStartPressed(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF39C12),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 60,
                                vertical: 20), // Adjusted padding
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                            shadowColor: Colors.black.withOpacity(0.5),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          child: const Text('START'),
                        ),
                      ),

                      // Bottom Spacer
                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Data Models, Auth, and other screens remain the same ---
// ... (The rest of the file is unchanged) ...
// --- Data Models (Refactored) ---
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? portId;
  final String? sectorId;
  final String status;
  final String? code;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.portId,
    this.sectorId,
    required this.status,
    this.code,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? 'No Name',
      email: data['email'] ?? 'No Email',
      role: data['role'] ?? 'مندوب',
      status: data['status'] ?? 'approved',
      portId: data['portId'], // Can be null
      sectorId: data['sectorId'], // Can be null
      code: data['code'], // Can be null
    );
  }
}

// --- Auth Handling ---
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen(isInitial: true);
        }
        if (snapshot.hasData) {
          return UserDataLoader(user: snapshot.data!);
        }
        return const UnifiedLoginScreen();
      },
    );
  }
}

// ===== MODIFICATION START =====
// UserDataLoader is now more robust with a try-catch block
class UserDataLoader extends StatelessWidget {
  final User user;
  const UserDataLoader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const AuthMessageScreen(
            message:
                "لم يتم العثور على بيانات المستخدم في قاعدة البيانات. برجاء التواصل مع الأدمن.",
          );
        }

        // --- ADDED TRY-CATCH BLOCK TO PREVENT CRASHES ---
        try {
          final userModel = UserModel.fromFirestore(snapshot.data!);

          if (userModel.status == 'pending') {
            return const AuthMessageScreen(
              message: "حسابك قيد المراجعة حالياً من قبل الأدمن.",
            );
          }

          if (!kIsWeb) {
            FcmService().saveTokenToDatabase(userModel.uid);
          }

          if (userModel.role == 'Admin') {
            return AdminMainScreen(user: userModel);
          } else {
            return MainScreen(user: userModel);
          }
        } catch (e) {
          // If any error occurs while reading data (e.g., missing field), show an error screen instead of crashing
          return AuthMessageScreen(
            message:
                "حدث خطأ أثناء تحميل بياناتك. قد تكون البيانات غير مكتملة أو غير صالحة.\n\nبرجاء التواصل مع الأدمن لحل المشكلة.\n\nError details: ${e.toString()}",
          );
        }
        // ===== MODIFICATION END =====
      },
    );
  }
}

// NEW: A dedicated screen to show auth-related messages
class AuthMessageScreen extends StatelessWidget {
  final String message;
  const AuthMessageScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.jpeg', height: 100),
              const SizedBox(height: 30),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('العودة لتسجيل الدخول'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Splash Screen
class SplashScreen extends StatelessWidget {
  final bool isInitial;
  const SplashScreen({this.isInitial = false, super.key});

  @override
  Widget build(BuildContext context) {
    if (!isInitial) {
      Future.delayed(const Duration(seconds: 2), () {
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
          );
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: Image.asset('assets/logo.jpeg')),
    );
  }
}

// --- Unified Login Screen (MODIFIED) ---
class UnifiedLoginScreen extends StatefulWidget {
  const UnifiedLoginScreen({super.key});

  @override
  State<UnifiedLoginScreen> createState() => _UnifiedLoginScreenState();
}

class _UnifiedLoginScreenState extends State<UnifiedLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // AuthWrapper will handle navigation after successful login
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = "فشل تسجيل الدخول";
        if (e.code == 'user-not-found' ||
            e.code == 'wrong-password' ||
            e.code == 'invalid-credential') {
          errorMessage = 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'صيغة البريد الإلكتروني غير صحيحة.';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset('assets/logo.jpeg', height: 120),
                const SizedBox(height: 40),
                Text('تسجيل الدخول',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                      labelText: 'كلمة المرور', prefixIcon: Icon(Icons.lock)),
                  obscureText: true,
                ),
                const SizedBox(height: 30),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15)),
                    child: const Text('دخول'),
                  ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const RegistrationScreen()));
                    },
                    child: const Text('ليس لديك حساب؟ سجل الآن'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- NEW REGISTRATION SCREEN ---
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  final _portIdController = TextEditingController();
  String _selectedRole = 'مندوب';
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        Map<String, dynamic> userData = {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _selectedRole,
          'code': _codeController.text.trim(),
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        };

        if (_selectedRole == 'مندوب') {
          userData['portId'] = _portIdController.text.trim();
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(userData);

        await FirebaseAuth.instance.signOut();

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text('تم التسجيل بنجاح'),
                content:
                    const Text('تم إرسال طلبك. سيتم تفعيله بعد موافقة الأدمن.'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('موافق'),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = "فشل التسجيل";
        if (e.code == 'weak-password') {
          errorMessage = 'كلمة المرور ضعيفة جدًا.';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'هذا البريد الإلكتروني مسجل بالفعل.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'صيغة البريد الإلكتروني غير صحيحة.';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل حساب جديد'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/logo.jpeg', height: 100),
                  const SizedBox(height: 30),
                  Text('إنشاء حساب جديد',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                        labelText: 'الاسم (ثلاثي)',
                        prefixIcon: Icon(Icons.person)),
                    validator: (value) =>
                        value!.isEmpty ? 'الرجاء إدخال الاسم' : null,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                        labelText: 'الوظيفة', prefixIcon: Icon(Icons.work)),
                    items: ['مندوب', 'مشرف', 'مدير'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedRole = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                        labelText: 'الكود', prefixIcon: Icon(Icons.pin)),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value!.isEmpty ? 'الرجاء إدخال الكود' : null,
                  ),
                  if (_selectedRole == 'مندوب') ...[
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _portIdController,
                      decoration: const InputDecoration(
                          labelText: 'رقم المنفذ',
                          prefixIcon: Icon(Icons.store)),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'الرجاء إدخال رقم المنفذ' : null,
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: Icon(Icons.email)),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value!.isEmpty || !value.contains('@')
                        ? 'الرجاء إدخال بريد إلكتروني صحيح'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                        labelText: 'كلمة المرور (6 أرقام على الأقل)',
                        prefixIcon: Icon(Icons.lock)),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.length < 6
                        ? 'كلمة المرور يجب أن تكون 6 أرقام على الأقل'
                        : null,
                  ),
                  const SizedBox(height: 30),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15)),
                      child: const Text('تسجيل'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// =================================================================
// The rest of the file remains the same
// =================================================================
// =================================================================
// START: DEFINITIONS FOR WIDGETS USED IN MAINSCREEN BOTTOMNAVBAR
// =================================================================

// PDF Viewer for local assets (used in BottomNavBar)
class PdfViewerScreen extends StatefulWidget {
  final String title;
  final String assetPath;
  const PdfViewerScreen(
      {required this.title, required this.assetPath, super.key});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  bool _isLoading = true;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      setState(() => _isLoading = false);
    } else {
      _prepareFile();
    }
  }

  Future<void> _prepareFile() async {
    try {
      final byteData = await rootBundle.load(widget.assetPath);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.title}.pdf');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      if (mounted) {
        setState(() {
          _localPath = file.path;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const Center(
        child: Text('عرض الملفات متاح فقط على تطبيق الموبايل'),
      );
    }
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_localPath == null) {
      return const Center(child: Text('فشل تحميل الملف'));
    }
    return PDFView(filePath: _localPath!);
  }
}

// Outlet List Page (now reads from Firestore)
class OutletListPage extends StatefulWidget {
  const OutletListPage({super.key});

  @override
  State<OutletListPage> createState() => _OutletListPageState();
}

class _OutletListPageState extends State<OutletListPage> {
  void _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('لا يمكن إجراء المكالمة: $e')),
        );
      }
    }
  }

  Widget _buildContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sectors')
          .orderBy('name')
          .snapshots(),
      builder: (context, sectorSnapshot) {
        if (!sectorSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (sectorSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text('لا توجد بيانات قطاعات.'));
        }

        return ListView.builder(
          itemCount: sectorSnapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final sector = sectorSnapshot.data!.docs[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              elevation: 2,
              child: ExpansionTile(
                title: Text('قطاع: ${sector['name']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Text('مدير القطاع: ${sector['managerName']}'),
                children: [_buildSupervisorsList(sector.id)],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSupervisorsList(String sectorId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('supervisors')
          .where('sectorId', isEqualTo: sectorId)
          .orderBy('name')
          .snapshots(),
      builder: (context, supervisorSnapshot) {
        if (!supervisorSnapshot.hasData) {
          return const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator()));
        }
        if (supervisorSnapshot.data!.docs.isEmpty) {
          return const ListTile(title: Text('لا يوجد مشرفون في هذا القطاع'));
        }

        return Column(
          children: supervisorSnapshot.data!.docs.map((supervisor) {
            return ExpansionTile(
              title: Text('المشرف: ${supervisor['name']}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.orange)),
              children: [_buildOutletsList(supervisor.id)],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildOutletsList(String supervisorId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('outlets')
          .where('supervisorId', isEqualTo: supervisorId)
          .snapshots(),
      builder: (context, outletSnapshot) {
        if (!outletSnapshot.hasData) return const SizedBox.shrink();
        if (outletSnapshot.data!.docs.isEmpty) {
          return const ListTile(title: Text('لا يوجد منافذ لهذا المشرف'));
        }

        final outlets = outletSnapshot.data!.docs;
        outlets.sort((a, b) {
          final numA = int.tryParse((a.data() as Map)['number'] ?? '0') ?? 0;
          final numB = int.tryParse((b.data() as Map)['number'] ?? '0') ?? 0;
          return numA.compareTo(numB);
        });

        return Column(
          children: outlets.map((outlet) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: ListTile(
                leading: CircleAvatar(child: Text(outlet['number'])),
                title: Text('تلفون: ${outlet['phone']}'),
                subtitle: Text('العنوان: ${outlet['address']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.phone, color: Colors.green),
                  onPressed: () => _makePhoneCall(outlet['phone']),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }
}

// =================================================================
// END: DEFINITIONS FOR MISSING WIDGETS
// =================================================================

// MainScreen for DELEGATE and MANAGER
class MainScreen extends StatefulWidget {
  final UserModel user;
  const MainScreen({required this.user, super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late Widget _currentBody;
  int _bottomNavIndex = -1;

  @override
  void initState() {
    super.initState();
    _currentBody = DelegateManagerDashboard(
        user: widget.user, onNavigate: _navigateToPage);
  }

  void _navigateToPage(Widget page, {int bottomNavIndex = -1}) {
    setState(() {
      _currentBody = page;
      _bottomNavIndex = bottomNavIndex;
    });
  }

  void _goHome() {
    _navigateToPage(
        DelegateManagerDashboard(
            user: widget.user, onNavigate: _navigateToPage),
        bottomNavIndex: -1);
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle = 'مرحباً ${widget.user.name}';
    if (widget.user.role == 'مدير') {
      appBarTitle = 'مرحباً أ/ ${widget.user.name}';
    }

    bool isHomePage = _currentBody is DelegateManagerDashboard;

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        leading: isHomePage
            ? Builder(
                builder: (context) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer()))
            : BackButton(onPressed: _goHome),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () =>
                  _navigateToPage(NotificationsBody(user: widget.user)))
        ],
      ),
      drawer: AppDrawer(
          user: widget.user, onNavigate: _navigateToPage, goHome: _goHome),
      body: _currentBody,
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined), label: 'المجلة'),
          BottomNavigationBarItem(
              icon: Icon(Icons.electrical_services), label: 'الوشوش'),
          BottomNavigationBarItem(
              icon: Icon(Icons.phone), label: 'أرقام المنافذ'),
        ],
        currentIndex: _bottomNavIndex == -1 ? 0 : _bottomNavIndex,
        selectedItemColor: _bottomNavIndex == -1 ? Colors.grey : Colors.orange,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
              _navigateToPage(
                  PdfViewerScreen(
                      title: 'المجلة', assetPath: 'assets/magazine.pdf'),
                  bottomNavIndex: 0);
              break;
            case 1:
              _navigateToPage(
                  PdfViewerScreen(
                      title: 'الوشوش', assetPath: 'assets/wushush.pdf'),
                  bottomNavIndex: 1);
              break;
            case 2:
              _navigateToPage(const OutletListPage(), bottomNavIndex: 2);
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }
}

// Delegate/Manager Dashboard
class DelegateManagerDashboard extends StatelessWidget {
  final UserModel user;
  final Function(Widget, {int bottomNavIndex}) onNavigate;

  const DelegateManagerDashboard(
      {required this.user, required this.onNavigate, super.key});

  @override
  Widget build(BuildContext context) {
    final sections = {
      'التعليمات': Icons.integration_instructions_outlined,
      'التدريب': Icons.model_training,
      'تنمية المهارات': Icons.psychology_outlined,
      'الدفاتر': Icons.menu_book_outlined,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.orange.shade100,
                    child: const Icon(Icons.person, color: Colors.orange),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('مرحباً بعودتك،',
                            style: TextStyle(color: Colors.grey.shade600)),
                        Text(user.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _LatestNotificationCard(
              user: user, onNavigate: (page) => onNavigate(page)),
          const SizedBox(height: 20),
          const Text(
            'الوصول السريع',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: sections.length,
            itemBuilder: (context, index) {
              final title = sections.keys.elementAt(index);
              final icon = sections.values.elementAt(index);
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    if (title == 'التدريب') {
                      onNavigate(TrainingSectionsScreen(
                          user: user, onNavigate: onNavigate));
                    } else {
                      onNavigate(
                          SectionContentBody(sectionName: title, user: user));
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 45, color: Colors.orange),
                      const SizedBox(height: 12),
                      Text(title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LatestNotificationCard extends StatelessWidget {
  final UserModel user;
  final Function(Widget) onNavigate;

  const _LatestNotificationCard({required this.user, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('notifications');

    if (user.role == 'مندوب' && user.portId != null) {
      query =
          query.where('recipients', arrayContainsAny: [user.portId, 'الكل']);
    } else {
      query = query.where('recipients', arrayContains: 'الكل');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.orderBy('timestamp', descending: true).limit(1).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(child: ListTile(title: Text('...جاري التحميل')));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink(); // No notifications, show nothing
        }

        final notificationDoc = snapshot.data!.docs.first;
        final data = notificationDoc.data() as Map<String, dynamic>;
        final List<dynamic> readBy = data['readBy'] ?? [];
        final isRead = readBy.contains(user.uid);

        return Card(
          elevation: 2,
          color: isRead ? Colors.white : Colors.orange.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isRead
                ? BorderSide.none
                : BorderSide(color: Colors.orange.shade200, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onNavigate(NotificationsBody(user: user)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.campaign_rounded,
                      color: Colors.orange.shade700, size: 30),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'آخر الإشعارات',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data['message'] ?? 'اضغط لعرض التفاصيل',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// App Drawer
class AppDrawer extends StatelessWidget {
  final UserModel user;
  final Function(Widget, {int bottomNavIndex}) onNavigate;
  final VoidCallback goHome;

  const AppDrawer(
      {required this.user,
      required this.onNavigate,
      required this.goHome,
      super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            accountEmail: Text(user.email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'V',
                  style: const TextStyle(fontSize: 24, color: Colors.orange)),
            ),
            decoration: const BoxDecoration(color: Colors.orange),
          ),
          ListTile(
              leading: const Icon(Icons.home),
              title: const Text('الصفحة الرئيسية'),
              onTap: () {
                Navigator.pop(context);
                goHome();
              }),
          ListTile(
              leading: const Icon(Icons.leaderboard_outlined),
              title: const Text('لوحة الصدارة'),
              onTap: () {
                Navigator.pop(context);
                onNavigate(const LeaderboardScreen());
              }),
          if (user.role == 'مندوب')
            ListTile(
                leading: const Icon(Icons.quiz),
                title: const Text('اختباراتي'),
                onTap: () {
                  Navigator.pop(context);
                  onNavigate(DelegateQuizListScreen(user: user));
                }),
          if (user.role == 'مدير')
            ListTile(
                leading: const Icon(Icons.assessment),
                title: const Text('تقارير المنافذ'),
                onTap: () {
                  Navigator.pop(context);
                  onNavigate(ReportsScreen(user: user));
                }),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text("منصات التواصل",
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.facebook,
                    color: Color(0xFF1877F2)),
                onPressed: () => launchExternalUrl(
                    context, 'https://www.facebook.com/venus.electric/'),
              ),
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.youtube,
                    color: Color(0xFFFF0000)),
                onPressed: () => launchExternalUrl(context,
                    'https://www.youtube.com/channel/UCYTPZZ3LkHAwk6cZyF7GWxA'),
              ),
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.instagram,
                    color: Color(0xFFC13584)),
                onPressed: () => launchExternalUrl(
                    context, 'https://www.instagram.com/venus.electric.egy/'),
              ),
            ],
          ),
          const Divider(),
          ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('تسجيل الخروج'),
              onTap: () => _logout(context)),
        ],
      ),
    );
  }
}

// --- ADMIN SECTION (RE-DESIGNED) ---
class AdminMainScreen extends StatelessWidget {
  final UserModel user;
  const AdminMainScreen({required this.user, super.key});

  void _logout() {
    FirebaseAuth.instance.signOut();
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> dashboardItems = [
      {
        'title': 'إدارة البيانات',
        'icon': Icons.data_usage_rounded,
        'page': const DataManagementScreen(),
      },
      {
        'title': 'إدارة المستخدمين',
        'icon': Icons.manage_accounts_rounded,
        'page': const AdminUserManagementScreen(),
      },
      {
        'title': 'التقارير والإحصائيات',
        'icon': Icons.bar_chart_rounded,
        'page': const AdminAnalyticsDashboard(),
      },
      {
        'title': 'إدارة الاختبارات',
        'icon': Icons.quiz_rounded,
        'page': const AdminQuizScreen(),
      },
      {
        'title': 'إدارة المحتوى',
        'icon': Icons.edit_document,
        'page': const AdminContentManagementHub(),
      },
      {
        'title': 'إرسال الإشعارات',
        'icon': Icons.send_rounded,
        'page': AdminNotificationsScreen(user: user),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الأدمن'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: _logout,
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: dashboardItems.length,
        itemBuilder: (context, index) {
          final item = dashboardItems[index];
          return _AdminDashboardCard(
            title: item['title'],
            icon: item['icon'],
            onTap: () => _navigateTo(context, item['page']),
          );
        },
      ),
    );
  }
}

class _AdminDashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _AdminDashboardCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.indigo),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Notifications Body (User-facing) ---
class NotificationsBody extends StatefulWidget {
  final UserModel user;
  const NotificationsBody({required this.user, super.key});

  @override
  State<NotificationsBody> createState() => _NotificationsBodyState();
}

class _NotificationsBodyState extends State<NotificationsBody> {
  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('timestamp', descending: true);

    if (widget.user.role == 'مندوب' && widget.user.portId != null) {
      query = query
          .where('recipients', arrayContainsAny: [widget.user.portId, 'الكل']);
    } else {
      query = query.where('recipients', arrayContains: 'الكل');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.limit(50).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('لا توجد إشعارات جديدة'));
        }

        final notifications = snapshot.data!.docs;

        return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;
              final List<dynamic> readBy = data['readBy'] ?? [];
              final bool isRead = readBy.contains(widget.user.uid);
              final timestamp = data['timestamp'] as Timestamp?;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                color: isRead ? Colors.white : Colors.orange.shade50,
                child: ListTile(
                  leading: Icon(
                    isRead ? Icons.notifications : Icons.notifications_active,
                    color: isRead ? Colors.grey : Colors.orange,
                  ),
                  title: Text(data['message'] ?? ''),
                  subtitle: Text(
                    timestamp != null
                        ? DateFormat('yyyy-MM-dd – hh:mm a')
                            .format(timestamp.toDate())
                        : '',
                  ),
                  onTap: () {
                    if (!isRead) {
                      doc.reference.update({
                        'readBy': FieldValue.arrayUnion([widget.user.uid])
                      });
                    }
                    if (data['fileUrl'] != null &&
                        (data['fileUrl'] as String).isNotEmpty) {
                      launchExternalUrl(context, data['fileUrl']);
                    }
                  },
                ),
              );
            });
      },
    );
  }
}

// --- Send Notification Body (For Manager) ---
class SendNotificationBody extends StatefulWidget {
  final UserModel user;
  const SendNotificationBody({required this.user, super.key});
  @override
  State<SendNotificationBody> createState() => _SendNotificationBodyState();
}

class _SendNotificationBodyState extends State<SendNotificationBody> {
  final _messageController = TextEditingController();
  final _fileUrlController = TextEditingController();
  bool _isLoading = false;
  List<String> _allDelegates = [];
  List<String> _selectedDelegates = [];
  bool _isDataLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDelegates();
  }

  Future<void> _fetchDelegates() async {
    if (widget.user.sectorId == null) {
      setState(() => _isDataLoading = false);
      return;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('outlets')
          .where('sectorId', isEqualTo: widget.user.sectorId)
          .get();

      final delegates =
          snapshot.docs.map((doc) => doc['number'] as String).toList();
      delegates.sort((a, b) => int.parse(a).compareTo(int.parse(b)));

      if (mounted) {
        setState(() {
          _allDelegates = delegates;
          _isDataLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDataLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل تحميل قائمة المنافذ: $e')));
      }
    }
  }

  Future<void> _sendNotification() async {
    if (_messageController.text.isEmpty && _fileUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('الرجاء كتابة رسالة أو إرفاق رابط ملف')));
      return;
    }
    if (_selectedDelegates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار منفذ واحد على الأقل')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'sender': widget.user.name,
        'recipients': _selectedDelegates,
        'sector': widget.user.sectorId,
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
        _selectedDelegates = [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('فشل الإرسال: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDataLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: _isLoading
          ? const Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text("جاري الإرسال...")
              ],
            ))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("إرسال إلى:",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Wrap(
                  spacing: 8.0,
                  children: [
                    ChoiceChip(
                      label: const Text('تحديد الكل'),
                      selected:
                          _selectedDelegates.length == _allDelegates.length &&
                              _allDelegates.isNotEmpty,
                      onSelected: (selected) {
                        setState(() {
                          _selectedDelegates =
                              selected ? List.from(_allDelegates) : [];
                        });
                      },
                    ),
                    ..._allDelegates
                        .map((delegate) => FilterChip(
                              label: Text('منفذ $delegate'),
                              selected: _selectedDelegates.contains(delegate),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedDelegates.add(delegate);
                                  } else {
                                    _selectedDelegates.remove(delegate);
                                  }
                                });
                              },
                            ))
                        .toList(),
                  ],
                ),
                const Divider(height: 30),
                TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                        labelText: 'نص الإشعار (اختياري)'),
                    maxLines: 5),
                const SizedBox(height: 16),
                TextField(
                    controller: _fileUrlController,
                    decoration: const InputDecoration(
                        labelText: 'رابط الصورة أو PDF (اختياري)')),
                const SizedBox(height: 30),
                ElevatedButton(
                    onPressed: _sendNotification,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15)),
                    child: const Text(
                      'إرسال',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    )),
              ],
            ),
    );
  }
}
