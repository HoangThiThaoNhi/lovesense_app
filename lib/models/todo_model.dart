import 'package:cloud_firestore/cloud_firestore.dart';

enum TodoCategory { personal, together, forUs }

enum TodoStatus { notStarted, inProgress, waitingPartner, completed, archived }

enum TodoAssignee { me, partner, both }

class TodoModel {
  final String id;
  final String task;
  final bool done;
  final int priority; // 0: Low, 1: Medium, 2: High
  final bool isArchived;
  final Timestamp? timestamp;
  final Timestamp? deletedAt;
  // New fields for Couple Mode Deep Dive
  final TodoCategory category;
  final TodoAssignee assignedTo;
  final bool isShared;
  final TodoStatus status;
  final String?
  partnerReaction; // Legacy, keeping for backward compatibility or removing if safe. Let's keep it but deprecate.
  final bool aiSuggested;
  final String creatorId;

  // New fields for deep tracking
  final Map<String, Timestamp> viewedBy;
  final List<String> completedBy;
  final Map<String, String> reactions; // userId -> emoji

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
    this.viewedBy = const {},
    this.completedBy = const [],
    this.reactions = const {},
  });

  factory TodoModel.fromMap(String id, Map<String, dynamic> data) {
    // Parse viewedBy Map safely
    Map<String, Timestamp> parsedViewedBy = {};
    if (data['viewedBy'] is Map) {
      final Map rawViewedBy = data['viewedBy'];
      rawViewedBy.forEach((key, value) {
        if (value is Timestamp) {
          parsedViewedBy[key.toString()] = value;
        }
      });
    }

    // Parse reactions safely
    Map<String, String> parsedReactions = {};
    if (data['reactions'] is Map) {
      final Map rawReactions = data['reactions'];
      rawReactions.forEach((key, value) {
        parsedReactions[key.toString()] = value.toString();
      });
    }

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
      viewedBy: parsedViewedBy,
      completedBy: List<String>.from(data['completedBy'] ?? []),
      reactions: parsedReactions,
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
      'viewedBy': viewedBy,
      'completedBy': completedBy,
      'reactions': reactions,
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
    Map<String, Timestamp>? viewedBy,
    List<String>? completedBy,
    Map<String, String>? reactions,
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
      viewedBy: viewedBy ?? this.viewedBy,
      completedBy: completedBy ?? this.completedBy,
      reactions: reactions ?? this.reactions,
    );
  }
}
