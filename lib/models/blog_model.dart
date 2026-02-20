import 'package:cloud_firestore/cloud_firestore.dart';

class BlogModel {
  final String id;
  final String title;
  final String description; // Was summary
  final String content; // html or markdown
  final String coverImage; // Was imageUrl
  final String category;
  final List<String> tags;
  final String authorId;
  final bool isFeatured;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final int readingTime; // minutes
  final String status; // "draft" | "published"
  final Timestamp createdAt;
  final Timestamp updatedAt;

  BlogModel({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.coverImage,
    required this.category,
    required this.tags,
    required this.authorId,
    this.isFeatured = false,
    this.likeCount = 0,
    this.commentCount = 0,
    this.viewCount = 0,
    this.readingTime = 0,
    this.status = 'draft',
    required this.createdAt,
    required this.updatedAt,
  });

  factory BlogModel.fromMap(String id, Map<String, dynamic> data) {
    return BlogModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      content: data['content'] ?? '',
      coverImage: data['coverImage'] ?? '',
      category: data['category'] ?? 'General',
      tags: List<String>.from(data['tags'] ?? []),
      authorId: data['authorId'] ?? '',
      isFeatured: data['isFeatured'] ?? false,
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      viewCount: data['viewCount'] ?? 0,
      readingTime: data['readingTime'] ?? 0,
      status: data['status'] ?? 'draft',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'coverImage': coverImage,
      'category': category,
      'tags': tags,
      'authorId': authorId,
      'isFeatured': isFeatured,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'viewCount': viewCount,
      'readingTime': readingTime,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class BlogComment {
  final String id;
  final String blogId;
  final String userId;
  final String content;
  final Timestamp createdAt;
  final String status; // 'active' | 'hidden'
  final String? parentId; // For replies
  final int replyCount; // To show "View 3 replies"
  
  // Optional: User display info helper
  final String? userName; 
  final String? userAvatar;

  BlogComment({
    required this.id,
    required this.blogId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.status = 'active',
    this.parentId,
    this.replyCount = 0,
    this.userName,
    this.userAvatar,
  });

  factory BlogComment.fromMap(String id, Map<String, dynamic> data) {
    return BlogComment(
      id: id,
      blogId: data['blogId'] ?? '',
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      status: data['status'] ?? 'active',
      parentId: data['parentId'],
      replyCount: data['replyCount'] ?? 0,
      userName: data['userName'],
      userAvatar: data['userAvatar'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'blogId': blogId,
      'userId': userId,
      'content': content,
      'createdAt': createdAt,
      'status': status,
      'parentId': parentId,
      'replyCount': replyCount,
      'userName': userName,
      'userAvatar': userAvatar,
    };
  }
}
