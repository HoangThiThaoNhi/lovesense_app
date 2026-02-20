import 'package:flutter/material.dart';
import '../../models/blog_model.dart';
import '../../services/content_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'paper_detail_screen.dart'; // Will be refactored to BlogDetailScreen
import 'saved_blogs_screen.dart'; // New screen
import 'package:flutter_animate/flutter_animate.dart';

class BlogFeedScreen extends StatefulWidget {
  const BlogFeedScreen({super.key});

  @override
  State<BlogFeedScreen> createState() => _BlogFeedScreenState();
}

class _BlogFeedScreenState extends State<BlogFeedScreen> {
  final ContentService _contentService = ContentService();
  String _selectedCategory = 'All';
  String? _selectedTag; // New filter
  final TextEditingController _searchController = TextEditingController();
  List<BlogModel>? _searchResults;
  final bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Search logic remains similar but client-side for now
  void _performSearch(String query) async {
    if (query.isEmpty) {
      if (mounted) setState(() => _searchResults = null);
      return;
    }
    
    // Note: ContentService.searchPapers was removed/needs update. 
    // For now we will filter the stream or implement a basic search if needed.
    // Implementing a basic client-side filter on the stream data is better for small datasets.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          "Lovesense Blog",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.black87),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedBlogsScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Tìm kiếm bài viết...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) {
                 // Simple local search could go here
              },
            ),
          ),

          // Categories & Tags
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip('All'),
                const SizedBox(width: 8),
                _buildCategoryChip('Love'),
                const SizedBox(width: 8),
                _buildCategoryChip('Self-Growth'),
                const SizedBox(width: 8),
                _buildCategoryChip('Psychology'),
                const SizedBox(width: 8),
                _buildCategoryChip('Tips'),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          // Content
          Expanded(
            child: StreamBuilder<List<BlogModel>>(
              stream: _contentService.getBlogsStream(category: _selectedCategory, tag: _selectedTag),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final blogs = snapshot.data!;
                if (blogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text("Chưa có bài viết nào", style: GoogleFonts.inter(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: blogs.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _buildBlogCard(blogs[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = _selectedCategory == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedCategory = label);
      },
      selectedColor: const Color(0xFF6200EA),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (blog.coverImage.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  blog.coverImage,
                  fit: BoxFit.cover,
                  errorBuilder: (_,__,___) => Container(color: Colors.grey[200]),
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
                          color: const Color(0xFF6200EA).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          blog.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6200EA),
                          ),
                        ),
                      ),
                      if (blog.isFeatured) ...[
                        const SizedBox(width: 8),
                         Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "FEATURED",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        DateFormat('dd/MM/yyyy').format(blog.createdAt.toDate()),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    blog.title,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    blog.description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  
                  // Footer Stats
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                       const SizedBox(width: 4),
                      Text("${blog.readingTime} min", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(width: 16),
                      Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text("${blog.viewCount}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                       const SizedBox(width: 16),
                      Icon(Icons.favorite_border, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text("${blog.likeCount}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const Spacer(),
                      Text("Đọc tiếp ->", style: GoogleFonts.inter(color: const Color(0xFF6200EA), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOutQuad),
    );
  }
}
