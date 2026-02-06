import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class _LearningHubScreenState extends State<LearningHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();

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
        title: Text('Trung tâm Phát triển', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF673AB7), // Deep Purple
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
        children: [
          _buildCoursesTab(),
          _buildChallengesTab(),
        ],
      ),
    );
  }

  Widget _buildCoursesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _adminService.getCoursesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF673AB7)));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("Chưa có khóa học nào", style: GoogleFonts.inter(color: Colors.grey)));
        }

        final courses = snapshot.data!.docs.map((doc) => CourseModel.fromFirestore(doc)).toList();

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: courses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) => _buildCourseCard(courses[index]),
        );
      },
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => CourseDetailScreen(course: course)));
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    course.thumbnailUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(height: 150, color: Colors.grey[200], child: const Icon(Icons.class_outlined)),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_circle_outline, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text('${course.lessonsCount} bài', style: const TextStyle(color: Colors.white, fontSize: 10)),
                      ],
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
                    style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.purple[100],
                        child: Text(course.instructorName[0], style: const TextStyle(fontSize: 8)),
                      ),
                      const SizedBox(width: 6),
                      Text(course.instructorName, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      Text('${course.rating}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
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

  Widget _buildChallengesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _adminService.getQuizzesStream(),
      builder: (context, snapshot) {
         if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF673AB7)));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("Chưa có thử thách nào", style: GoogleFonts.inter(color: Colors.grey)));
        }

        final quizzes = snapshot.data!.docs.map((doc) => QuizModel.fromFirestore(doc)).toList();

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
        color: quiz.type == QuizType.ranked ? const Color(0xFFFFF8E1) : Colors.white, // Pale Amber for Ranked
        borderRadius: BorderRadius.circular(16),
        border: quiz.type == QuizType.ranked ? Border.all(color: Colors.amber, width: 1) : null,
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
             color: quiz.type == QuizType.ranked ? Colors.amber[100] : Colors.purple[50],
             borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
             quiz.type == QuizType.ranked ? Icons.emoji_events : Icons.quiz,
             color: quiz.type == QuizType.ranked ? Colors.orange[800] : Colors.purple,
             size: 28,
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(quiz.title, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16))),
            if (quiz.isRanked)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                child: const Text('RANKED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
             Text(quiz.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600])),
            if (quiz.hasReward) ...[
               const SizedBox(height: 4),
               Row(
                 children: [
                   const Icon(Icons.card_giftcard, size: 14, color: Colors.pink),
                   const SizedBox(width: 4),
                   Text(quiz.rewardDescription, style: GoogleFonts.inter(color: Colors.pink, fontSize: 12, fontWeight: FontWeight.w600)),
                 ],
               )
            ],
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => QuizPlayerScreen(quiz: quiz)));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: quiz.type == QuizType.ranked ? Colors.orange : const Color(0xFF673AB7),
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
