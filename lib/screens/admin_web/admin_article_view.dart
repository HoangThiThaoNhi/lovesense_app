import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/article_model.dart';
import '../../services/admin_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminArticleView extends StatefulWidget {
  const AdminArticleView({super.key});

  @override
  State<AdminArticleView> createState() => _AdminArticleViewState();
}

class _AdminArticleViewState extends State<AdminArticleView> {
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
            offset: const Offset(0, 10)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quản lý Bài viết',
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chia sẻ kiến thức và câu chuyện truyền cảm hứng.',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddArticleDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Thêm bài viết mới'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4081),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  shadowColor: Colors.pink.withOpacity(0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _adminService.getArticlesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có bài viết nào',
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8, // Taller for articles
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index];
                    final article = ArticleModel.fromFirestore(data);
                    return _buildArticleCard(article);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(ArticleModel article) {
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
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                article.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[100],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      article.category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.remove_red_eye, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('${article.views}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      IconButton(
                        onPressed: () => _deleteArticle(article),
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Xóa bài viết',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteArticle(ArticleModel article) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bài viết?'),
        content: Text('Bạn có chắc muốn xóa "${article.title}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await _adminService.deleteArticle(article.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showAddArticleDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final contentController = TextEditingController();
    final imgController = TextEditingController();
    String category = 'Mental Health';
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Thêm bài viết mới', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề bài viết',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: category,
                          decoration: const InputDecoration(
                            labelText: 'Danh mục',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Mental Health', child: Text('Mental Health (Sức khỏe tâm thần)')),
                            DropdownMenuItem(value: 'Relationship', child: Text('Relationship (Mối quan hệ)')),
                            DropdownMenuItem(value: 'Self-care', child: Text('Self-care (Chăm sóc bản thân)')),
                            DropdownMenuItem(value: 'Love', child: Text('Love (Tình yêu)')),
                            DropdownMenuItem(value: 'News', child: Text('News (Tin tức)')),
                          ],
                          onChanged: (val) => category = val!,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: imgController,
                    decoration: const InputDecoration(
                      labelText: 'Link ảnh bìa (URL)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.image),
                      helperText: 'Nên dùng ảnh tỷ lệ 16:9 hoặc ảnh ngang chất lượng cao.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả ngắn (Sapo)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.short_text),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Nội dung chi tiết (Có thể dùng Markdown)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  if (isLoading) const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Đăng bài'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4081),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: isLoading ? null : () async {
                if (titleController.text.isEmpty || imgController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tiêu đề và ảnh bìa')),
                  );
                  return;
                }

                setState(() => isLoading = true);

                try {
                  final newArticle = ArticleModel(
                    id: '', // Firestore auto-id
                    title: titleController.text.trim(),
                    description: descController.text.trim(),
                    content: contentController.text.trim(),
                    imageUrl: imgController.text.trim(),
                    category: category,
                    authorId: 'admin_1', // Mock admin ID
                    authorName: 'Admin Lovesense',
                    authorAvatar: 'https://ui-avatars.com/api/?name=Admin',
                    createdAt: DateTime.now(),
                  );

                  await _adminService.addArticle(newArticle);
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đăng bài viết thành công!'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  setState(() => isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
