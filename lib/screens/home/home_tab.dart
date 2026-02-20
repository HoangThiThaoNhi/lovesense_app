import 'package:flutter/material.dart';
import 'for_you_section.dart';
import 'ai_chat_widget.dart';
import 'mood_check_in_widget.dart';
import 'todo_list_widget.dart';
import 'couple_todo_widget.dart';
import 'couple_mood_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/profile_service.dart';
import '../../services/notification_service.dart';
import '../profile/widgets/requests_modal.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/ai_service.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../learning/learning_hub_screen.dart';
import '../community/paper_feed_screen.dart';
import '../community/paper_detail_screen.dart';
import '../../services/content_service.dart';
import '../../models/blog_model.dart';

// ... existing imports ...

// ... inside _HomeTabState ...

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
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    if (_uid != null) {
      _userStream = AuthService().getUserStream(_uid);
    } else {
      // Handle guest case if needed, though MainScreen guards this
      _userStream = Stream.value(null);
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
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
            // Actions Row
            Row(
              children: [
                // Notification Bell
                StreamBuilder<List<dynamic>>(
                  stream: ProfileService().getPendingRequests(),
                  builder: (context, reqSnapshot) {
                    final requestCount = reqSnapshot.data?.length ?? 0;
                    return StreamBuilder<int>(
                      stream: NotificationService().getUnreadCount(),
                      builder: (context, notifSnapshot) {
                        final unreadNotifCount = notifSnapshot.data ?? 0;
                        final totalBadgeCount = requestCount + unreadNotifCount;
                        return IconButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const RequestsModal(),
                            );
                          },
                          icon: Badge(
                            isLabelVisible: totalBadgeCount > 0,
                            label: Text('$totalBadgeCount'),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              size: 28,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(width: 8),
                // Avatar
                GestureDetector(
                  onTap: widget.onNavigateToProfile,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF4081),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[200],
                      backgroundImage:
                          photoUrl != null &&
                                  photoUrl.trim().isNotEmpty &&
                                  photoUrl.startsWith('http')
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
        ),
      ],
    ).animate().fadeIn().moveY(begin: -20, end: 0);
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
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Không thể tải thông tin",
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text("Thử lại"),
                    ),
                  ],
                ),
              ),
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
                  if (userModel != null && userModel.role == 'couple') ...[
                    CoupleMoodWidget(currentUser: userModel),
                    const SizedBox(height: 16),
                  ],
                  _buildMoodCheckIn(),

                  const SizedBox(height: 32),

                  // 3. AI Coach Suggestion
                  _buildAiSuggestion(),

                  const SizedBox(height: 32),

                  // 4. Daily To-Do List
                  _buildToDoSection(userModel),

                  const SizedBox(height: 32),

                  // 5. Recommended Courses (Dành cho bạn - Video)
                  _buildCoursesSection(),

                  const SizedBox(height: 32),

                  // 6. Growth & Challenges (Thử thách & Kỹ năng)
                  _buildGrowthHubSection(),

                  const SizedBox(height: 32),

                  // 7. Community Highlights (Cộng đồng)
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
                        'priority': 1,
                        'isArchived': false,
                        'deletedAt': null,
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
  Widget _buildToDoSection(UserModel? userModel) {
    if (userModel != null && userModel.role == 'couple') {
      return CoupleTodoWidget(currentUser: userModel);
    } else {
      return const TodoListWidget();
    }
  }

  // ... (inside build method, scrolling down to Community Section)

  Widget _buildCommunitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Lovesense Blog',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BlogFeedScreen()),
                );
              },
              child: Text(
                'Xem tất cả >',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: StreamBuilder<List<BlogModel>>(
            stream: ContentService().getBlogsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Icon(Icons.error));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final blogs = snapshot.data!;
              if (blogs.isEmpty) {
                return Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text("Chưa có bài viết nào"),
                );
              }

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: blogs.length > 5 ? 5 : blogs.length, // Limit 5
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final blog = blogs[index];
                  return GestureDetector(
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlogDetailScreen(blog: blog),
                          ),
                        ),
                    child: Container(
                      width: 280,
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
                              blog.coverImage.isNotEmpty
                                  ? blog.coverImage
                                  : 'https://via.placeholder.com/150',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.article,
                                      color: Colors.grey,
                                    ),
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
                                  blog.title,
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.purple[50],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        blog.category,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.purple[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 12,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${blog.readingTime} min",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.remove_red_eye,
                                      size: 12,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${blog.viewCount}",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
    return const ForYouSection();
  }

  Widget _buildGrowthHubSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Thử thách & Kỹ năng',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LearningHubScreen()),
                );
              },
              child: Text(
                'Khám phá',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFFFF4081),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LearningHubScreen()),
              ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF673AB7), Color(0xFF9575CD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'MỚI',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nâng cấp bản thân',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tham gia khóa học kỹ năng và thử thách có thưởng hấp dẫn!',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                // Using a generic placeholder icon/image if network is risky, or a safe icon
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.amber,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
