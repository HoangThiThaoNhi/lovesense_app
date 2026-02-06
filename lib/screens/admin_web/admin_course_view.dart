import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/course_model.dart';
import '../../services/admin_service.dart';

class AdminCourseView extends StatefulWidget {
  const AdminCourseView({super.key});

  @override
  State<AdminCourseView> createState() => _AdminCourseViewState();
}

class _AdminCourseViewState extends State<AdminCourseView> {
  final AdminService _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quản lý Khóa học & Kỹ năng',
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Các môn học kỹ năng và bài giảng từ cộng đồng.',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddCourseDialog(context),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Tạo khóa học mới'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF673AB7), // Deep Purple for Learning
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _adminService.getCoursesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('Chưa có danh sách khóa học', style: GoogleFonts.inter(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final course = CourseModel.fromFirestore(docs[index]);
                    return _buildCourseCard(course);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumb
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                course.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey[100], child: const Icon(Icons.class_outlined)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'SKILL',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepPurple[700]),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text('${course.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  course.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "By ${course.instructorName}",
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                 Text(
                  "${course.lessonsCount} bài học",
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _adminService.deleteCourse(course.id),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showAddCourseDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final imgCtrl = TextEditingController();
    final instructorCtrl = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Thêm khóa học mới'),
          content: SingleChildScrollView(
            child: SizedBox(
               width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Tên khóa học')),
                  const SizedBox(height: 12),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Mô tả ngắn')),
                  const SizedBox(height: 12),
                  TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: 'URL Ảnh bìa')),
                  const SizedBox(height: 12),
                  TextField(controller: instructorCtrl, decoration: const InputDecoration(labelText: 'Giảng viên/Tác giả')),
                  if (isLoading) const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                setState(() => isLoading = true);
                try {
                  final newCourse = CourseModel(
                    id: '',
                    title: titleCtrl.text,
                    description: descCtrl.text,
                    thumbnailUrl: imgCtrl.text,
                    instructorId: 'admin',
                    instructorName: instructorCtrl.text.isEmpty ? 'Admin' : instructorCtrl.text,
                    createdAt: DateTime.now(),
                    lessonsCount: 5, // Mock initial count
                    rating: 5.0,
                  );
                  await _adminService.addCourse(newCourse);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  setState(() => isLoading = false);
                  // Show error
                }
              },
              child: const Text('Tạo khóa học'),
            ),
          ],
        ),
      ),
    );
  }
}
