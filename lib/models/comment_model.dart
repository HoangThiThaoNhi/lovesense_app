import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final Timestamp timestamp;
  final int likes;
  final String? parentId; // For nested replies
  final int replyCount;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.timestamp,
    this.likes = 0,
    this.parentId,
    this.replyCount = 0,
  });

  factory CommentModel.fromMap(String id, Map<String, dynamic> data) {
    return CommentModel(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      userAvatar: data['userAvatar'] ?? '',
      content: data['content'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      likes: data['likes'] ?? 0,
      parentId: data['parentId'],
      replyCount: data['replyCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'timestamp': timestamp,
      'likes': likes,
      'parentId': parentId,
      'replyCount': replyCount,
    };
  }
}
