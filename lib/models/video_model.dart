import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String videoUrl;
  final String duration;
  final String category;
  final DateTime createdAt;

  VideoModel({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.duration,
    required this.category,
    required this.createdAt,
  });

  factory VideoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoModel(
      id: doc.id,
      title: data['title'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      duration: data['duration'] ?? '',
      category: data['category'] ?? 'General',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'videoUrl': videoUrl,
      'duration': duration,
      'category': category,
      'createdAt': createdAt,
    };
  }
}
