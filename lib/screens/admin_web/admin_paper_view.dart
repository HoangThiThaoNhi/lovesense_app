import 'package:flutter/material.dart';
import '../../services/content_service.dart';
import '../../models/blog_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'paper_editor_screen.dart'; // We are refactoring this file to be BlogEditorScreen

class AdminBlogView extends StatefulWidget {
  const AdminBlogView({super.key});

  @override
  State<AdminBlogView> createState() => _AdminBlogViewState();
}

class _AdminBlogViewState extends State<AdminBlogView> {
  final ContentService _contentService = ContentService();
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Quản lý Blog (Articles)",
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openEditor(context),
                  icon: const Icon(Icons.add),
                  label: const Text("Tạo Blog Mới"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6200EA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Filters
            Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 12),
                _buildFilterChip('Love'),
                const SizedBox(width: 12),
                _buildFilterChip('Self-Growth'),
                const SizedBox(width: 12),
                _buildFilterChip('Psychology'),
                const SizedBox(width: 12),
                _buildFilterChip('Tips'),
              ],
            ),
             const SizedBox(height: 24),

            Expanded(
              child: StreamBuilder<List<BlogModel>>(
                stream: _contentService.getBlogsStream(category: _selectedCategory, isAdmin: true),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final blogs = snapshot.data!;

                  if (blogs.isEmpty) {
                    return Center(
                      child: Text("Chưa có bài viết nào.", style: GoogleFonts.inter(fontSize: 16)),
                    );
                  }

                  return ListView.separated(
                    itemCount: blogs.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final blog = blogs[index];
                      return ListTile(
                        leading: Container(
                          width: 80,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            image: blog.coverImage.isNotEmpty
                                ? DecorationImage(image: NetworkImage(blog.coverImage), fit: BoxFit.cover)
                                : null,
                          ),
                          child: blog.coverImage.isEmpty ? const Icon(Icons.article) : null,
                        ),
                        title: Row(
                          children: [
                            if (blog.isFeatured) 
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(4)),
                                child: const Text("Featured", style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold)),
                              ),
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: blog.status == 'published' ? Colors.green[100] : Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                blog.status == 'published' ? "PUBLISHED" : "DRAFT",
                                style: TextStyle(
                                  fontSize: 10, 
                                  color: blog.status == 'published' ? Colors.green[800] : Colors.black54, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                            Expanded(child: Text(blog.title, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${blog.category} • ${DateFormat('dd/MM/yyyy').format(blog.createdAt.toDate())} • ${blog.readingTime} min read"),
                            if (blog.tags.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Wrap(
                                  spacing: 4,
                                  children: blog.tags.take(3).map((t) => Text("#$t", style: TextStyle(color: Colors.blue[600], fontSize: 11))).toList(),
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                             Column(
                               mainAxisAlignment: MainAxisAlignment.center,
                               crossAxisAlignment: CrossAxisAlignment.end,
                               children: [
                                 Text("Views: ${blog.viewCount}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                 Text("Likes: ${blog.likeCount} ♥", style: const TextStyle(fontSize: 12, color: Colors.red)),
                               ],
                             ),
                             const SizedBox(width: 16),
                             IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _openEditor(context, blog: blog),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(context, blog.id),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedCategory == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedCategory = label);
      },
    );
  }

  void _openEditor(BuildContext context, {BlogModel? blog}) {
     Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BlogEditorScreen(blog: blog)),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc chắn muốn xóa bài blog này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _contentService.deleteBlog(id);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

