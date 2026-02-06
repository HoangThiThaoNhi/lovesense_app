import 'package:cloud_firestore/cloud_firestore.dart';

class CourseModel {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String instructorId;
  final String instructorName;
  final int lessonsCount;
  final double rating;
  final bool isApproved; // Content moderation
  final DateTime createdAt;

  // We might store lessons in a sub-collection for scalability, 
  // but for simplicity/MVP, we can assume a simplified structure or just metadata here.
  // We'll keep it simple: Metadata first.

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.instructorId,
    required this.instructorName,
    this.lessonsCount = 0,
    this.rating = 0.0,
    this.isApproved = true,
    required this.createdAt,
  });

  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CourseModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      instructorId: data['instructorId'] ?? '',
      instructorName: data['instructorName'] ?? 'Admin',
      lessonsCount: data['lessonsCount'] ?? 0,
      rating: (data['rating'] ?? 0.0).toDouble(),
      isApproved: data['isApproved'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'instructorId': instructorId,
      'instructorName': instructorName,
      'lessonsCount': lessonsCount,
      'rating': rating,
      'isApproved': isApproved,
      'createdAt': createdAt,
    };
  }
}
