import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/goal_model.dart';
import '../models/goal_task_model.dart';
import '../models/task_log_model.dart';
import '../models/task_log_model.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

class GoalTodoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  String get _currentUserId => _auth.currentUser?.uid ?? '';

  /// Create a new Goal
  Future<String?> createGoal(
    GoalModel goal, {
    bool autoSuggestTasks = false,
  }) async {
    if (_currentUserId.isEmpty) return null;

    // Check if we exceed 5 active goals for this pillar
    final activeGoalsCount = await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('goals')
        .where('pillar', isEqualTo: goal.pillar.name)
        .where('status', isEqualTo: GoalStatus.active.name)
        .get()
        .then((snapshot) => snapshot.docs.length);

    if (activeGoalsCount >= 5) {
      throw Exception(
        'Bạn chỉ được tạo tối đa 5 mục tiêu đang hoạt động cho hạng mục này.',
      );
    }

    final newGoal = GoalModel(
      id: '',
      pillar: goal.pillar,
      title: goal.title,
      status: goal.status,
      createdAt: DateTime.now(),
      ownerId: _currentUserId,
      category: goal.category,
      duration: goal.duration,
      startDate: goal.startDate ?? DateTime.now(),
      endDate: goal.endDate,
      successMeasurement: goal.successMeasurement,
      baselineScore: goal.baselineScore,
      requiresPartnerConfirmation: goal.requiresPartnerConfirmation,
      partnerStatus: goal.requiresPartnerConfirmation ? 'pending' : 'active',
      visibility: goal.visibility,
      commitmentLevel: goal.commitmentLevel,
    );

    final docRef = await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('goals')
        .add(newGoal.toMap());

    if (autoSuggestTasks && goal.category != null) {
      _createSuggestedTasks(
        _currentUserId,
        docRef.id,
        goal.title,
        goal.category!,
      );
    }
    if (goal.pillar == PillarType.together && goal.requiresPartnerConfirmation) {
      // Find partner ID from 'users' collection or active relationships
      Future.microtask(() async {
        try {
          final myDoc = await _firestore.collection('users').doc(_currentUserId).get();
          final partnerId = myDoc.data()?['partnerId'] as String?;
          
          if (partnerId != null && partnerId.isNotEmpty) {
            await _notificationService.sendNotification(
              targetUserId: partnerId,
              type: NotificationType.goalInvitation,
              content: 'Đã mời bạn cùng thực hiện mục tiêu: ${goal.title}',
            );
          }
        } catch (e) {
          print('Error sending goal invitation notification: $e');
        }
      });
    }

    return docRef.id;
  }

  Future<void> _createSuggestedTasks(
    String ownerId,
    String goalId,
    String goalTitle,
    String category,
  ) async {
    try {
      final apiKey = AppConfig.groqApiKey;
      if (!apiKey.contains('YOUR_') && apiKey.isNotEmpty) {
        final url = Uri.parse(
          'https://api.groq.com/openai/v1/chat/completions',
        );
        final systemPrompt = '''
Bạn là AI hỗ trợ nhắc nhở mục tiêu. 
Dựa vào tên mục tiêu và danh mục, hãy trả về CHÍNH XÁC 3 nhiệm vụ (task) ngắn gọn, thực tế để bắt đầu.
Chỉ trả lời bằng danh sách các task, mỗi task trên 1 dòng. Không có giải thích, không đánh số thứ tự, bắt đầu mỗi dòng bằng dấu -
Ví dụ:
- Task 1
- Task 2
- Task 3
''';

        final response = await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': 'llama-3.3-70b-versatile',
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {
                'role': 'user',
                'content': 'Mục tiêu: $goalTitle. Danh mục: $category',
              },
            ],
            'temperature': 0.7,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final aiResponse =
              data['choices']?[0]?['message']?['content'] as String?;
          if (aiResponse != null && aiResponse.isNotEmpty) {
            final tasks =
                aiResponse
                    .split('\n')
                    .map(
                      (e) => e.replaceAll(RegExp(r'^[-*0-9.]+\s*'), '').trim(),
                    )
                    .where(
                      (e) =>
                          e.isNotEmpty &&
                          !e.toLowerCase().contains('dưới đây là'),
                    )
                    .take(3)
                    .toList();

            if (tasks.isNotEmpty) {
              for (final title in tasks) {
                final task = GoalTaskModel(
                  id: '',
                  goalId: goalId,
                  title: title,
                  isCompleted: false,
                  createdAt: DateTime.now(),
                  type: TaskType.oneTime,
                );
                createTask(ownerId, task);
              }
              return;
            }
          }
        }
      }
    } catch (e) {
      print("AI generation failed for tasks: \$e");
    }

    // FALLBACK
    final suggestions = {
      'Emotional Control': [
        'Thực hành hít thở sâu 5 phút',
        'Ghi nhật ký cảm xúc',
      ],
      'Self Improvement': [
        'Dành 15 phút thiền định',
        'Đọc 1 chương sách phát triển bản thân',
      ],
      'Discipline': ['Thức dậy đúng giờ', 'Hoàn thành to-do list ngày'],
      'Learning': ['Học 1 từ vựng mới', 'Xem 1 video TED Talk'],
      'Communication': [
        'Lắng nghe chủ động',
        'Chia sẻ cảm xúc chân thành 1 lần/ngày',
      ],
      'Conflict Resolution': [
        'Thực hành xin lỗi',
        'Dùng câu "Anh/Em cảm thấy..." thay vì đổ lỗi',
      ],
      'Quality Time': [
        'Dành 30 phút trò chuyện không điện thoại',
        'Lên kế hoạch hẹn hò cuối tuần',
      ],
      'Trust': ['Thông báo lịch trình rõ ràng', 'Giữ đúng một lời hứa nhỏ'],
      'Emotional Support': [
        'Hỏi thăm ngày hôm nay của người ấy',
        'Tặng 1 lời khen ngọt ngào',
      ],
      'Financial Planning': [
        'Ghi chép chi tiêu trong ngày',
        'Trích quỹ tiết kiệm chung',
      ],
      'Marriage Planning': [
        'Lên ý tưởng tổ chức đám cưới',
        'Tham khảo các gói chụp ảnh',
      ],
      'Family Plan': ['Gọi điện hỏi thăm gia đình', 'Lên kế hoạch về thăm nhà'],
      'Living Arrangement': [
        'Dọn dẹp không không gian chung',
        'Thỏa thuận phân chia việc nhà',
      ],
      'Long-term Vision': [
        'Viết ra 3 điều muốn đạt được cùng nhau',
        'Đọc chung 1 quyển sách',
      ],
    };

    final tasks =
        suggestions[category] ??
        ['Thực hiện bước đầu tiên', 'Lên kế hoạch chi tiết'];

    for (final title in tasks) {
      final task = GoalTaskModel(
        id: '',
        goalId: goalId,
        title: title,
        isCompleted: false,
        createdAt: DateTime.now(),
        type: TaskType.oneTime,
      );
      createTask(ownerId, task);
    }
  }

  /// Archive a Goal
  Future<void> archiveGoal(String goalId) async {
    if (_currentUserId.isEmpty) return;

    final goalDoc = await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('goals')
        .doc(goalId)
        .get();

    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('goals')
        .doc(goalId)
        .update({'status': GoalStatus.archived.name});

    if (goalDoc.exists) {
      final goal = GoalModel.fromMap(goalDoc.id, goalDoc.data()!);
      if (goal.pillar == PillarType.together || goal.visibility == 'both') {
        final myDoc =
            await _firestore.collection('users').doc(_currentUserId).get();
        final partnerId = myDoc.data()?['partnerId'] as String?;

        if (partnerId != null && partnerId.isNotEmpty) {
          await _notificationService.sendNotification(
            targetUserId: partnerId,
            type: NotificationType.goalUpdated,
            content: 'Đã lưu trữ mục tiêu: ${goal.title}',
          );
        }
      }
    }
  }

  /// Unarchive a Goal
  Future<void> unarchiveGoal(String goalId) async {
    if (_currentUserId.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('goals')
        .doc(goalId)
        .update({'status': GoalStatus.active.name});
  }

  /// Delete a Goal entirely
  Future<void> deleteGoal(String goalId) async {
    if (_currentUserId.isEmpty) return;

    // First, delete all tasks associated with this goal
    final tasksSnapshot =
        await _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('tasks')
            .where('goalId', isEqualTo: goalId)
            .get();

    WriteBatch batch = _firestore.batch();
    for (var doc in tasksSnapshot.docs) {
      batch.delete(doc.reference);

      // Also delete logs for these tasks
      final logsSnapshot =
          await _firestore
              .collection('users')
              .doc(_currentUserId)
              .collection('task_logs')
              .where('taskId', isEqualTo: doc.id)
              .get();
      for (var logDoc in logsSnapshot.docs) {
        batch.delete(logDoc.reference);
      }
    }

    // Fetch the goal to see if it's a Together goal
    final goalDoc = await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('goals')
        .doc(goalId)
        .get();

    if (goalDoc.exists) {
      final goal = GoalModel.fromMap(goalDoc.id, goalDoc.data()!);
      if (goal.pillar == PillarType.together || goal.visibility == 'both') {
        // Find partner ID to notify
        final myDoc =
            await _firestore.collection('users').doc(_currentUserId).get();
        final partnerId = myDoc.data()?['partnerId'] as String?;

        if (partnerId != null && partnerId.isNotEmpty) {
          await _notificationService.sendNotification(
            targetUserId: partnerId,
            type: NotificationType.goalDeleted,
            content: 'Đã xóa mục tiêu chung: ${goal.title}',
          );
        }
      }
    }

    // Delete the goal itself
    final goalRef = _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('goals')
        .doc(goalId);
    batch.delete(goalRef);

    await batch.commit();
  }

  /// Update a Goal title
  Future<void> updateGoalTitle(String goalId, String newTitle) async {
    if (_currentUserId.isEmpty) return;

    // Fetch goal to check if it's Together goal
    final goalDoc = await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('goals')
        .doc(goalId)
        .get();

    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('goals')
        .doc(goalId)
        .update({'title': newTitle});

    if (goalDoc.exists) {
      final goal = GoalModel.fromMap(goalDoc.id, goalDoc.data()!);
      if ((goal.pillar == PillarType.together || goal.visibility == 'both') && goal.title != newTitle) {
        final myDoc =
            await _firestore.collection('users').doc(_currentUserId).get();
        final partnerId = myDoc.data()?['partnerId'] as String?;

        if (partnerId != null && partnerId.isNotEmpty) {
          await _notificationService.sendNotification(
            targetUserId: partnerId,
            type: NotificationType.goalUpdated,
            content: 'Đã đổi tên mục tiêu "${goal.title}" thành "$newTitle"',
          );
        }
      }
    }
  }

  /// Get active Goals for my Growth stream
  Stream<List<GoalModel>> getMyGrowthGoalsStream() {
    return getGoalsStream(PillarType.myGrowth);
  }

  /// Get active Goals for Together stream
  Stream<List<GoalModel>> getTogetherGoalsStream(String partnerId) {
    if (_currentUserId.isEmpty || partnerId.isEmpty) {
      return getGoalsStream(PillarType.together);
    }

    // Merge streams logic for 'Together' goals
    final myGoalsStream =
        _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('goals')
            .where('pillar', isEqualTo: PillarType.together.name)
            .where('status', isEqualTo: GoalStatus.active.name)
            .snapshots()
            .map(
              (snapshot) =>
                  snapshot.docs
                      .map(
                        (doc) => GoalModel.fromMap(
                          doc.id,
                          doc.data(),
                          ownerId: _currentUserId,
                        ),
                      )
                      .toList(),
            )
            .asBroadcastStream();

    final partnerGoalsStream =
        _firestore
            .collection('users')
            .doc(partnerId)
            .collection('goals')
            .where('pillar', isEqualTo: PillarType.together.name)
            .where('status', isEqualTo: GoalStatus.active.name)
            .snapshots()
            .map(
              (snapshot) =>
                  snapshot.docs
                      .map(
                        (doc) => GoalModel.fromMap(
                          doc.id,
                          doc.data(),
                          ownerId: partnerId,
                        ),
                      )
                      .toList(),
            )
            .asBroadcastStream();

    return Rx.combineLatest2(myGoalsStream, partnerGoalsStream, (
      List<GoalModel> my,
      List<GoalModel> partner,
    ) {
      final merged = [...my, ...partner];
      merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return merged;
    }).asBroadcastStream();
  }

  /// Get active Goals for For Us stream
  Stream<List<GoalModel>> getForUsGoalsStream() {
    return getGoalsStream(PillarType.forUs);
  }

  Stream<List<GoalModel>> getGoalsStream(PillarType pillar) {
    if (_currentUserId.isEmpty) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('goals')
        .where('pillar', isEqualTo: pillar.name)
        .where('status', isEqualTo: GoalStatus.active.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => GoalModel.fromMap(
                      doc.id,
                      doc.data(),
                      ownerId: _currentUserId,
                    ),
                  )
                  .toList(),
        );
  }

  /// Get Archived Goals Stream for a specific Pillar
  Stream<List<GoalModel>> getArchivedGoalsStream(PillarType pillar) {
    if (_currentUserId.isEmpty) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('goals')
        .where('pillar', isEqualTo: pillar.name)
        .where('status', isEqualTo: GoalStatus.archived.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => GoalModel.fromMap(
                      doc.id,
                      doc.data(),
                      ownerId: _currentUserId,
                    ),
                  )
                  .toList(),
        );
  }

  /// Create a Task for a Goal
  Future<void> createTask(String ownerId, GoalTaskModel task) async {
    if (ownerId.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(ownerId)
        .collection('tasks')
        .add(task.toMap());
  }

  /// Get Tasks for a specific Goal
  Stream<List<GoalTaskModel>> getTasksByGoalId(
    String ownerId,
    String goalId, {
    bool includeArchived = false,
  }) {
    if (ownerId.isEmpty) return Stream.value([]);
    var query = _firestore
        .collection('users')
        .doc(ownerId)
        .collection('tasks')
        .where('goalId', isEqualTo: goalId);

    if (!includeArchived) {
      query = query.where('isArchived', isEqualTo: false);
    }

    return query.snapshots().map((snapshot) {
      final tasks =
          snapshot.docs
              .map((doc) => GoalTaskModel.fromMap(doc.id, doc.data()))
              .toList();
      // Xắp xếp tại Dart để tránh lỗi index kép của Firebase
      tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return tasks;
    });
  }

  /// Complete a Task (and trigger Reflection)
  Future<void> completeTask(
    String ownerId,
    String taskId,
    ReflectionMood mood,
    String? note,
  ) async {
    if (ownerId.isEmpty) return;

    // Create Reflection log
    final log = TaskLogModel(
      id: '',
      taskId: taskId,
      completedAt: DateTime.now(),
      reflectionMood: mood,
      reflectionText: note,
    );

    await _firestore
        .collection('users')
        .doc(ownerId)
        .collection('task_logs')
        .add(log.toMap());

    // Update Task status
    final taskDoc =
        await _firestore
            .collection('users')
            .doc(ownerId)
            .collection('tasks')
            .doc(taskId)
            .get();

    if (taskDoc.exists) {
      final task = GoalTaskModel.fromMap(taskDoc.id, taskDoc.data()!);
      if (task.type == TaskType.oneTime) {
        await taskDoc.reference.update({'isCompleted': true});
      } else {
        // Repeating tasks: increase streak, but keep it incomplete or setup logic for resetting next day
        // For now: mark completed, increase streak
        await taskDoc.reference.update({
          'isCompleted': true,
          'streak': FieldValue.increment(1),
        });
      }

      // Check if it's a together goal to notify partner
      final goalDoc = await _firestore
          .collection('users')
          .doc(ownerId)
          .collection('goals')
          .doc(task.goalId)
          .get();
      if (goalDoc.exists) {
        final goal = GoalModel.fromMap(goalDoc.id, goalDoc.data()!);
        if (goal.pillar == PillarType.together || goal.visibility == 'both') {
          final myDoc = await _firestore.collection('users').doc(_currentUserId).get();
          final partnerId = myDoc.data()?['partnerId'] as String?;
          if (partnerId != null && partnerId.isNotEmpty) {
            await _notificationService.sendNotification(
              targetUserId: partnerId,
              type: NotificationType.goalUpdated,
              content: 'Đã hoàn thành công việc "${task.title}" trong mục tiêu "${goal.title}"',
            );
          }
        }
      }
    }
  }

  /// Undo Task Completion
  Future<void> undoCompleteTask(String ownerId, String taskId) async {
    if (ownerId.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(ownerId)
        .collection('tasks')
        .doc(taskId)
        .update({'isCompleted': false});
  }

  /// Delete a Task
  Future<void> deleteTask(String ownerId, String taskId) async {
    if (ownerId.isEmpty) return;

    // First remove task logs
    final logsSnapshot =
        await _firestore
            .collection('users')
            .doc(ownerId)
            .collection('task_logs')
            .where('taskId', isEqualTo: taskId)
            .get();

    WriteBatch batch = _firestore.batch();
    for (var logDoc in logsSnapshot.docs) {
      batch.delete(logDoc.reference);
    }

    // Fetch task before deleting to get goal context
    final taskDoc = await _firestore
        .collection('users')
        .doc(ownerId)
        .collection('tasks')
        .doc(taskId)
        .get();

    String? goalId;
    String? taskTitle;
    if (taskDoc.exists) {
      final task = GoalTaskModel.fromMap(taskDoc.id, taskDoc.data()!);
      goalId = task.goalId;
      taskTitle = task.title;
    }

    final taskRef = _firestore
        .collection('users')
        .doc(ownerId)
        .collection('tasks')
        .doc(taskId);
    batch.delete(taskRef);

    await batch.commit();

    // Check if it's a together goal to notify partner after deletion
    if (goalId != null && taskTitle != null) {
      final goalDoc = await _firestore
          .collection('users')
          .doc(ownerId)
          .collection('goals')
          .doc(goalId)
          .get();
      if (goalDoc.exists) {
        final goal = GoalModel.fromMap(goalDoc.id, goalDoc.data()!);
        if (goal.pillar == PillarType.together || goal.visibility == 'both') {
          final myDoc =
              await _firestore.collection('users').doc(_currentUserId).get();
          final partnerId = myDoc.data()?['partnerId'] as String?;
          if (partnerId != null && partnerId.isNotEmpty) {
            await _notificationService.sendNotification(
              targetUserId: partnerId,
              type: NotificationType.goalUpdated,
              content: 'Đã xóa công việc "$taskTitle" khỏi mục tiêu "${goal.title}"',
            );
          }
        }
      }
    }
  }

  /// Archive a Task
  Future<void> archiveTask(String ownerId, String taskId) async {
    if (ownerId.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(ownerId)
        .collection('tasks')
        .doc(taskId)
        .update({'isArchived': true});
  }

  /// Update a Task title
  Future<void> updateTaskTitle(
    String ownerId,
    String taskId,
    String newTitle,
  ) async {
    if (ownerId.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(ownerId)
        .collection('tasks')
        .doc(taskId)
        .update({'title': newTitle});
  }

  /// Thay đổi trạng thái hoàn thành của Goal cho chế độ Cả Hai
  Future<void> toggleGoalCompletionStatus(String ownerId, String goalId, String userId, bool isDone) async {
    if (_currentUserId.isEmpty) return;
    
    final docRef = _firestore
        .collection('users')
        .doc(ownerId)
        .collection('goals')
        .doc(goalId);

    if (isDone) {
      await docRef.update({
        'completedBy': FieldValue.arrayUnion([userId])
      });
    } else {
      await docRef.update({
        'completedBy': FieldValue.arrayRemove([userId])
      });
    }
  }

  /// Chấp nhận một lời mời goal Together (từ partner / ownerId)
  Future<void> acceptGoal(String ownerId, String goalId) async {
    if (_currentUserId.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(ownerId)
        .collection('goals')
        .doc(goalId)
        .update({'partnerStatus': 'active'});
  }

  /// Từ chối một lời mời goal Together (từ partner / ownerId)
  Future<void> declineGoal(String ownerId, String goalId) async {
    if (_currentUserId.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(ownerId)
        .collection('goals')
        .doc(goalId)
        .update({'partnerStatus': 'declined'});
  }
}
