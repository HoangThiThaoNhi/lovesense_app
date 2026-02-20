import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/admin_web/admin_scaffold.dart';
import 'screens/admin_web/admin_views.dart';
import 'screens/admin_web/admin_video_view.dart';
import 'screens/admin_web/admin_quiz_view.dart';
import 'screens/admin_web/admin_users_view.dart';
import 'screens/admin_web/admin_paper_view.dart';
import 'screens/admin_web/admin_course_view.dart';
import 'screens/admin_web/admin_policy_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }

  runApp(const LovesenseAdminApp());
}

class LovesenseAdminApp extends StatelessWidget {
  const LovesenseAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lovesense Admin CMS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF4081)),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const AdminMainScreen(),
    );
  }
}

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _views = const [
    AdminDashboardView(),
    AdminUsersView(),
    AdminVideoView(),
    AdminBlogView(),
    AdminCourseView(),
    AdminQuizView(),
    AdminQuizView(),
    AdminPolicyView(),
  ];

  final List<String> _titles = const [
    'Dashboard',
    'Quản lý Người dùng',
    'Quản lý Video',
    'Quản lý Bài viết',
    'Quản lý Khóa học',
    'Quản lý Quiz',
    'Quản lý Chính sách',
  ];

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: _titles[_selectedIndex],
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        if (index == 99) {
          // Logout
          return;
        }
        setState(() => _selectedIndex = index);
      },
      body: _views[_selectedIndex],
    );
  }
}
