import 'package:cloud_firestore/cloud_firestore.dart';

class UserCourseProgress {
  final String id; // Doc ID
  final String userId;
  final String courseId;
  final List<String> completedLessonIds;
  final Map<String, String> journalEntries; // lessonId: entry
  final double progressPercent;
  final DateTime updatedAt;
  final bool isCompleted;

  UserCourseProgress({
    required this.id,
    required this.userId,
    required this.courseId,
    this.completedLessonIds = const [],
    this.journalEntries = const {},
    this.progressPercent = 0.0,
    required this.updatedAt,
    this.isCompleted = false,
  });

  factory UserCourseProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserCourseProgress(
      id: doc.id,
      userId: data['userId'] ?? '',
      courseId: data['courseId'] ?? '',
      completedLessonIds: List<String>.from(data['completedLessonIds'] ?? []),
      journalEntries: Map<String, String>.from(data['journalEntries'] ?? {}),
      progressPercent: (data['progressPercent'] ?? 0.0).toDouble(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'courseId': courseId,
      'completedLessonIds': completedLessonIds,
      'journalEntries': journalEntries,
      'progressPercent': progressPercent,
      'updatedAt': updatedAt,
      'isCompleted': isCompleted,
    };
  }
}

class CoupleCourseProgress {
  final String id;
  final String coupleId;
  final String courseId;
  final String user1Id;
  final String user2Id;
  final List<String> userIds; // [user1Id, user2Id] for array-contains queries
  final List<String> user1CompletedLessons;
  final List<String> user2CompletedLessons;
  final Map<String, double> compatibilityScores; // lessonId: score
  final DateTime updatedAt;

  CoupleCourseProgress({
    required this.id,
    required this.coupleId,
    required this.courseId,
    required this.user1Id,
    required this.user2Id,
    required this.userIds,
    this.user1CompletedLessons = const [],
    this.user2CompletedLessons = const [],
    this.compatibilityScores = const {},
    required this.updatedAt,
  });

  factory CoupleCourseProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CoupleCourseProgress(
      id: doc.id,
      coupleId: data['coupleId'] ?? '',
      courseId: data['courseId'] ?? '',
      user1Id: data['user1Id'] ?? '',
      user2Id: data['user2Id'] ?? '',
      userIds: List<String>.from(data['userIds'] ?? []),
      user1CompletedLessons: List<String>.from(
        data['user1CompletedLessons'] ?? [],
      ),
      user2CompletedLessons: List<String>.from(
        data['user2CompletedLessons'] ?? [],
      ),
      compatibilityScores: Map<String, double>.from(
        data['compatibilityScores']?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            {},
      ),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'coupleId': coupleId,
      'courseId': courseId,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'userIds': userIds,
      'user1CompletedLessons': user1CompletedLessons,
      'user2CompletedLessons': user2CompletedLessons,
      'compatibilityScores': compatibilityScores,
      'updatedAt': updatedAt,
    };
  }
}
