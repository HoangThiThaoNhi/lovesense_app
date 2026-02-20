import 'package:flutter/material.dart';
import '../../models/lesson_model.dart';
import '../../services/course_service.dart';
import 'package:google_fonts/google_fonts.dart';

class LessonScreen extends StatefulWidget {
  final String courseId;
  const LessonScreen({super.key, required this.courseId});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final CourseService _courseService = CourseService();
  int _currentLessonIndex = 0;
  List<LessonModel> _lessons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  void _loadLessons() {
    _courseService.getLessonsStream(widget.courseId).listen((lessons) {
      if (mounted) {
        setState(() {
          _lessons = lessons; // Assuming service sorts them by order
          _isLoading = false;
        });
      }
    });
  }

  void _nextLesson() {
    if (_currentLessonIndex < _lessons.length - 1) {
      setState(() {
        _currentLessonIndex++;
      });
    } else {
      // Course Completed
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chúc mừng! Bạn đã hoàn thành khóa học.")),
      );
    }
  }

  void _prevLesson() {
    if (_currentLessonIndex > 0) {
      setState(() {
        _currentLessonIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_lessons.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Khóa học chưa có bài học.")),
      );
    }

    final lesson = _lessons[_currentLessonIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bài ${_currentLessonIndex + 1}/${_lessons.length}',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Content Area (Video or Image Placeholder)
          Container(
            height: 220,
            width: double.infinity,
            color: Colors.black,
            child:
                lesson.type == LessonType.video
                    ? const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 60,
                      ),
                    )
                    : const Center(
                      child: Text(
                        "HÌNH ẢNH / AUDIO",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    lesson.contentText,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Interactive Section (Reflection / Task)
                  if (lesson.reflectionQuestion != null &&
                      lesson.reflectionQuestion!.isNotEmpty)
                    _buildReflectionBox(lesson),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentLessonIndex > 0)
              TextButton.icon(
                onPressed: _prevLesson,
                icon: const Icon(Icons.arrow_back),
                label: const Text("Bài trước"),
              )
            else
              const SizedBox(width: 80),

            ElevatedButton(
              onPressed: () {
                // Mark complete logic here
                _courseService.completeLesson(
                  courseId: widget.courseId,
                  lessonId: lesson.id,
                  totalLessons: _lessons.length,
                  journalEntry: "Completed", // Placeholder
                );
                _nextLesson();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF673AB7),
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                _currentLessonIndex == _lessons.length - 1
                    ? "Hoàn thành"
                    : "Tiếp tục",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReflectionBox(LessonModel lesson) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note, color: Colors.purple),
              const SizedBox(width: 8),
              Text(
                "Góc suy ngẫm",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lesson.reflectionQuestion!,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Nhập suy nghĩ của bạn...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
