import 'package:cloud_firestore/cloud_firestore.dart';

class QuizModel {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final QuizType type;
  final List<Question> questions;
  final DateTime? startTime;
  final DateTime? endTime;
  
  // New Fields
  final bool isRanked;
  final bool hasReward;
  final String rewardDescription;

  QuizModel({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.type,
    required this.questions,
    this.startTime,
    this.endTime,
    this.isRanked = false,
    this.hasReward = false,
    this.rewardDescription = '',
  });

  factory QuizModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuizModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      coverUrl: data['coverUrl'] ?? '',
      type: _parseType(data['type']),
      questions: (data['questions'] as List<dynamic>? ?? [])
          .map((q) => Question.fromMap(q))
          .toList(),
      startTime: (data['startTime'] as Timestamp?)?.toDate(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      isRanked: data['isRanked'] ?? (data['type'] == 'ranked'), // Backwards compat
      hasReward: data['hasReward'] ?? false,
      rewardDescription: data['rewardDescription'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'coverUrl': coverUrl,
      'type': type == QuizType.ranked ? 'ranked' : 'standard',
      'questions': questions.map((q) => q.toMap()).toList(),
      'startTime': startTime,
      'endTime': endTime,
      'isRanked': isRanked,
      'hasReward': hasReward,
      'rewardDescription': rewardDescription,
    };
  }

  static QuizType _parseType(String? type) {
    if (type == 'ranked') return QuizType.ranked;
    return QuizType.standard;
  }
}

enum QuizType { standard, ranked }

class Question {
  final String question;
  final List<String> options;
  final int correctIndex;

  Question({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctIndex: map['correctIndex'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
    };
  }
}
