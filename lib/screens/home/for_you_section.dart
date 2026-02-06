import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/video_model.dart';
import '../../models/article_model.dart';
import '../../services/admin_service.dart';
import '../content/content_feed_screen.dart';

class ForYouSection extends StatelessWidget {
  const ForYouSection({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminService adminService = AdminService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dành cho bạn',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ContentFeedScreen()));
                },
                child: Text('Xem tất cả', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFFF4081))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280, // Height for the cards
          child: FutureBuilder(
            future: Future.wait([
              adminService.getVideosStream().first,
              adminService.getArticlesStream().first,
            ]),
            builder: (context, AsyncSnapshot<List<QuerySnapshot>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Lỗi tải nội dung: ${snapshot.error}"));
              }

              final videoDocs = snapshot.data?[0].docs ?? [];
              final articleDocs = snapshot.data?[1].docs ?? [];

              final List<dynamic> mixedContent = [];
              
              // Add top 3 videos
              for (var doc in videoDocs.take(3)) {
                mixedContent.add(VideoModel.fromFirestore(doc));
              }
              // Add top 3 articles
              for (var doc in articleDocs.take(3)) {
                mixedContent.add(ArticleModel.fromFirestore(doc));
              }

              // Sort by date descending
              mixedContent.sort((a, b) {
                DateTime dateA = a is VideoModel ? a.createdAt : (a as ArticleModel).createdAt;
                DateTime dateB = b is VideoModel ? b.createdAt : (b as ArticleModel).createdAt;
                return dateB.compareTo(dateA);
              });

              if (mixedContent.isEmpty) {
                return const Center(child: Text("Chưa có nội dung mới."));
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: mixedContent.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final item = mixedContent[index];
                  if (item is VideoModel) {
                    return _buildVideoCard(context, item);
                  } else {
                    return _buildArticleCard(context, item as ArticleModel);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVideoCard(BuildContext context, VideoModel video) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  video.thumbnailUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 120, color: Colors.grey[300], child: const Icon(Icons.broken_image)),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(4)),
                  child: Row(
                    children: [
                      const Icon(Icons.play_arrow, color: Colors.white, size: 10),
                      const SizedBox(width: 2),
                      Text(video.duration, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const Positioned.fill(
                child: Center(
                  child: CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: Icon(Icons.play_arrow, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.category.toUpperCase(),
                  style: TextStyle(fontSize: 10, color: Colors.purple[300], fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildArticleCard(BuildContext context, ArticleModel article) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              article.imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(height: 120, color: Colors.grey[300], child: const Icon(Icons.article)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                   article.category.toUpperCase(),
                   style: TextStyle(fontSize: 10, color: Colors.blue[300], fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, height: 1.3),
                ),
                const SizedBox(height: 8),
                Text(
                  article.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }
}
