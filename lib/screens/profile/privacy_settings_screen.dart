import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../../services/profile_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _isLoading = true;
  bool _showStatus = true;
  bool _showPrivateInfo = true;

  // Partner Sharing
  bool _shareMood = true;
  bool _shareDiary = true;
  bool _shareQuiz = true;
  bool _isCouple = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final user = await AuthService().getUser(uid);
      if (user != null && mounted) {
        setState(() {
          _showStatus = user.showStatus;
          _showPrivateInfo = user.showPrivateInfo;
          _shareMood = user.shareMood;
          _shareDiary = user.shareDiary;
          _shareQuiz = user.shareQuiz;
          _isCouple = user.role == 'couple';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updatePrivacy(String field, bool value) async {
    // Optimistic update
    setState(() {
      if (field == 'showStatus') _showStatus = value;
      if (field == 'showPrivateInfo') _showPrivateInfo = value;
      if (field == 'shareMood') _shareMood = value;
      if (field == 'shareDiary') _shareDiary = value;
      if (field == 'shareQuiz') _shareQuiz = value;
    });

    try {
      if (field == 'showStatus') {
        await ProfileService().updateProfile(showStatus: value);
      } else if (field == 'showPrivateInfo') {
        await ProfileService().updateProfile(showPrivateInfo: value);
      } else if (field == 'shareMood') {
        await ProfileService().updateProfile(shareMood: value);
      } else if (field == 'shareDiary') {
        await ProfileService().updateProfile(shareDiary: value);
      } else if (field == 'shareQuiz') {
        await ProfileService().updateProfile(shareQuiz: value);
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          if (field == 'showStatus') _showStatus = !value;
          if (field == 'showPrivateInfo') _showPrivateInfo = !value;
          if (field == 'shareMood') _shareMood = !value;
          if (field == 'shareDiary') _shareDiary = !value;
          if (field == 'shareQuiz') _shareQuiz = !value;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi cập nhật: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          "Quyền riêng tư & Dữ liệu",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. My Data Section
                  _buildSectionTitle("Dữ liệu của tôi"),
                  _buildSectionContainer(
                    children: [
                      _buildActionTile(
                        "Xem dữ liệu",
                        "Xem thông tin và nội dung bạn đã lưu.",
                        Icons.visibility_outlined,
                        () => _showDataDialog(
                          context,
                          "Dữ liệu của bạn",
                          "Tính năng đang phát triển. Bạn sẽ sớm có thể xem toàn bộ dữ liệu của mình tại đây.",
                        ),
                      ),
                      const Divider(height: 1),
                      _buildActionTile(
                        "Tải dữ liệu",
                        "Tải xuống bản sao dữ liệu tài khoản.",
                        Icons.download_outlined,
                        () => _showDataDialog(
                          context,
                          "Tải dữ liệu",
                          "Hệ thống đang chuẩn bị dữ liệu. Vui lòng thử lại sau.",
                        ),
                      ),
                      const Divider(height: 1),
                      _buildActionTile(
                        "Xóa tài khoản",
                        "Xóa vĩnh viễn tài khoản và dữ liệu.",
                        Icons.delete_forever_outlined,
                        () => _showDeleteAccountDialog(context),
                        isDestructive: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 2. Partner Sharing Section
                  _buildSectionTitle("Chia sẻ với Partner"),
                  if (!_isCouple)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Ghép đôi để sử dụng tính năng này",
                            style: GoogleFonts.inter(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                  Opacity(
                    opacity: _isCouple ? 1.0 : 0.5,
                    child: IgnorePointer(
                      ignoring: !_isCouple,
                      child: _buildSectionContainer(
                        children: [
                          _buildSwitchTile(
                            "Chia sẻ Mood",
                            "Cho phép Partner xem cảm xúc của bạn.",
                            _shareMood,
                            (v) => _updatePrivacy('shareMood', v),
                          ),
                          const Divider(height: 1),
                          _buildSwitchTile(
                            "Chia sẻ Nhật ký",
                            "Cho phép Partner xem nhật ký được chia sẻ.",
                            _shareDiary,
                            (v) => _updatePrivacy('shareDiary', v),
                          ),
                          const Divider(height: 1),
                          _buildSwitchTile(
                            "Chia sẻ Quiz",
                            "Cho phép Partner xem kết quả Quiz.",
                            _shareQuiz,
                            (v) => _updatePrivacy('shareQuiz', v),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const SizedBox(height: 40),
                ],
              ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSectionContainer({required List<Widget> children}) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String? subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center, // Align center for simple switches
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFFF4081),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String? subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive ? Colors.red[50] : Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDestructive ? Colors.red : Colors.blue[700],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? Colors.red : Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  void _showDataDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Đóng"),
              ),
            ],
          ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Xóa tài khoản?"),
            content: const Text(
              "Hành động này không thể hoàn tác. Mọi dữ liệu của bạn sẽ bị xóa vĩnh viễn.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Hủy"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Implement delete logic later
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Yêu cầu xóa tài khoản đã được gửi."),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Xóa vĩnh viễn"),
              ),
            ],
          ),
    );
  }
}
