import 'package:cloud_firestore/cloud_firestore.dart';

class ArticleModel {
  final String id;
  final String title;
  final String description;
  final String content;
  final String imageUrl;
  final String category;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final DateTime createdAt;
  final int views;
  final int likes;

  ArticleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.imageUrl,
    required this.category,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.createdAt,
    this.views = 0,
    this.likes = 0,
  });

  factory ArticleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ArticleModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? 'General',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Admin',
      authorAvatar: data['authorAvatar'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      views: data['views'] ?? 0,
      likes: data['likes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'imageUrl': imageUrl,
      'category': category,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'createdAt': createdAt,
      'views': views,
      'likes': likes,
    };
  }
}
