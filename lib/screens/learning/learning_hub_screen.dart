import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/course_service.dart';
import '../../services/admin_service.dart';
import '../../models/course_model.dart';
import '../../models/quiz_model.dart';
import 'course_detail_screen.dart';
import 'quiz_player_screen.dart';

class LearningHubScreen extends StatefulWidget {
  const LearningHubScreen({super.key});

  @override
  State<LearningHubScreen> createState() => _LearningHubScreenState();
}

class _LearningHubScreenState extends State<LearningHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CourseService _courseService = CourseService();
  final AdminService _adminService = AdminService();

  // Filters
  String _selectedMode = 'All'; // All, Individual, Couple
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Trung tâm Phát triển',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF673AB7),
          unselectedLabelColor: Colors.grey,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          indicatorColor: const Color(0xFF673AB7),
          tabs: const [
            Tab(text: 'Khóa học Kỹ năng'),
            Tab(text: 'Thử thách & Quiz'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildCoursesTab(), _buildChallengesTab()],
      ),
    );
  }

  Widget _buildCoursesTab() {
    return Column(
      children: [
        // Search & Filter Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm khóa học...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Tất cả', 'All'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Cá nhân', 'Individual'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Cặp đôi', 'Couple'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Course List
        Expanded(
          child: StreamBuilder<List<CourseModel>>(
            // Pass 'Both' implies we need logic to handle 'All'.
            // If Selected is All, we pass null to service to get everything?
            // Service supports targetAudience.
            stream: _courseService.getCoursesStream(
              targetAudience: _selectedMode == 'All' ? null : _selectedMode,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF673AB7)),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    "Chưa có khóa học nào",
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                );
              }

              // Client-side Search Filtering
              final courses =
                  snapshot.data!.where((c) {
                    return c.title.toLowerCase().contains(_searchQuery);
                  }).toList();

              if (courses.isEmpty) {
                return Center(
                  child: Text(
                    "Không tìm thấy kết quả",
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: courses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder:
                    (context, index) => _buildCourseCard(courses[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedMode == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF673AB7) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CourseDetailScreen(course: course)),
        );
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    course.thumbnailUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Container(
                          height: 160,
                          color: Colors.grey[200],
                          child: const Icon(Icons.class_outlined),
                        ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_circle_outline,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${course.lessonsCount} bài',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          course.targetAudience == 'Couple'
                              ? Colors.pink
                              : Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      course.targetAudience == 'Couple'
                          ? 'Couple'
                          : 'Individual',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getLevelColor(course.level).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _getLevelColor(
                              course.level,
                            ).withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          course.level,
                          style: TextStyle(
                            fontSize: 10,
                            color: _getLevelColor(course.level),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      Text(
                        ' ${course.rating}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Basic':
        return Colors.green;
      case 'Intermediate':
        return Colors.orange;
      case 'Advanced':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget _buildChallengesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _adminService.getQuizzesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF673AB7)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "Chưa có thử thách nào",
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          );
        }

        final quizzes =
            snapshot.data!.docs
                .map((doc) => QuizModel.fromFirestore(doc))
                .toList();

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: quizzes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) => _buildQuizCard(quizzes[index]),
        );
      },
    );
  }

  Widget _buildQuizCard(QuizModel quiz) {
    return Container(
      decoration: BoxDecoration(
        color:
            quiz.type == QuizType.ranked
                ? const Color(0xFFFFF8E1)
                : Colors.white, // Pale Amber for Ranked
        borderRadius: BorderRadius.circular(16),
        border:
            quiz.type == QuizType.ranked
                ? Border.all(color: Colors.amber, width: 1)
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color:
                quiz.type == QuizType.ranked
                    ? Colors.amber[100]
                    : Colors.purple[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            quiz.type == QuizType.ranked ? Icons.emoji_events : Icons.quiz,
            color:
                quiz.type == QuizType.ranked
                    ? Colors.orange[800]
                    : Colors.purple,
            size: 28,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                quiz.title,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (quiz.isRanked)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'RANKED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              quiz.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (quiz.hasReward) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.card_giftcard, size: 14, color: Colors.pink),
                  const SizedBox(width: 4),
                  Text(
                    quiz.rewardDescription,
                    style: GoogleFonts.inter(
                      color: Colors.pink,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => QuizPlayerScreen(quiz: quiz)),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                quiz.type == QuizType.ranked
                    ? Colors.orange
                    : const Color(0xFF673AB7),
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: const Text('Tham gia'),
        ),
      ),
    );
  }
}
