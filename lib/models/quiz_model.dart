import 'package:cloud_firestore/cloud_firestore.dart';

enum QuizType { standard, ranked }

enum QuizMode { individual, couple }

enum QuestionType { multipleChoice, scenario, slider, likert, text }

class QuizModel {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final QuizType type;
  final QuizMode mode;
  final String difficulty; // 'Easy', 'Medium', 'Hard'
  final List<Question> questions;
  final DateTime? startTime;
  final DateTime? endTime;

  final bool isRanked;
  final bool hasReward;
  final String rewardDescription;
  final int xpReward;

  QuizModel({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.type,
    required this.mode,
    required this.difficulty,
    required this.questions,
    this.startTime,
    this.endTime,
    this.isRanked = false,
    this.hasReward = false,
    this.rewardDescription = '',
    this.xpReward = 10,
  });

  factory QuizModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuizModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      coverUrl: data['coverUrl'] ?? '',
      type: _parseType(data['type']),
      mode: _parseMode(data['mode']),
      difficulty: data['difficulty'] ?? 'Easy',
      questions:
          (data['questions'] as List<dynamic>? ?? [])
              .map((q) => Question.fromMap(q))
              .toList(),
      startTime: (data['startTime'] as Timestamp?)?.toDate(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      isRanked: data['isRanked'] ?? false,
      hasReward: data['hasReward'] ?? false,
      rewardDescription: data['rewardDescription'] ?? '',
      xpReward: data['xpReward'] ?? 10,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'coverUrl': coverUrl,
      'type': type.name,
      'mode': mode.name,
      'difficulty': difficulty,
      'questions': questions.map((q) => q.toMap()).toList(),
      'startTime': startTime,
      'endTime': endTime,
      'isRanked': isRanked,
      'hasReward': hasReward,
      'rewardDescription': rewardDescription,
      'xpReward': xpReward,
    };
  }

  static QuizType _parseType(String? type) => QuizType.values.firstWhere(
    (e) => e.name == type,
    orElse: () => QuizType.standard,
  );
  static QuizMode _parseMode(String? mode) => QuizMode.values.firstWhere(
    (e) => e.name == mode,
    orElse: () => QuizMode.individual,
  );
}

abstract class Question {
  final String id;
  final String text;
  final QuestionType type;

  Question({required this.id, required this.text, required this.type});

  Map<String, dynamic> toMap();

  static Question fromMap(Map<String, dynamic> map) {
    final typeStr = map['type'] as String? ?? 'multipleChoice';
    final type = QuestionType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => QuestionType.multipleChoice,
    );

    switch (type) {
      case QuestionType.multipleChoice:
        return MultipleChoiceQuestion.fromMap(map);
      case QuestionType.slider:
        return SliderQuestion.fromMap(map);
      case QuestionType.scenario:
        return ScenarioQuestion.fromMap(map);
      case QuestionType.likert:
        return LikertQuestion.fromMap(map);
      case QuestionType.text:
        return TextQuestion.fromMap(map);
    }
  }
}

class MultipleChoiceQuestion extends Question {
  final List<String> options;
  final int correctIndex;
  final int points;

  MultipleChoiceQuestion({
    required super.id,
    required super.text,
    required this.options,
    required this.correctIndex,
    this.points = 10,
  }) : super(type: QuestionType.multipleChoice);

  @override
  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'type': type.name,
    'options': options,
    'correctIndex': correctIndex,
    'points': points,
  };

  factory MultipleChoiceQuestion.fromMap(Map<String, dynamic> map) =>
      MultipleChoiceQuestion(
        id: map['id'] ?? '',
        text: map['text'] ?? '',
        options: List<String>.from(map['options'] ?? []),
        correctIndex: map['correctIndex'] ?? 0,
        points: map['points'] ?? 10,
      );
}

class SliderQuestion extends Question {
  final double min;
  final double max;
  final String? minLabel;
  final String? maxLabel;
  final int divisions;

  SliderQuestion({
    required super.id,
    required super.text,
    this.min = 0,
    this.max = 100,
    this.minLabel,
    this.maxLabel,
    this.divisions = 10,
  }) : super(type: QuestionType.slider);

  @override
  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'type': type.name,
    'min': min,
    'max': max,
    'minLabel': minLabel,
    'maxLabel': maxLabel,
    'divisions': divisions,
  };

  factory SliderQuestion.fromMap(Map<String, dynamic> map) => SliderQuestion(
    id: map['id'] ?? '',
    text: map['text'] ?? '',
    min: (map['min'] ?? 0).toDouble(),
    max: (map['max'] ?? 100).toDouble(),
    minLabel: map['minLabel'],
    maxLabel: map['maxLabel'],
    divisions: map['divisions'] ?? 10,
  );
}

class LikertQuestion extends Question {
  final int scale; // 3, 5, 7

  LikertQuestion({required super.id, required super.text, this.scale = 5})
    : super(type: QuestionType.likert);

  @override
  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'type': type.name,
    'scale': scale,
  };

  factory LikertQuestion.fromMap(Map<String, dynamic> map) => LikertQuestion(
    id: map['id'] ?? '',
    text: map['text'] ?? '',
    scale: map['scale'] ?? 5,
  );
}

class ScenarioQuestion extends Question {
  final List<ScenarioOption> options;

  ScenarioQuestion({
    required super.id,
    required super.text,
    required this.options,
  }) : super(type: QuestionType.scenario);

  @override
  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'type': type.name,
    'options': options.map((o) => o.toMap()).toList(),
  };

  factory ScenarioQuestion.fromMap(Map<String, dynamic> map) =>
      ScenarioQuestion(
        id: map['id'] ?? '',
        text: map['text'] ?? '',
        options:
            (map['options'] as List? ?? [])
                .map((o) => ScenarioOption.fromMap(o))
                .toList(),
      );
}

class ScenarioOption {
  final String text;
  final int scoreImpact; // Emotion score change
  final String feedback;

  ScenarioOption({
    required this.text,
    this.scoreImpact = 0,
    this.feedback = '',
  });

  Map<String, dynamic> toMap() => {
    'text': text,
    'scoreImpact': scoreImpact,
    'feedback': feedback,
  };
  factory ScenarioOption.fromMap(Map<String, dynamic> map) => ScenarioOption(
    text: map['text'] ?? '',
    scoreImpact: map['scoreImpact'] ?? 0,
    feedback: map['feedback'] ?? '',
  );
}

class TextQuestion extends Question {
  TextQuestion({required super.id, required super.text})
    : super(type: QuestionType.text);
  @override
  Map<String, dynamic> toMap() => {'id': id, 'text': text, 'type': type.name};
  factory TextQuestion.fromMap(Map<String, dynamic> map) =>
      TextQuestion(id: map['id'] ?? '', text: map['text'] ?? '');
}
