import 'package:cloud_firestore/cloud_firestore.dart';

class QuizAttemptModel {
  final String id;
  final String userId;
  final String quizId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>
  answers; // questionId : value (int index, double value, etc)
  final int score;
  final int earnedXp;

  // Couple Mode
  final String? partnerId;
  final String? partnerAttemptId;
  final double? compatibilityScore;

  QuizAttemptModel({
    required this.id,
    required this.userId,
    required this.quizId,
    required this.startedAt,
    this.completedAt,
    required this.answers,
    this.score = 0,
    this.earnedXp = 0,
    this.partnerId,
    this.partnerAttemptId,
    this.compatibilityScore,
  });

  factory QuizAttemptModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuizAttemptModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      quizId: data['quizId'] ?? '',
      startedAt: (data['startedAt'] as Timestamp).toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      answers: Map<String, dynamic>.from(data['answers'] ?? {}),
      score: data['score'] ?? 0,
      earnedXp: data['earnedXp'] ?? 0,
      partnerId: data['partnerId'],
      partnerAttemptId: data['partnerAttemptId'],
      compatibilityScore: (data['compatibilityScore'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'quizId': quizId,
      'startedAt': startedAt,
      'completedAt': completedAt,
      'answers': answers,
      'score': score,
      'earnedXp': earnedXp,
      'partnerId': partnerId,
      'partnerAttemptId': partnerAttemptId,
      'compatibilityScore': compatibilityScore,
    };
  }

  bool get isCompleted => completedAt != null;
}
