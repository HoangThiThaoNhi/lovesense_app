import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/article_model.dart';

class ArticleDetailScreen extends StatelessWidget {
  final ArticleModel article;

  const ArticleDetailScreen({super.key, required this.article});

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
                article.imageUrl, 
                fit: BoxFit.cover,
                color: Colors.black26, 
                colorBlendMode: BlendMode.darken,
              ),
            ),
            leading: const BackButton(color: Colors.white),
            actions: [
               IconButton(onPressed: (){}, icon: const Icon(Icons.bookmark_border, color: Colors.white)),
               IconButton(onPressed: (){}, icon: const Icon(Icons.share, color: Colors.white)),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      article.category.toUpperCase(),
                      style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    article.title, 
                    style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(article.authorAvatar),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(article.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                           Text(
                            "${article.createdAt.day} thg ${article.createdAt.month}, ${article.createdAt.year} • 5 min read",
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Content (Simple text for now, could be Markdown)
                  Text(
                    article.content, // Assuming rich text or markdown later
                    style: GoogleFonts.merriweather( // Serif for reading
                      fontSize: 16,
                      height: 1.8,
                      color: Colors.black87
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
