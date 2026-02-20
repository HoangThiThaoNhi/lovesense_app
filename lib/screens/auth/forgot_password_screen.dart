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
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    setState(() => _errorText = null);
    final email = _emailController.text.trim();

    if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _errorText = 'Email không hợp lệ');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      // Success UI
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Đã gửi liên kết'),
          content: Text(
            'Một email chứa liên kết đặt lại mật khẩu đã được gửi tới $email.\nVui lòng kiểm tra hộp thư (kể cả mục Spam).',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close Dialog
                Navigator.pop(context); // Back to Login
              },
              child: const Text('Đã hiểu, quay lại đăng nhập'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Gửi yêu cầu thất bại';
      if (e.code == 'user-not-found') msg = 'Email này chưa được đăng ký.';
      if (e.code == 'invalid-email') msg = 'Định dạng email không đúng.';
      setState(() => _errorText = msg);
    } catch (e) {
       setState(() => _errorText = 'Đã có lỗi xảy ra. Hãy thử lại.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF0F5), Color(0xFFE6E6FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                const Icon(
                  Icons.mark_email_unread_outlined, 
                  size: 80, 
                  color: Color(0xFFFF4081)
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                
                const SizedBox(height: 32),
                
                Text(
                  'Khôi phục mật khẩu',
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ).animate().fadeIn().moveY(begin: 20, end: 0),
                
                const SizedBox(height: 12),
                
                Text(
                  'Nhập email của bạn, chúng tôi sẽ gửi liên kết để bạn đặt lại mật khẩu mới.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 48),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email đăng ký',
                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      errorText: _errorText,
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms).moveX(begin: -20, end: 0),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendResetLink,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4081),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(0xFFFF4081).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                    ),
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Gửi liên kết',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0),

                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

