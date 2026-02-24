import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskType { oneTime, repeating }

class GoalTaskModel {
  final String id;
  final String goalId;
  final String title;
  final TaskType type;
  final String? frequency; // e.g., 'daily', 'weekly'
  final DateTime? dueDate;
  final bool isCompleted;
  final bool isArchived;
  final int streak;
  final DateTime createdAt;

  GoalTaskModel({
    required this.id,
    required this.goalId,
    required this.title,
    this.type = TaskType.oneTime,
    this.frequency,
    this.dueDate,
    this.isCompleted = false,
    this.isArchived = false,
    this.streak = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'goalId': goalId,
      'title': title,
      'type': type.name,
      'frequency': frequency,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'isCompleted': isCompleted,
      'isArchived': isArchived,
      'streak': streak,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory GoalTaskModel.fromMap(String id, Map<String, dynamic> map) {
    return GoalTaskModel(
      id: id,
      goalId: map['goalId'] ?? '',
      title: map['title'] ?? '',
      type: TaskType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TaskType.oneTime,
      ),
      frequency: map['frequency'],
      dueDate: (map['dueDate'] as Timestamp?)?.toDate(),
      isCompleted: map['isCompleted'] ?? false,
      isArchived: map['isArchived'] ?? false,
      streak: map['streak'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
