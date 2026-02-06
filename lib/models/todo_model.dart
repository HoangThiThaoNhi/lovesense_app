import 'package:cloud_firestore/cloud_firestore.dart';

class TodoModel {
  final String id;
  final String task;
  final bool done;
  final int priority; // 0: Low, 1: Medium, 2: High
  final bool isArchived;
  final Timestamp? timestamp;

  TodoModel({
    required this.id,
    required this.task,
    this.done = false,
    this.priority = 1, // Default Medium
    this.isArchived = false,
    this.timestamp,
  });

  factory TodoModel.fromMap(String id, Map<String, dynamic> data) {
    return TodoModel(
      id: id,
      task: data['task'] ?? '',
      done: data['done'] ?? false,
      priority: data['priority'] ?? 1,
      isArchived: data['isArchived'] ?? false,
      timestamp: data['timestamp'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'task': task,
      'done': done,
      'priority': priority,
      'isArchived': isArchived,
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
    };
  }

  TodoModel copyWith({
    String? task,
    bool? done,
    int? priority,
    bool? isArchived,
  }) {
    return TodoModel(
      id: id,
      task: task ?? this.task,
      done: done ?? this.done,
      priority: priority ?? this.priority,
      isArchived: isArchived ?? this.isArchived,
      timestamp: timestamp,
    );
  }
}
