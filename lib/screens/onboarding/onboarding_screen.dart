import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui' as ui; // Import UI for ImageFilter
import '../main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // Lottie URLs (using reliable public URLs or placeholders)
  // If offline/error, it will gracefully fallback or show loader
  final List<Map<String, String>> _pages = [
    {
      'title': 'Bắt đầu từ chính bạn',
      'desc':
          'Theo dõi cảm xúc, xây dựng thói quen tích cực và phát triển bản thân mỗi ngày — theo cách của riêng bạn.',
      // Yoga/Meditation Lottie (New URL)
      'lottie':
          'https://lottie.host/80a8bf70-98fd-426d-a314-87db37877286/e1qWqL9q7j.json',
      'icon': 'self_improvement',
    },
    {
      'title': 'Phát triển cùng người quan trọng',
      'desc':
          'Khi sẵn sàng, bạn có thể tạo nhóm cặp đôi để cùng theo dõi cảm xúc, đặt mục tiêu chung và đồng hành lâu dài.',
      // Couple/Love Lottie
      'lottie': 'https://assets5.lottiefiles.com/packages/lf20_u25cckyh.json',
      'icon': 'favorite',
    },
    {
      'title': 'Chia sẻ giá trị – Tạo thu nhập',
      'desc':
          'Khi bạn có trải nghiệm và kiến thức, hãy chia sẻ qua nội dung hoặc khóa học và tạo thu nhập từ giá trị bạn mang lại.',
      // Creator/Work Lottie
      'lottie': 'https://assets2.lottiefiles.com/packages/lf20_w51pcehl.json',
      'icon': 'lightbulb',
    },
    {
      'title': 'Luôn có người đồng hành',
      'desc':
          'AI hỗ trợ giúp bạn nhận gợi ý phù hợp theo từng giai đoạn — cá nhân, cặp đôi hay nhà sáng tạo.',
      // AI/Robot Lottie (New URL)
      'lottie': 'https://assets5.lottiefiles.com/packages/lf20_wdXBRc.json',
      'icon': 'smart_toy',
    },
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  void _nextPage() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  // Animated Background Gradient Colors
  List<Color> get _currentGradient {
    switch (_currentIndex) {
      case 0:
        return [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)];
      case 1:
        return [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)];
      case 2:
        return [const Color(0xFFFFF9C4), const Color(0xFFFFF59D)];
      case 3:
        return [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)];
      default:
        return [const Color(0xFFFFF0F5), const Color(0xFFF3E5F5)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _currentGradient,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // --- Background Effects ---
              // Blob 1
              Positioned(
                top: -100,
                right: -50,
                child: _buildBlob(350, Colors.purple.withOpacity(0.2)),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.3, 1.3),
                duration: 6.seconds,
              ),

              // Blob 2
              Positioned(
                bottom: -100,
                left: -50,
                child: _buildBlob(300, Colors.blue.withOpacity(0.2)),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).move(
                begin: const Offset(0, 0),
                end: const Offset(50, -50),
                duration: 8.seconds,
              ),

              // Blob 3
              Positioned(
                top: MediaQuery.of(context).size.height * 0.3,
                left: -100,
                child: _buildBlob(200, Colors.pink.withOpacity(0.15)),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).moveX(
                begin: 0,
                end: 200,
                duration: 10.seconds,
              ),

              // Glassmorphism Blur
              Positioned.fill(
                child: BackdropFilter(
                  filter:
                      ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30), // High blur
                  child: Container(color: Colors.white.withOpacity(0.1)),
                ),
              ),

              // Content
              Column(
                children: [
                  // Top Bar: Back Button & Skip
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button (VISIBLE CHECK)
                        _currentIndex > 0
                            ? IconButton(
                              onPressed: _prevPage,
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.black87,
                                size: 28, // Larger
                              ),
                            ).animate().fadeIn()
                            : const SizedBox(width: 48),

                        // Skip Button
                        TextButton(
                          onPressed: _completeOnboarding,
                          child: Text(
                            'Bỏ qua',
                            style: GoogleFonts.inter(
                              color: Colors.black54,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        final item = _pages[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Lottie with Glass Card Effect
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.4),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                height: 320,
                                child: Lottie.network(
                                  item['lottie']!,
                                  fit: BoxFit.contain,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          _buildFallbackIcon(item['icon']!),
                                ),
                              )
                                  .animate()
                                  .scale(
                                    duration: 800.ms,
                                    curve: Curves.elasticOut,
                                  )
                                  .fadeIn(),
                              
                              // ... Titles and Text same as before
                              const SizedBox(height: 32),

                              // Title
                              Text(
                                item['title']!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 28, // Slightly larger
                                  fontWeight: FontWeight.w800, // Extra Bold
                                  color: Colors.black87,
                                  height: 1.2,
                                ),
                              ).animate().fadeIn(delay: 200.ms).moveY(
                                begin: 30,
                                end: 0,
                                curve: Curves.easeOutQuad,
                              ),

                              const SizedBox(height: 20),

                              // Description (BOLDER as requested)
                              Text(
                                item['desc']!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.quicksand(
                                  fontSize: 18, // Larger
                                  height: 1.4,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w700, // Bold
                                ),
                              ).animate().fadeIn(delay: 400.ms).moveY(
                                begin: 20,
                                end: 0,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Bottom controls same as before...
                  Container(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Indicators (Modern Pill Shape)
                        Row(
                          children: List.generate(
                            _pages.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.fastOutSlowIn,
                              margin: const EdgeInsets.only(right: 6),
                              height: 10,
                              width: _currentIndex == index ? 32 : 10,
                              decoration: BoxDecoration(
                                color:
                                    _currentIndex == index
                                        ? const Color(0xFFFF4081)
                                        : Colors.black12,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),

                        // Animated FAB with Shadow/Glow
                        GestureDetector(
                          onTap: _nextPage,
                          child: Container(
                            height: 64,
                            width: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF4081), Color(0xFFFF80AB)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF4081,
                                  ).withOpacity(0.5),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              _currentIndex == _pages.length - 1
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        )
                              .animate(target: _currentIndex.toDouble())
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.15, 1.15),
                                duration: 200.ms,
                              )
                              .then(delay: 200.ms)
                              .scale(
                                begin: const Offset(1.15, 1.15),
                                end: const Offset(1, 1),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        // Optional: Add blur for glassmorphism feel
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 20,
            spreadRadius: 20,
          )
        ],
      ),
    );
  }

  Widget _buildFallbackIcon(String iconKey) {
    IconData icon;
    switch (iconKey) {
      case 'self_improvement':
        icon = Icons.self_improvement;
        break;
      case 'favorite':
        icon = Icons.favorite;
        break;
      case 'lightbulb':
        icon = Icons.lightbulb;
        break;
      case 'smart_toy':
        icon = Icons.smart_toy;
        break;
      default:
        icon = Icons.circle;
    }
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.5),
      ),
      child: Icon(icon, size: 100, color: const Color(0xFFFF4081)),
    );
  }
}
