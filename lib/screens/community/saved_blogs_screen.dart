import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/blog_model.dart';
import '../../services/content_service.dart';
import 'paper_detail_screen.dart';

class SavedBlogsScreen extends StatefulWidget {
  const SavedBlogsScreen({super.key});

  @override
  State<SavedBlogsScreen> createState() => _SavedBlogsScreenState();
}

class _SavedBlogsScreenState extends State<SavedBlogsScreen> {
  final ContentService _contentService = ContentService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Đã lưu")),
        body: const Center(child: Text("Vui lòng đăng nhập để xem bài viết đã lưu.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          "Bài viết đã lưu",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: StreamBuilder<List<String>>(
        stream: _contentService.getSavedBlogIdsStream(_uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final savedIds = snapshot.data!;

          if (savedIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("Bạn chưa lưu bài viết nào", style: GoogleFonts.inter(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: savedIds.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final blogId = savedIds[index];
              return FutureBuilder<BlogModel?>(
                future: _contentService.getBlog(blogId),
                builder: (context, blogSnapshot) {
                  if (!blogSnapshot.hasData) return const SizedBox(); // Loading or null
                  final blog = blogSnapshot.data;
                  if (blog == null) return const SizedBox(); // Deleted blog

                  return _buildBlogCard(blog);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBlogCard(BlogModel blog) {
    return GestureDetector(
      onTap: () {
         Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BlogDetailScreen(blog: blog)),
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
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Image
            if (blog.coverImage.isNotEmpty)
              SizedBox(
                width: 120,
                height: 120,
                child: Image.network(
                  blog.coverImage,
                  fit: BoxFit.cover,
                  errorBuilder: (_,__,___) => Container(color: Colors.grey[200]),
                ),
              ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6200EA).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            blog.category.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6200EA),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('dd/MM').format(blog.createdAt.toDate()),
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      blog.title,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                         const SizedBox(width: 4),
                        Text("${blog.readingTime} min", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        const SizedBox(width: 16),
                        Icon(Icons.favorite, size: 14, color: Colors.red[300]),
                        const SizedBox(width: 4),
                        Text("${blog.likeCount}", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
