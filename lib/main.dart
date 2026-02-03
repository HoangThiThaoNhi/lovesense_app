import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
// import 'firebase_options.dart'; // User needs to generate this if using CLI, or just standard setup

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // IMPORTANT: User must add google-services.json (Android) or GoogleService-Info.plist (iOS)
  // or use FlutterFire CLI to generate firebase_options.dart
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint(
      "Firebase Initialization Failed (Did you add config files?): $e",
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      home: const SplashScreen(),
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final List<Map<String, String>> _quotes = [
    {
      'text': 'Yêu không phải là nhìn nhau, mà là cùng nhau nhìn về một hướng.',
      'author': 'Antoine de Saint-Exupéry',
    },
    {
      'text':
          'Tình yêu là khi hạnh phúc của người kia quan trọng hơn hạnh phúc của chính mình.',
      'author': 'H. Jackson Brown Jr.',
    },
    {
      'text':
          'Yêu là chấp nhận những khiếm khuyết, và đồng thời thấy được vẻ đẹp.',
      'author': 'Unknown',
    },
    {
      'text': 'Trái tim luôn biết con đường về nhà khi có tình yêu dẫn lối.',
      'author': 'Unknown',
    },
    {'text': 'Yêu là cho đi mà không mong nhận lại.', 'author': 'Unknown'},
    {
      'text': 'Người ta yêu bằng trái tim, chứ không phải bằng lý trí.',
      'author': 'Samuel Butler',
    },
  ];

  int _index = 0;

  void _nextQuote() {
    setState(() {
      _index = (_index + 1) % _quotes.length;
    });
  }

  void _prevQuote() {
    setState(() {
      _index = (_index - 1 + _quotes.length) % _quotes.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final quote = _quotes[_index];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFC1E3), Color(0xFFFFE0B2)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, color: Colors.redAccent, size: 56),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '“${quote['text']}”',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontStyle: FontStyle.italic,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '- ${quote['author']}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _prevQuote,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Trước'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _nextQuote,
                        icon: const Icon(Icons.favorite),
                        label: const Text('Tiếp theo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                      ),
                    ],
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
