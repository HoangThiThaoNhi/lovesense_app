import 'package:cloud_firestore/cloud_firestore.dart';

enum ReflectionMood { better, normal, difficult }

class TaskLogModel {
  final String id;
  final String taskId;
  final DateTime completedAt;
  final ReflectionMood reflectionMood;
  final String? reflectionText;

  TaskLogModel({
    required this.id,
    required this.taskId,
    required this.completedAt,
    required this.reflectionMood,
    this.reflectionText,
  });

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'completedAt': Timestamp.fromDate(completedAt),
      'reflectionMood': reflectionMood.name,
      'reflectionText': reflectionText,
    };
  }

  factory TaskLogModel.fromMap(String id, Map<String, dynamic> map) {
    return TaskLogModel(
      id: id,
      taskId: map['taskId'] ?? '',
      completedAt:
          (map['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reflectionMood: ReflectionMood.values.firstWhere(
        (e) => e.name == map['reflectionMood'],
        orElse: () => ReflectionMood.normal,
      ),
      reflectionText: map['reflectionText'],
    );
  }
}
