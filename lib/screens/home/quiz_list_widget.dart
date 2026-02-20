import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/quiz_model.dart';
import 'quiz_screen.dart'; // We will create this next

class QuizListWidget extends StatelessWidget {
  const QuizListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thử thách vui',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Xem tất cả',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6200EA)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('content')
                .doc('quizzes')
                .collection('items')
                // .where('isActive', isEqualTo: true) // Assuming field exists or we filter later
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Lỗi tải quiz: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                 return _buildEmptyState();
              }

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                clipBehavior: Clip.none,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final quiz = QuizModel.fromFirestore(docs[index]);
                  return _buildQuizCard(context, quiz);
                },
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms).moveX(begin: 30, end: 0);
  }

   Widget _buildEmptyState() {
     return Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.purple[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purple[100]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology_outlined, size: 40, color: Colors.purple[200]),
            const SizedBox(height: 8),
            Text(
              "Sắp có thử thách mới",
              style: GoogleFonts.inter(color: Colors.purple[300]),
            ),
          ],
        ),
      );
  }

  Widget _buildQuizCard(BuildContext context, QuizModel quiz) {
    final isRanked = quiz.type == QuizType.ranked;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => QuizScreen(quiz: quiz)),
        );
      },
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Image/Color
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isRanked ? const Color(0xFF2D3436) : Colors.purple[50],
                image: quiz.coverUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(quiz.coverUrl),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.4),
                          BlendMode.darken,
                        ),
                      )
                    : null,
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                   if (isRanked) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emoji_events, size: 12, color: Colors.black),
                          const SizedBox(width: 4),
                          Text(
                            'Đua Top nhận quà',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    quiz.title,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${quiz.questions.length} câu hỏi • ${isRanked ? "Có thưởng" : "Giải trí"}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Play Button Overlay
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(isRanked ? 0.2 : 0.9),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: isRanked ? Colors.white : Colors.purple,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
