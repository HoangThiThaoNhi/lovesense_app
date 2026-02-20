import 'package:cloud_firestore/cloud_firestore.dart';

enum ChallengeType { daily, weekly, topic }

enum ChallengeStatus { active, completed, expired }

class ChallengeModel {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final ChallengeType type;
  final String difficulty; // 'Easy', 'Medium', 'Hard'
  final DateTime endDate;
  final int xpReward;
  final String? badgeReward;
  final String quizId; // Linked quiz

  ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.type,
    required this.difficulty,
    required this.endDate,
    required this.xpReward,
    this.badgeReward,
    required this.quizId,
  });

  factory ChallengeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChallengeModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      coverUrl: data['coverUrl'] ?? '',
      type: ChallengeType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ChallengeType.daily,
      ),
      difficulty: data['difficulty'] ?? 'Easy',
      endDate: (data['endDate'] as Timestamp).toDate(),
      xpReward: data['xpReward'] ?? 0,
      badgeReward: data['badgeReward'],
      quizId: data['quizId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'coverUrl': coverUrl,
      'type': type.name,
      'difficulty': difficulty,
      'endDate': endDate,
      'xpReward': xpReward,
      'badgeReward': badgeReward,
      'quizId': quizId,
    };
  }

  // Helper
  String get timeLeft {
    final diff = endDate.difference(DateTime.now());
    if (diff.isNegative) return "Ended";
    if (diff.inDays > 0) return "${diff.inDays} days left";
    return "${diff.inHours}h ${diff.inMinutes % 60}m left";
  }
}
