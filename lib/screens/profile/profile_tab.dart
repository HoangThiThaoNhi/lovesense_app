import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  
  // Toggles
  bool _dailyReminder = true;
  bool _aiSuggestions = true;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 32),
              
              // Mode Management
              Text(
                'Chế độ sử dụng',
                style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildModeCard('Cá nhân', Icons.person, Colors.blue, isActive: true),
                    const SizedBox(width: 12),
                    _buildModeCard('Cặp đôi', Icons.favorite, Colors.pink, isActive: false),
                    const SizedBox(width: 12),
                    _buildModeCard('Sáng tạo', Icons.brush, Colors.orange, isActive: false),
                  ],
                ),
              ).animate().fadeIn().moveX(begin: 20, end: 0),
              
              const SizedBox(height: 32),
              
              // Settings Groups
              _buildSectionTitle('Cài đặt cá nhân'),
              _buildSettingsCard([
                _buildSwitchTile('Nhắc nhở check-in mỗi ngày', _dailyReminder, (val) => setState(() => _dailyReminder = val)),
                _buildSwitchTile('Gợi ý từ AI Coach', _aiSuggestions, (val) => setState(() => _aiSuggestions = val)),
              ]),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Tài khoản & Bảo mật'),
              _buildSettingsCard([
                _buildActionTile('Đổi mật khẩu', Icons.lock_outline),
                _buildActionTile('Quyền riêng tư dữ liệu', Icons.privacy_tip_outlined),
                _buildActionTile('Đăng xuất', Icons.logout, isDestructive: true),
              ]),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Hỗ trợ'),
              _buildSettingsCard([
                _buildActionTile('Cộng đồng & Diễn đàn', Icons.forum_outlined),
                _buildActionTile('Gửi phản hồi', Icons.feedback_outlined),
                _buildActionTile('Điều khoản & Chính sách', Icons.description_outlined),
              ]),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final String name = _currentUser?.displayName ?? 'Người dùng mới';
    final String email = _currentUser?.email ?? 'example@email.com';
    // Mask email
    final maskedEmail = email.replaceRange(2, email.indexOf('@'), '****');

    return Row(
      children: [
        Stack(
          children: [
             Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFF4081), width: 3),
              ),
              child: const CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=32'),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                child: const Icon(Icons.edit, size: 14, color: Colors.white),
              ),
            )
          ],
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              maskedEmail,
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
             const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                'Đang ở chế độ Cá nhân',
                style: GoogleFonts.inter(fontSize: 10, color: Colors.blue[800], fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn().moveY(begin: -20, end: 0);
  }

  Widget _buildModeCard(String title, IconData icon, Color color, {required bool isActive}) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? color : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? Colors.transparent : Colors.grey[300]!),
        boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))] : [],
      ),
      child: Column(
        children: [
          Icon(icon, color: isActive ? Colors.white : color, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              color: isActive ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (!isActive)
            Text(
              'Chuyển đổi',
              style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
            ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
         boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 14)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFFF4081),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionTile(String title, IconData icon, {bool isDestructive = false}) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isDestructive ? Colors.red : Colors.grey[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDestructive ? Colors.red : Colors.black87,
                  fontWeight: isDestructive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
