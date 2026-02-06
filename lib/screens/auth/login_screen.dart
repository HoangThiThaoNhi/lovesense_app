import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../main_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Removed FormKey as we are doing manual validation for custom UI
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  // Validation State
  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;

  // Password Visibility State
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool isValid = true;
    setState(() {
      // Reset errors
      _emailError = null;
      _passwordError = null;

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
        _passwordError = 'Vui lòng nhập Mật khẩu';
        isValid = false;
      } else {
        // Strong Password Logic
        // Regex: At least 1 Uppercase, 1 Number, 1 Special Char
        // Updated Regex to include ? and other special chars
        bool hasUpper = password.contains(RegExp(r'[A-Z]'));
        bool hasDigits = password.contains(RegExp(r'[0-9]'));
        bool hasSpecial = password.contains(
          RegExp(r'[!@#\$&*~^%().,+=_\-?/<>;:{}\[\]|]'),
        );

        if (!hasUpper || !hasDigits || !hasSpecial) {
          _passwordError = 'Mật khẩu phải có chữ hoa, số và ký tự đặc biệt';
          isValid = false;
        }
      }
    });
    return isValid;
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Ensure Firestore data exists (Self-healing for legacy/broken users)
      if (_authService.currentUser != null) {
        await _authService.ensureUserExists(_authService.currentUser!);
      }

      if (!mounted) return;

      // Navigate to Home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String errorMessage = 'Đăng nhập thất bại';
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        errorMessage = 'Email hoặc mật khẩu không chính xác';
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
          content: Text(
            'Đã có lỗi xảy ra. Thử lại sau.',
            style: GoogleFonts.inter(),
          ),
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
                // Animated Logo (Consistent with Splash)
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
                                padding: const EdgeInsets.all(24),
                                color: Colors.white,
                                child: const Icon(
                                  Icons.favorite_rounded,
                                  size: 60,
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

                const SizedBox(height: 32),

                Text(
                  'Chào mừng',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ).animate().fadeIn(duration: 500.ms).moveY(begin: 20, end: 0),

                const SizedBox(height: 8),

                Text(
                  'Cùng yêu thương theo cách của bạn',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                const SizedBox(height: 48),

                // Email Input (Auto Focus)
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  delay: 300,
                  autofocus: true,
                  maxLength: 100, // Limit input
                  errorText: _emailError, // Manual Error
                ),

                const SizedBox(height: 16),

                // Password Input
                _buildTextField(
                  controller: _passwordController,
                  label: 'Mật khẩu',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: !_showPassword,
                  delay: 400,
                  maxLength: 50, // Limit input
                  errorText: _passwordError, // Manual Error
                  onToggleObscure: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                ),

                const SizedBox(height: 12),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Quên mật khẩu?',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFFF4081),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 24),

                // Login Button
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
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                        ),
                        child: Text(
                          'Đăng nhập',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0),

                const SizedBox(height: 24),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Chưa có tài khoản? ',
                      style: GoogleFonts.inter(color: Colors.black54),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Đăng ký ngay',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFF4081),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 700.ms),

                // Bottom spacer
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
    bool autofocus = false,
    int delay = 0,
    int maxLength = 100,
    String? errorText,
    VoidCallback? onToggleObscure,
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
            obscureText: isPassword ? obscureText : false,
            autofocus: autofocus,
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
