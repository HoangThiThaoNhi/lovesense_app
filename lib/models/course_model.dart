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
  final bool isApproved;
  final DateTime createdAt;

  // New Fields
  final String level; // 'Basic', 'Intermediate', 'Advanced'
  final String targetAudience; // 'Individual', 'Couple', 'Both'
  final List<String> tags;
  final String duration; // e.g., '30 mins'

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
    this.level = 'Basic',
    this.targetAudience = 'Both',
    this.tags = const [],
    this.duration = '',
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
      level: data['level'] ?? 'Basic',
      targetAudience: data['targetAudience'] ?? 'Both',
      tags: List<String>.from(data['tags'] ?? []),
      duration: data['duration'] ?? '',
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
      'level': level,
      'targetAudience': targetAudience,
      'tags': tags,
      'duration': duration,
    };
  }
}
