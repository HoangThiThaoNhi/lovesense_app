import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'services/ai_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Error loading .env file: $e");
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Ensure session persists across reloads (Critical for Web)
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

    // Enable Firestore Persistence (Web & Mobile)
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    // For Web specifically, sometimes enablePersistence() is needed explicitly if settings don't catch it
    // But settings style is modern. Let's start with this.
    // Actually, explicit enablePersistence is often safer for legacy/hybrid support.
    // For Web specifically, settings API covers most cases now.
    // If needed, synchronization can be added to Settings in newer FlutterFire versions,
    // but typically persistenceEnabled: true is enough for basic offline.
  } catch (e) {
    debugPrint("Firebase Initialization Failed: $e");
  }

  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  // Initialize AI Service
  try {
    await AIService().init();
  } catch (e) {
    debugPrint("Failed to initialize AI Service: $e");
  }

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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', 'US'), Locale('vi', 'VN')],
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
