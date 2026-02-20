import 'package:cloud_firestore/cloud_firestore.dart';

class PaperModel {
  final String id;
  final String title;
  final String summary;
  final String content; // Markdown or HTML
  final String imageUrl;
  final String category;
  final String status; // 'draft', 'published'
  final String authorId;
  final String authorName;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  
  // Stats
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final double ratingAvg;
  final int ratingCount;

  PaperModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.imageUrl,
    required this.category,
    this.status = 'draft',
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.updatedAt,
    this.viewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
  });

  factory PaperModel.fromMap(String id, Map<String, dynamic> data) {
    return PaperModel(
      id: id,
      title: data['title'] ?? '',
      summary: data['summary'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? 'General',
      status: data['status'] ?? 'draft',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Admin',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'],
      viewCount: data['viewCount'] ?? 0,
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      ratingAvg: (data['ratingAvg'] ?? 0.0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'summary': summary,
      'content': content,
      'imageUrl': imageUrl,
      'category': category,
      'status': status,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
      'viewCount': viewCount,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'ratingAvg': ratingAvg,
      'ratingCount': ratingCount,
    };
  }

  PaperModel copyWith({
    String? title,
    String? summary,
    String? content,
    String? imageUrl,
    String? category,
    String? status,
    String? authorName,
    Timestamp? updatedAt,
    int? viewCount,
    int? likeCount,
    int? commentCount,
    double? ratingAvg,
    int? ratingCount,
  }) {
    return PaperModel(
      id: id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      status: status ?? this.status,
      authorId: authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }
}
