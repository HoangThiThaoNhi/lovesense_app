import 'package:flutter/material.dart';
import 'ai_chat_widget.dart';
import 'mood_check_in_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/ai_service.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback? onNavigateToProfile;

  const HomeTab({super.key, this.onNavigateToProfile});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // Mock Data
  // Mood data moved to MoodService

  late Stream<UserModel?> _userStream;
  late Stream<QuerySnapshot> _todoStream;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    if (_uid != null) {
      _userStream = AuthService().getUserStream(_uid!);
      _todoStream =
          FirebaseFirestore.instance
              .collection('users')
              .doc(_uid)
              .collection('todos')
              .orderBy('timestamp', descending: true)
              .snapshots();
    } else {
      // Handle guest case if needed, though MainScreen guards this
      _userStream = Stream.value(null);
      _todoStream = Stream.empty();
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Main.dart handles auth redirection, so user is likely logged in.
    // If null transiently, show loading.
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF4081)),
        ),
      );
    }

    return StreamBuilder<UserModel?>(
      // Use distinct to avoid rebuilding if data hasn't changed? Firestore streams usually handle this.
      stream: _userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFFF4081)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text("Không thể tải thông tin: ${snapshot.error}"),
            ),
          );
        }

        final userModel = snapshot.data;
        final String fullName = userModel?.name ?? 'Bạn';
        final String name =
            fullName.isNotEmpty ? fullName.split(' ').last : 'Bạn';
        final String? photoUrl = userModel?.photoUrl;

        return Scaffold(
          backgroundColor: const Color(0xFFFAFAFA),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header
                  _buildHeader(name, photoUrl),

                  const SizedBox(height: 32),

                  // 2. Mood Check-in
                  _buildMoodCheckIn(),

                  const SizedBox(height: 32),

                  // 3. AI Coach Suggestion
                  _buildAiSuggestion(),

                  const SizedBox(height: 32),

                  // 4. Daily To-Do List
                  _buildToDoSection(),

                  const SizedBox(height: 32),

                  // 5. Recommended Courses (Dành cho bạn)
                  _buildCoursesSection(),

                  const SizedBox(height: 32),

                  // 6. Community Highlights (Cộng đồng)
                  _buildCommunitySection(),

                  const SizedBox(height: 80), // Bottom padding for FAB
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showAiChatbot,
            backgroundColor: const Color(0xFF6200EA),
            icon: const Icon(Icons.smart_toy, color: Colors.white),
            label: Text(
              'AI Chat',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate().scale(delay: 1.seconds),
        );
      },
    );
  }

  Widget _buildHeader(String name, String? photoUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_greeting, $name 🌱',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hôm nay bạn cảm thấy thế nào?',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
            // Avatar
            GestureDetector(
              onTap: widget.onNavigateToProfile,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF4081), width: 2),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      photoUrl != null && photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                  child:
                      (photoUrl == null || photoUrl.isEmpty)
                          ? const Icon(
                            Icons.favorite_rounded,
                            color: Color(0xFFFF4081),
                            size: 24,
                          )
                          : null,
                ),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn().moveY(begin: -20, end: 0);
  }

  // Method logic replaced by separated widget
  Widget _buildMoodCheckIn() {
    return const MoodCheckInWidget();
  }

  Widget _buildAiSuggestion() {
    final hasChatted = AIService().hasChatted;
    final suggestions = AIService().getSuggestions();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              hasChatted
                  ? [
                    const Color(0xFFE3F2FD),
                    const Color(0xFFBBDEFB),
                  ] // Blue for Suggestions
                  : [
                    const Color(0xFFF3E5F5),
                    const Color(0xFFE1BEE7),
                  ], // Purple for New User
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    hasChatted ? Icons.auto_awesome : Icons.waving_hand,
                    color: hasChatted ? Colors.blueAccent : Colors.purple,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasChatted ? 'Gợi ý từ AI Coach' : 'Làm quen với AI',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: hasChatted ? Colors.blue[800] : Colors.purple[800],
                    ),
                  ),
                ],
              ),
              if (hasChatted)
                IconButton(
                  // Quick Chat Trigger
                  onPressed: _showAiChatbot,
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.blueAccent,
                    size: 20,
                  ),
                  tooltip: 'Hỏi AI ngay',
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (!hasChatted) ...[
            Text(
              'Chào bạn! Mình là AI Coach của Lovesense.',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hãy chia sẻ một chút về cảm xúc của bạn hôm nay để mình có thể đưa ra những lời khuyên hữu ích nhé!',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAiChatbot,
                icon: const Icon(Icons.chat, size: 18),
                label: const Text("Tâm sự ngay"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ] else ...[
            Text(
              'Hôm nay bạn có thể thử:',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ...suggestions.map((s) => _buildAiActionItem(s)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid != null) {
                    final batch = FirebaseFirestore.instance.batch();
                    for (var task in suggestions) {
                      final docRef =
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .collection('todos')
                              .doc();
                      batch.set(docRef, {
                        'task': task,
                        'done': false,
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                    }
                    await batch.commit();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Đã thêm gợi ý vào danh sách việc cần làm!',
                          ),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.add_task, size: 18),
                label: const Text("Áp dụng gợi ý AI"),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.6),
                  foregroundColor: Colors.blue[800],
                  side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).scale();
  }

  Widget _buildAiActionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.arrow_right_alt, size: 18, color: Colors.blue),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // --- New Features ---

  // Mock To-Do Data
  // Cloud based Todo List (Migrated to Firestore)

  Widget _buildToDoSection() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Danh sách việc cần làm',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Tính năng thêm thủ công sẽ sớm ra mắt! Hãy nhờ AI gợi ý nhé.",
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.add_circle_outline,
                color: Color(0xFFFF4081),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _todoStream,
          builder: (context, snapshot) {
            // Loading State
            if (!snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final docs = snapshot.data!.docs;

            // Empty State
            if (docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "Chưa có nhiệm vụ nào.\nHãy chat với AI để nhận gợi ý!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.grey),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final id = docs[index].id;
                final task = data['task'] ?? '';
                final isDone = data['done'] ?? false;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isDone
                              ? Colors.green.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .collection('todos')
                              .doc(id)
                              .update({'done': !isDone});
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone ? Colors.green : Colors.transparent,
                            border: Border.all(
                              color: isDone ? Colors.green : Colors.grey,
                              width: 2,
                            ),
                          ),
                          child:
                              isDone
                                  ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          task,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            decoration:
                                isDone ? TextDecoration.lineThrough : null,
                            color: isDone ? Colors.grey : Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .collection('todos')
                              .doc(id)
                              .delete();
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildCommunitySection() {
    // Mock Community Posts
    final List<Map<String, String>> posts = [
      {
        'user': 'An Nhiên',
        'title': 'Cách mình vượt qua áp lực đồng trang lứa',
        'likes': '124',
        'image': 'https://picsum.photos/id/1/200/200',
      },
      {
        'user': 'Minh Nhật',
        'title': 'Góc làm việc chill chill cuối tuần 🌿',
        'likes': '89',
        'image': 'https://picsum.photos/id/2/200/200',
      },
      {
        'user': 'Thảo Chi',
        'title': 'Hành trình chữa lành sau chia tay',
        'likes': '256',
        'image': 'https://picsum.photos/id/3/200/200',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cộng đồng Lovesense',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'Xem tất cả >',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: posts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final post = posts[index];
              return Container(
                width: 260,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        post['image']!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[200],
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            post['title']!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 8,
                                backgroundColor: Colors.pink,
                                child: Icon(
                                  Icons.person,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                post['user']!,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.favorite,
                                size: 12,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${post['likes']} chanh sả',
                                style: GoogleFonts.inter(fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms).moveX(begin: 30, end: 0);
  }

  void _showAiChatbot() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: const AiChatWidget(),
          ),
    );
  }

  Widget _buildCoursesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dành cho bạn',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _buildCourseCard(
                'Chữa lành đứa trẻ bên trong',
                '15 phút',
                Colors.pink[100]!,
              ),
              const SizedBox(width: 16),
              _buildCourseCard(
                'Quản lý cảm xúc tiêu cực',
                '10 phút',
                Colors.green[100]!,
              ),
              const SizedBox(width: 16),
              _buildCourseCard(
                'Xây dựng sự tự tin',
                '20 phút',
                Colors.blue[100]!,
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms).moveX(begin: 50, end: 0);
  }

  Widget _buildCourseCard(String title, String duration, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow_rounded, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                duration,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
