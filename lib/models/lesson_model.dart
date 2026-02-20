import 'package:cloud_firestore/cloud_firestore.dart';

enum LessonType { video, audio, text }

class LessonModel {
  final String id;
  final String courseId; // Parent course
  final String title;
  final String description;
  final LessonType type;
  final String contentUrl; // For video/audio
  final String contentText; // For text insights
  final int order; // Sequence 1, 2, 3...
  final int estimatedMinutes;

  // Specific Fields
  final String? reflectionQuestion; // Individual
  final String? coupleActionTask; // Couple

  LessonModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.type,
    required this.contentUrl,
    required this.contentText,
    required this.order,
    required this.estimatedMinutes,
    this.reflectionQuestion,
    this.coupleActionTask,
  });

  factory LessonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LessonModel(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: LessonType.values.firstWhere(
        (e) => e.toString().split('.').last == (data['type'] ?? 'text'),
        orElse: () => LessonType.text,
      ),
      contentUrl: data['contentUrl'] ?? '',
      contentText: data['contentText'] ?? '',
      order: data['order'] ?? 0,
      estimatedMinutes: data['estimatedMinutes'] ?? 5,
      reflectionQuestion: data['reflectionQuestion'],
      coupleActionTask: data['coupleActionTask'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'contentUrl': contentUrl,
      'contentText': contentText,
      'order': order,
      'estimatedMinutes': estimatedMinutes,
      'reflectionQuestion': reflectionQuestion,
      'coupleActionTask': coupleActionTask,
    };
  }
}
