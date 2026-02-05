import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  // Validation State
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool isValid = true;
    setState(() {
      _emailError = null;
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        _emailError = 'Vui lòng nhập Email';
        isValid = false;
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _emailError = 'Email không hợp lệ';
        isValid = false;
      }
    });
    return isValid;
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();

    if (!_validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã gửi email khôi phục. Vui lòng kiểm tra hộp thư.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Delay then pop
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String errorMessage = 'Gửi yêu cầu thất bại';
      if (e.code == 'user-not-found') {
        errorMessage = 'Email không tồn tại trong hệ thống';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Email không hợp lệ';
      } else {
        errorMessage = 'Lỗi: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage, style: GoogleFonts.inter()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã có lỗi xảy ra.', style: GoogleFonts.inter()),
          backgroundColor: Colors.redAccent,
        ),
      );
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF0F5), // Lavender Blush
              Color(0xFFE6E6FA), // Lavender
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),

                // Icon
                const Center(
                      child: Icon(
                        Icons.lock_reset_rounded,
                        size: 80,
                        color: Color(0xFFFF4081),
                      ),
                    )
                    .animate()
                    .scale(duration: 500.ms, curve: Curves.elasticOut)
                    .fadeIn(duration: 500.ms),

                const SizedBox(height: 24),

                Text(
                  'Quên mật khẩu?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ).animate().fadeIn(duration: 500.ms).moveY(begin: 20, end: 0),

                const SizedBox(height: 8),

                Text(
                  'Đừng lo, hãy nhập email để lấy lại mật khẩu',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                const SizedBox(height: 48),

                // Email Input
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  delay: 300,
                  maxLength: 100,
                  errorText: _emailError,
                ),

                const SizedBox(height: 32),

                // Send Button
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF4081),
                      ),
                    )
                    : Container(
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(27),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF4081), Color(0xFFFF80AB)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF4081).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                        ),
                        child: Text(
                          'Gửi yêu cầu',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    int delay = 0,
    int maxLength = 100,
    String? errorText,
  }) {
    // Column to hold Container(Input) + Error Text (Outside)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border:
                errorText != null
                    ? Border.all(color: Colors.redAccent, width: 1.5)
                    : null, // Highlight border if error
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: GoogleFonts.inter(),
            maxLength: maxLength,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: GoogleFonts.inter(color: Colors.grey),
              prefixIcon: Icon(icon, color: Colors.grey),
              border: InputBorder.none,
              counterText: '', // Hide counter
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),

        // Error Text Outside
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              errorText,
              style: GoogleFonts.inter(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),
      ],
    ).animate().fadeIn(delay: delay.ms).moveX(begin: -20, end: 0);
  }
}
