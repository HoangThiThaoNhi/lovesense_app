import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/course_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CourseDetailScreen extends StatelessWidget {
  final CourseModel course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                course.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'SKILL COURSE',
                          style: TextStyle(color: Colors.purple[700], fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      Text(' ${course.rating} (120 reviews)', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    course.title,
                    style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Created by ${course.instructorName}',
                    style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
                  ),
                   const SizedBox(height: 24),
                   Text("Giới thiệu", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   Text(
                     course.description,
                     style: GoogleFonts.inter(fontSize: 15, height: 1.5, color: Colors.grey[800]),
                   ),
                   const SizedBox(height: 32),
                   Text("Nội dung khóa học (${course.lessonsCount} bài)", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 16),
                   // Mock Lessons List
                   ListView.separated(
                     padding: EdgeInsets.zero,
                     shrinkWrap: true,
                     physics: const NeverScrollableScrollPhysics(),
                     itemCount: course.lessonsCount,
                     separatorBuilder: (_, __) => const SizedBox(height: 12),
                     itemBuilder: (context, index) {
                       return Container(
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(
                           color: Colors.white,
                           borderRadius: BorderRadius.circular(12),
                           border: Border.all(color: Colors.grey[200]!),
                         ),
                         child: Row(
                           children: [
                             Container(
                               width: 40, height: 40,
                               decoration: BoxDecoration(color: Colors.purple[50], shape: BoxShape.circle),
                               child: Center(child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple))),
                             ),
                             const SizedBox(width: 16),
                             Expanded(
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text("Bài học ${index + 1}: Giới thiệu", style: const TextStyle(fontWeight: FontWeight.w600)),
                                   Text("15:00", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                 ],
                               ),
                             ),
                             const Icon(Icons.play_circle_outline, color: Colors.purple),
                           ],
                         ),
                       );
                     },
                   ),
                   const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF673AB7),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('Bắt đầu học ngay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    ).animate().fadeIn();
  }
}
