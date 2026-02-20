import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:email_otp/email_otp.dart'; // Removed
import '../../services/auth_service.dart';
// For LandingPage
import '../onboarding/onboarding_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Removed FormKey
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  // final EmailOTP _emailOTP = EmailOTP(); // Removed instance

  // Validation State
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  bool _isLoading = false;

  // Password Visibility State
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool isValid = true;
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;

      // Name Validation
      if (_nameController.text.trim().isEmpty) {
        _nameError = 'Vui lòng nhập họ tên';
        isValid = false;
      }

      // Email Validation
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        _emailError = 'Vui lòng nhập Email';
        isValid = false;
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _emailError = 'Email không hợp lệ';
        isValid = false;
      }

      // Password Validation
      final password = _passwordController.text;
      if (password.isEmpty) {
        _passwordError = 'Vui lòng nhập mật khẩu';
        isValid = false;
      } else if (password.length < 6) {
        _passwordError = 'Mật khẩu phải từ 6 ký tự';
        isValid = false;
      } else {
        // Strong Password Regex for Register
        // At least 1 Uppercase, 1 Number, 1 Special Char
        bool hasUpper = password.contains(RegExp(r'[A-Z]'));
        bool hasDigits = password.contains(RegExp(r'[0-9]'));
        // Updated Regex to include ? and more special chars
        bool hasSpecial = password.contains(
          RegExp(r'[!@#\$&*~^%().,+=_\-?/<>;:{}\[\]|]'),
        );

        if (!hasUpper || !hasDigits || !hasSpecial) {
          _passwordError = 'Phải có chữ hoa, số và ký tự đặc biệt';
          isValid = false;
        }
      }

      // Confirm Password
      if (_confirmPasswordController.text != password) {
        _confirmPasswordError = 'Mật khẩu không khớp';
        isValid = false;
      }
    });

    return isValid;
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    if (!_validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Direct Firebase Registration (Standard Flow)
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        role: 'single', // Default role
      );

      if (!mounted) return;

      // Show Success & Verify Instructions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(
            'Đăng ký thành công! Vui lòng kiểm tra email để xác thực tài khoản.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to Login or Onboarding
      // Usually require detailed onboarding now
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errorMessage = 'Đăng ký thất bại';
      if (e.code == 'weak-password') {
        errorMessage = 'Mật khẩu quá yếu';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email này đã được sử dụng. Vui lòng đăng nhập.';
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
          content: Text('Lỗi: $e', style: GoogleFonts.inter()),
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
                const SizedBox(height: 24),

                // Animated Logo
                Center(
                  child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Container(
                                padding: const EdgeInsets.all(20),
                                color: Colors.white,
                                child: const Icon(
                                  Icons.favorite_rounded,
                                  size: 50,
                                  color: Color(0xFFFF4081),
                                ),
                              )
                              .animate(
                                onPlay: (controller) => controller.repeat(),
                              )
                              .shimmer(
                                duration: 2500.ms,
                                color: Colors.pinkAccent.withOpacity(0.3),
                                delay: 1000.ms,
                              ),
                        ),
                      )
                      .animate(
                        onPlay:
                            (controller) => controller.repeat(reverse: true),
                      )
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.05, 1.05),
                        duration: 1500.ms,
                        curve: Curves.easeInOut,
                      ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Tạo tài khoản',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ).animate().fadeIn(duration: 500.ms).moveY(begin: 20, end: 0),

                const SizedBox(height: 8),

                Text(
                  'Bắt đầu hành trình yêu thương ngay hôm nay',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                const SizedBox(height: 48),

                // Name Input
                _buildTextField(
                  controller: _nameController,
                  label: 'Họ và tên',
                  icon: Icons.person_outline,
                  delay: 300,
                  maxLength: 50,
                  errorText: _nameError,
                ),

                const SizedBox(height: 16),

                // Email Input
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  delay: 400,
                  maxLength: 100,
                  errorText: _emailError,
                ),

                const SizedBox(height: 16),

                // Password Input
                _buildTextField(
                  controller: _passwordController,
                  label: 'Mật khẩu',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: !_showPassword,
                  delay: 500,
                  maxLength: 50,
                  errorText: _passwordError,
                  onToggleObscure: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Confirm Password Input
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Xác nhận mật khẩu',
                  icon: Icons.lock_clock_outlined,
                  isPassword: true,
                  obscureText: !_showConfirmPassword,
                  delay: 600,
                  maxLength: 50,
                  errorText: _confirmPasswordError,
                  onToggleObscure: () {
                    setState(() {
                      _showConfirmPassword = !_showConfirmPassword;
                    });
                  },
                ),

                const SizedBox(height: 32),

                // Register Button
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
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                        ),
                        child: Text(
                          'Đăng ký',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 700.ms).moveY(begin: 20, end: 0),

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
    bool obscureText = false,
    int delay = 0,
    int maxLength = 100,
    String? errorText,
    VoidCallback? onToggleObscure,
  }) {
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
                    : null,
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
            obscureText: isPassword ? obscureText : false,
            style: GoogleFonts.inter(),
            maxLength: maxLength,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: GoogleFonts.inter(color: Colors.grey),
              prefixIcon: Icon(icon, color: Colors.grey),
              suffixIcon:
                  isPassword
                      ? IconButton(
                        icon: Icon(
                          obscureText
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: onToggleObscure,
                      )
                      : null,
              border: InputBorder.none,
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
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
