import 'package:cloud_firestore/cloud_firestore.dart';

enum TodoCategory { personal, together, forUs }

enum TodoStatus { notStarted, inProgress, waiting, completed }

enum TodoAssignee { me, partner, both }

class TodoModel {
  final String id;
  final String task;
  final bool done;
  final int priority; // 0: Low, 1: Medium, 2: High
  final bool isArchived;
  final Timestamp? timestamp;
  final Timestamp? deletedAt;

  // New fields for Couple Mode
  final TodoCategory category;
  final TodoAssignee assignedTo;
  final bool isShared;
  final TodoStatus status;
  final String? partnerReaction;
  final bool aiSuggested;
  final String creatorId;

  TodoModel({
    required this.id,
    required this.task,
    this.done = false,
    this.priority = 1, // Default Medium
    this.isArchived = false,
    this.timestamp,
    this.deletedAt,
    this.category = TodoCategory.personal,
    this.assignedTo = TodoAssignee.me,
    this.isShared = false,
    this.status = TodoStatus.notStarted,
    this.partnerReaction,
    this.aiSuggested = false,
    this.creatorId = '',
  });

  factory TodoModel.fromMap(String id, Map<String, dynamic> data) {
    return TodoModel(
      id: id,
      task: data['task'] ?? '',
      done: data['done'] ?? false,
      priority: data['priority'] ?? 1,
      isArchived: data['isArchived'] ?? false,
      timestamp: data['timestamp'],
      deletedAt: data['deletedAt'],
      category: TodoCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => TodoCategory.personal,
      ),
      assignedTo: TodoAssignee.values.firstWhere(
        (e) => e.name == data['assignedTo'],
        orElse: () => TodoAssignee.me,
      ),
      isShared: data['isShared'] ?? false,
      status: TodoStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TodoStatus.notStarted,
      ),
      partnerReaction: data['partnerReaction'],
      aiSuggested: data['aiSuggested'] ?? false,
      creatorId: data['creatorId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'task': task,
      'done': done,
      'priority': priority,
      'isArchived': isArchived,
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
      'deletedAt': deletedAt,
      'category': category.name,
      'assignedTo': assignedTo.name,
      'isShared': isShared,
      'status': status.name,
      'partnerReaction': partnerReaction,
      'aiSuggested': aiSuggested,
      'creatorId': creatorId,
    };
  }

  TodoModel copyWith({
    String? task,
    bool? done,
    int? priority,
    bool? isArchived,
    Timestamp? deletedAt,
    TodoCategory? category,
    TodoAssignee? assignedTo,
    bool? isShared,
    TodoStatus? status,
    String? partnerReaction,
    bool? aiSuggested,
    String? creatorId,
  }) {
    return TodoModel(
      id: id,
      task: task ?? this.task,
      done: done ?? this.done,
      priority: priority ?? this.priority,
      isArchived: isArchived ?? this.isArchived,
      timestamp: timestamp,
      deletedAt: deletedAt ?? this.deletedAt,
      category: category ?? this.category,
      assignedTo: assignedTo ?? this.assignedTo,
      isShared: isShared ?? this.isShared,
      status: status ?? this.status,
      partnerReaction: partnerReaction ?? this.partnerReaction,
      aiSuggested: aiSuggested ?? this.aiSuggested,
      creatorId: creatorId ?? this.creatorId,
    );
  }
}
