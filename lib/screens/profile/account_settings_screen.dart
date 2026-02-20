import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final bool _isLoading = false;

  void _showChangePasswordDialog() {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Đổi mật khẩu"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: "Mật khẩu mới",
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmController,
                  decoration: const InputDecoration(
                    labelText: "Nhập lại mật khẩu",
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Hủy"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (passwordController.text != confirmController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Mật khẩu không khớp")),
                    );
                    return;
                  }
                  if (passwordController.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Mật khẩu phải có ít nhất 6 ký tự"),
                      ),
                    );
                    return;
                  }

                  try {
                    await _auth.currentUser?.updatePassword(
                      passwordController.text,
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Đổi mật khẩu thành công!"),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
                    }
                  }
                },
                child: const Text("Lưu"),
              ),
            ],
          ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Xóa tài khoản?"),
            content: const Text(
              "Hành động này không thể hoàn tác. Dữ liệu của bạn sẽ bị xóa vĩnh viễn sau 30 ngày.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Hủy"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  // Logic to soft-delete or flag account would go here
                  // For now, we will sign out as a placeholder for "Delete" flow start
                  await AuthService().signOut();
                  if (mounted) {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }
                },
                child: const Text("Xóa vĩnh viễn"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Cài đặt tài khoản",
          style: GoogleFonts.montserrat(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader("Bảo mật"),
          _buildActionTile(
            "Đổi mật khẩu",
            Icons.lock_outline,
            onTap: _showChangePasswordDialog,
          ),
          _buildActionTile(
            "Xác thực 2 yếu tố",
            Icons.verified_user_outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Tính năng đang phát triển")),
              );
            },
          ),

          const SizedBox(height: 32),
          _buildSectionHeader("Pháp lý & Chính sách"),
          _buildActionTile("Điều khoản sử dụng", Icons.description_outlined),
          _buildActionTile(
            "Chính sách quyền riêng tư",
            Icons.privacy_tip_outlined,
          ),

          const SizedBox(height: 32),
          _buildSectionHeader("Vùng nguy hiểm", color: Colors.red),
          _buildActionTile(
            "Xóa tài khoản",
            Icons.delete_forever,
            color: Colors.red,
            onTap: _showDeleteAccountDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color ?? Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    IconData icon, {
    VoidCallback? onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.black87, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: color ?? Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}
