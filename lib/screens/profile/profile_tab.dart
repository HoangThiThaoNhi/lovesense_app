import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/user_model.dart';
import '../../models/request_model.dart'; // Import RequestModel
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import 'edit_profile_screen.dart';
import 'account_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'policy_viewer_screen.dart';
import 'widgets/mode_status_section.dart';
import 'widgets/relationship_section.dart';
import 'widgets/couple_space_section.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // Toggles
  bool _dailyReminder = true;
  bool _aiSuggestions = true;
  bool _isUploading = false;

  late Stream<UserModel?> _userStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _userStream = AuthService().getUserStream(uid);
    } else {
      _userStream = Stream.value(null);
    }
  }

  Future<void> _pickImage(bool isAvatar) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      // Check for valid file (path or bytes)
      final hasPath = !kIsWeb && result.files.single.path != null;
      final hasBytes = kIsWeb && result.files.single.bytes != null;

      if (!hasPath && !hasBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Không thể chọn ảnh này")),
          );
        }
        return;
      }

      setState(() => _isUploading = true);

      File? file;
      Uint8List? bytes;

      if (kIsWeb) {
        bytes = result.files.single.bytes;
      } else {
        if (result.files.single.path != null) {
          file = File(result.files.single.path!);
        }
      }

      final fileName = result.files.single.name;

      try {
        if (isAvatar) {
          await ProfileService().uploadAvatar(
            file: file,
            bytes: bytes,
            fileName: fileName,
          );
        } else {
          await ProfileService().uploadCover(
            file: file,
            bytes: bytes,
            fileName: fileName,
          );
        }
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Cập nhật thành công!")));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  void _showCoverOptions(BuildContext context, String? currentCoverUrl) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (currentCoverUrl != null)
                ListTile(
                  leading: const Icon(Icons.visibility),
                  title: const Text('Xem ảnh bìa'),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder:
                          (_) => Dialog(
                            child: InteractiveViewer(
                              child: Image.network(currentCoverUrl),
                            ),
                          ),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Thay đổi ảnh bìa'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(false);
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<UserModel?>(
      stream: _userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFFAFAFA),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Error loading profile"));
        }

        final userModel = snapshot.data;
        if (userModel == null) {
          return const Center(child: Text("User not found"));
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFAFAFA),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRichHeader(userModel),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bio moved up
                      if (userModel.bio != null &&
                          userModel.bio!.isNotEmpty) ...[
                        Text(
                          userModel.bio!,
                          style: GoogleFonts.inter(
                            color: Colors.grey[600],
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Account Modes & Requests
                      StreamBuilder<List<RequestModel>>(
                        stream: ProfileService().getPendingRequests(),
                        builder: (context, requestSnapshot) {
                          final requests = requestSnapshot.data ?? [];
                          return ModeStatusSection(
                            user: userModel,
                            pendingRequests: requests,
                          );
                        },
                      ),

                      // Relationship Section (Couple Mode)
                      if (userModel.role == 'couple')
                        RelationshipSection(currentUser: userModel),

                      const SizedBox(height: 24),

                      // Couple Space (Couple Mode)
                      if (userModel.role == 'couple')
                        const CoupleSpaceSection(),

                      if (userModel.role == 'couple')
                        const SizedBox(height: 24),

                      // Settings Sections
                      _buildSectionTitle('Cài đặt cá nhân'),
                      _buildSettingsCard([
                        _buildSwitchTile(
                          'Nhắc nhở check-in mỗi ngày',
                          _dailyReminder,
                          (v) => setState(() => _dailyReminder = v),
                        ),
                        _buildSwitchTile(
                          'Gợi ý từ AI Coach',
                          _aiSuggestions,
                          (v) => setState(() => _aiSuggestions = v),
                        ),
                      ]),
                      const SizedBox(height: 24),

                      _buildSectionTitle('Tài khoản'),
                      _buildSettingsCard([
                        _buildActionTile(
                          'Chỉnh sửa hồ sơ',
                          Icons.person_outline,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => EditProfileScreen(user: userModel),
                              ),
                            );
                          },
                        ),
                        _buildActionTile(
                          'Bảo mật & Đăng nhập',
                          Icons.security,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AccountSettingsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildActionTile(
                          'Quyền riêng tư',
                          Icons.privacy_tip_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PrivacySettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ]),
                      const SizedBox(height: 24),

                      _buildSectionTitle('Chính sách & Điều khoản'),
                      _buildSettingsCard([
                        _buildActionTile(
                          'Điều khoản sử dụng',
                          Icons.description_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => const PolicyViewerScreen(
                                      title: "Điều khoản sử dụng",
                                      policyId: "terms_of_use",
                                    ),
                              ),
                            );
                          },
                        ),
                        _buildActionTile(
                          'Chính sách quyền riêng tư',
                          Icons.privacy_tip_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => const PolicyViewerScreen(
                                      title: "Chính sách quyền riêng tư",
                                      policyId: "privacy_policy",
                                    ),
                              ),
                            );
                          },
                        ),
                        _buildActionTile(
                          'Chính sách AI',
                          Icons.smart_toy_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => const PolicyViewerScreen(
                                      title: "Chính sách AI",
                                      policyId: "ai_policy",
                                    ),
                              ),
                            );
                          },
                        ),
                      ]),
                      const SizedBox(height: 24),

                      _buildActionTile(
                        'Đăng xuất',
                        Icons.logout,
                        isDestructive: true,
                        onTap: () async {
                          final navigator = Navigator.of(
                            context,
                            rootNavigator: true,
                          );
                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );

                          // Show loading
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder:
                                (_) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                          );

                          try {
                            await AuthService().signOut();
                            // Success - Close loading dialog.
                            // navigator is from root so it's safe to use even if ProfileTab is unmounted.
                            navigator.pop();
                          } catch (e) {
                            navigator.pop(); // Close loading
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text("Đăng xuất thất bại: $e")),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRichHeader(UserModel user) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomLeft,
      children: [
        // Cover Image
        GestureDetector(
          onTap: () => _showCoverOptions(context, user.coverUrl),
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.purple[100],
              image:
                  user.coverUrl != null
                      ? DecorationImage(
                        image: NetworkImage(user.coverUrl!),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                user.coverUrl == null
                    ? Center(
                      child: Icon(
                        Icons.image,
                        color: Colors.purple[200],
                        size: 50,
                      ),
                    )
                    : null,
          ),
        ),

        if (_isUploading)
          const Positioned.fill(
            child: Center(child: CircularProgressIndicator()),
          ),

        // Avatar & Info Overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black54],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar with Edit Icon
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 8),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[300],
                        backgroundImage:
                            user.photoUrl != null
                                ? NetworkImage(user.photoUrl!)
                                : null,
                        child:
                            user.photoUrl == null
                                ? const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.grey,
                                )
                                : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _pickImage(true),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // Interactive Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfileScreen(user: user),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              user.name,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  const Shadow(
                                    color: Colors.black45,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.edit,
                              color: Colors.white.withOpacity(0.8),
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                      if (user.username != null)
                        Text(
                          "@${user.username}",
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            shadows: [
                              const Shadow(
                                color: Colors.black45,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      _buildModeTag(user),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeTag(UserModel user) {
    String label = "Cá nhân";
    Color color = Colors.blue;

    if (user.role == 'couple') {
      label = "Cặp đôi";
      color = Colors.pink;
    } else if (user.role == 'creator') {
      label = "Nhà sáng tạo";
      color = Colors.purple;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper widget - Keep old signature but change implementation if needed (or remove if fully cutting)
  // Actually, I'll remove _buildStatsRow entirely from usage first.

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
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
            activeThumbColor: const Color(0xFFFF4081),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    IconData icon, {
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive ? Colors.red : Colors.grey[700],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDestructive ? Colors.red : Colors.black87,
                  fontWeight:
                      isDestructive ? FontWeight.w600 : FontWeight.normal,
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
