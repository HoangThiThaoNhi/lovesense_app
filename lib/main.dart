import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Ensure session persists across reloads (Critical for Web)
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  } catch (e) {
    debugPrint(
      "Firebase Initialization Failed: $e",
    );
  }
  
  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  runApp(MyApp(onboardingCompleted: onboardingCompleted));
}

class MyApp extends StatelessWidget {
  final bool onboardingCompleted;
  const MyApp({super.key, required this.onboardingCompleted});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tình Yêu Quotes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: StreamBuilder<User?>(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          if (snapshot.hasData) {
            // Instant check! No FutureBuilder delay.
            if (onboardingCompleted) {
              return const MainScreen();
            }
            return const OnboardingScreen();
          }
          // Người dùng chưa đăng nhập
          return const LoginScreen();
        },
      ),
    );
  }
}


