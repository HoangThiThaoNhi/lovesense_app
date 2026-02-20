import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
// Import Core
// import '../main.dart'; // Circular dependency if not careful, but needed for LandingPage
// Actually, let's just use the widget directly if possible, or correct import path

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigation is handled by main.dart StreamBuilder
  }

  // Logic removed to prevent conflict with Main.dart StreamBuilder

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF9A9E), // Soft Pink
              Color(0xFFFECFEF), // Lighter Pink
              Color(0xFFE0C3FC), // Soft Purple
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Container with Heartbeat and Circular Shimmer
              Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Outer shadow glow
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pink.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Container(
                            padding: const EdgeInsets.all(40),
                            color: Colors.white,
                            child: const Icon(
                              Icons.favorite_rounded,
                              size: 80,
                              color: Color(0xFFFF4081), // Vivid Pink/Red
                            ),
                          )
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(
                            duration: 2500.ms,
                            color: Colors.pinkAccent.withOpacity(0.3),
                            delay: 1000.ms,
                          ),
                    ),
                  )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1),
                    duration: 1000.ms,
                    curve: Curves.easeInOut,
                  ), // Heartbeat effect

              const SizedBox(height: 16), // Reduced height to move text up
              // App Name - Title Font (Montserrat)
              Text(
                    'Lovesense',
                    style: GoogleFonts.inter(
                      fontSize: 50, // Slightly smaller for Montserrat
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2.0, // Added letter spacing for title look
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.1),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 800.ms)
                  .moveY(
                    begin: 20,
                    end: 0,
                    delay: 300.ms,
                    curve: Curves.easeOut,
                  ),

              const SizedBox(height: 12),

              // Slogan - Soft Rounded Font (Vietnamese Friendly)
              Text(
                    'Chạm vào cảm xúc, nuôi dưỡng yêu thương',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.95),
                      letterSpacing: 0.5,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 800.ms)
                  .moveY(
                    begin: 10,
                    end: 0,
                    delay: 800.ms,
                    curve: Curves.easeOut,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
