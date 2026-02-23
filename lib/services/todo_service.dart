import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import '../models/todo_model.dart';

class TodoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUserId => _auth.currentUser?.uid ?? '';

  /// Log hành động cho Todo List (sử dụng sau này cho AI)
  Future<void> logTodoAction(
    String ownerId,
    String todoId,
    String action, {
    String? taskName,
    Map<String, dynamic>? extraData,
  }) async {
    if (_currentUserId.isEmpty) return;
    try {
      await _firestore
          .collection('users')
          .doc(ownerId)
          .collection('todoHistory')
          .add({
            'todoId': todoId,
            'action': action,
            'actorId': _currentUserId,
            'taskName': taskName,
            'extraData': extraData ?? {},
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Lỗi khi ghi todoHistory: $e');
    }
  }

  /// Thêm Todo mới
  Future<void> addTodo({
    required String task,
    required TodoCategory category,
    TodoAssignee assignedTo = TodoAssignee.me,
    bool isShared = false,
    bool aiSuggested = false,
    TodoStatus status = TodoStatus.notStarted,
  }) async {
    if (_currentUserId.isEmpty) return;

    final newTodo = TodoModel(
      id: '', // Firestore sẽ tự tạo ID
      task: task,
      category: category,
      assignedTo: assignedTo,
      isShared: isShared,
      aiSuggested: aiSuggested,
      status: status,
      creatorId: _currentUserId,
    );

    final docRef = await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('todos')
        .add(newTodo.toMap());

    await logTodoAction(_currentUserId, docRef.id, 'created', taskName: task);
  }

  /// Đánh dấu là đã xem
  Future<void> markTodoAsViewed(String ownerId, String todoId) async {
    if (_currentUserId.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(ownerId)
        .collection('todos')
        .doc(todoId)
        .update({'viewedBy.$_currentUserId': FieldValue.serverTimestamp()});
  }

  /// Cập nhật Status Cho Together/For Us với logic Option B (5-step flow)
  Future<void> updateTodoStatusAdvanced(
    String ownerId,
    String todoId,
    TodoStatus newStatus,
    TodoModel currentTodo,
  ) async {
    if (_currentUserId.isEmpty) return;

    final docRef = _firestore
        .collection('users')
        .doc(ownerId)
        .collection('todos')
        .doc(todoId);

    // Sync isArchived boolean
    bool isArchived = newStatus == TodoStatus.archived;

    // Logic for Task Both (Cả 2)
    if (newStatus == TodoStatus.waitingPartner &&
        currentTodo.assignedTo == TodoAssignee.both) {
      if (!currentTodo.completedBy.contains(_currentUserId)) {
        await docRef.update({
          'status': newStatus.name,
          'completedBy': FieldValue.arrayUnion([_currentUserId]),
          'isArchived': isArchived,
        });
        await addSystemComment(
          ownerId,
          todoId,
          'đã hoàn thành phần việc của mình. Đang chờ đối phương xác nhận!',
        );
      }
    } else if (newStatus == TodoStatus.completed &&
        currentTodo.assignedTo == TodoAssignee.both) {
      if (!currentTodo.completedBy.contains(_currentUserId)) {
        List<String> updatedCompletedBy = List.from(currentTodo.completedBy);
        updatedCompletedBy.add(_currentUserId);

        bool bothCompleted = updatedCompletedBy.length >= 2;

        if (bothCompleted) {
          await docRef.update({
            'status': TodoStatus.completed.name,
            'completedBy': FieldValue.arrayUnion([_currentUserId]),
            'done': true,
            'isArchived': isArchived,
          });
          await addSystemComment(
            ownerId,
            todoId,
            '🎉 Cả hai đã hoàn thành công việc!',
          );
        } else {
          // Fallback if somehow it tries to complete without the other person
          await docRef.update({
            'status': TodoStatus.waitingPartner.name,
            'completedBy': FieldValue.arrayUnion([_currentUserId]),
            'isArchived': isArchived,
          });
          await addSystemComment(
            ownerId,
            todoId,
            'đã hoàn thành phần việc của mình.',
          );
        }
      }
    } else {
      // Normal flow
      await docRef.update({
        'status': newStatus.name,
        'isArchived': isArchived,
        if (newStatus == TodoStatus.inProgress ||
            newStatus == TodoStatus.notStarted)
          'completedBy': [],
        if (newStatus == TodoStatus.inProgress ||
            newStatus == TodoStatus.notStarted)
          'done': false,
        if (newStatus == TodoStatus.completed &&
            currentTodo.assignedTo != TodoAssignee.both)
          'done': true,
      });

      String statusText = '';
      if (newStatus == TodoStatus.inProgress) {
        statusText = 'đang bắt đầu làm việc này.';
      }
      if (newStatus == TodoStatus.completed &&
          currentTodo.assignedTo != TodoAssignee.both) {
        statusText = 'đã hoàn thành công việc.';
      }
      if (newStatus == TodoStatus.archived) {
        statusText = 'đã lưu trữ công việc này.';
      }

      if (statusText.isNotEmpty) {
        await addSystemComment(ownerId, todoId, statusText);
      }
    }

    // Log history
    String logAction =
        isArchived
            ? 'archived'
            : (newStatus == TodoStatus.completed
                ? 'completed'
                : 'status_changed');
    await logTodoAction(
      ownerId,
      todoId,
      logAction,
      taskName: currentTodo.task,
      extraData: {'status': newStatus.name},
    );
  }

  /// Toggle Reaction
  Future<void> toggleReaction(
    String ownerId,
    String todoId,
    String emoji,
  ) async {
    if (_currentUserId.isEmpty) return;

    final docRef = _firestore
        .collection('users')
        .doc(ownerId)
        .collection('todos')
        .doc(todoId);

    final doc = await docRef.get();
    if (!doc.exists) return;

    final reactions = doc.data()?['reactions'];
    String? currentReaction;
    if (reactions is Map) {
      currentReaction = reactions[_currentUserId];
    }

    if (currentReaction == emoji) {
      // Remove reaction
      await docRef.update({'reactions.$_currentUserId': FieldValue.delete()});
    } else {
      // Add reaction using set with merge to avoid errors if map doesn't exist
      await docRef.set({
        'reactions': {_currentUserId: emoji},
      }, SetOptions(merge: true));

      // Update partnerReaction for backward compatibility
      if (ownerId != _currentUserId) {
        await docRef.update({'partnerReaction': emoji});
      }

      // Add system comment for the reaction
      await addSystemComment(
        ownerId,
        todoId,
        'đã thả cảm xúc $emoji vào công việc này.',
      );
    }
  }

  /// Add Comment
  Future<void> addComment(String ownerId, String todoId, String text) async {
    if (_currentUserId.isEmpty) return;

    await _firestore
        .collection('users')
        .doc(ownerId)
        .collection('todos')
        .doc(todoId)
        .collection('comments')
        .add({
          'text': text,
          'senderId': _currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
          'isSystemMessage': false,
        });
  }

  /// Add System Comment
  Future<void> addSystemComment(
    String ownerId,
    String todoId,
    String text,
  ) async {
    await _firestore
        .collection('users')
        .doc(ownerId)
        .collection('todos')
        .doc(todoId)
        .collection('comments')
        .add({
          'text': text,
          'senderId': _currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
          'isSystemMessage': true,
        });
  }

  /// Get Comments Stream
  Stream<QuerySnapshot> getCommentsStream(String ownerId, String todoId) {
    return _firestore
        .collection('users')
        .doc(ownerId)
        .collection('todos')
        .doc(todoId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Cập nhật trạng thái Checkbox cho My Growth
  Future<void> toggleTodoDone(String uid, String todoId, bool isDone) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('todos')
        .doc(todoId)
        .update({
          'done': isDone,
          'status':
              isDone ? TodoStatus.completed.name : TodoStatus.inProgress.name,
        });

    await logTodoAction(
      uid,
      todoId,
      isDone ? 'completed' : 'uncompleted',
      extraData: {'done': isDone},
    );
  }

  /// Cập nhật Status cho Together / For Us (Not started, In progress...)
  Future<void> updateTodoStatus(
    String uid,
    String todoId,
    TodoStatus status,
  ) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('todos')
        .doc(todoId)
        .update({'status': status.name});

    await logTodoAction(
      uid,
      todoId,
      'status_changed',
      extraData: {'status': status.name},
    );
  }

  /// Gửi Reaction thả tim / comment cho Task của Partner
  Future<void> reactToTodo(
    String partnerId,
    String todoId,
    String reaction,
  ) async {
    await _firestore
        .collection('users')
        .doc(partnerId)
        .collection('todos')
        .doc(todoId)
        .update({'partnerReaction': reaction});
  }

  /// Sửa tên công việc
  Future<void> updateTodoTask(
    String ownerId,
    String todoId,
    String newTask,
  ) async {
    if (_currentUserId.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(ownerId)
        .collection('todos')
        .doc(todoId)
        .update({'task': newTask});

    await logTodoAction(ownerId, todoId, 'edited', taskName: newTask);
  }

  /// Xóa (vào thùng rác)
  Future<void> deleteTodo(String ownerId, String todoId) async {
    if (_currentUserId.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(ownerId)
        .collection('todos')
        .doc(todoId)
        .update({'deletedAt': FieldValue.serverTimestamp()});

    await logTodoAction(ownerId, todoId, 'deleted');
  }

  /// Stream Lấy danh sách nhiệm vụ của MỘT người (Dùng cho chế độ Single)
  Stream<List<TodoModel>> getMyTodosStream() {
    if (_currentUserId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('todos')
        .where('isArchived', isEqualTo: false)
        .where('deletedAt', isNull: true)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => TodoModel.fromMap(doc.id, doc.data()))
                  .toList(),
        );
  }

  /// Trả về 3 streams kết hợp của 2 người (Dùng cho chế độ Couple)
  /// Tránh lỗi Require Index của Firebase bằng cách gộp ở Client
  Stream<List<TodoModel>> getCoupleTodosStream(String partnerId) {
    if (_currentUserId.isEmpty || partnerId.isEmpty) {
      return getMyTodosStream();
    }

    final myTodosStream = _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('todos')
        .where('isArchived', isEqualTo: false)
        .where('deletedAt', isNull: true)
        .snapshots()
        .map(
          (shot) =>
              shot.docs.map((d) => TodoModel.fromMap(d.id, d.data())).toList(),
        );

    final partnerTodosStream = _firestore
        .collection('users')
        .doc(partnerId)
        .collection('todos')
        .where('isArchived', isEqualTo: false)
        .where('deletedAt', isNull: true)
        .snapshots()
        .map(
          (shot) =>
              shot.docs.map((d) => TodoModel.fromMap(d.id, d.data())).toList(),
        );

    // Merge 2 lists lại và sort
    return Rx.combineLatest2(myTodosStream, partnerTodosStream, (
      List<TodoModel> my,
      List<TodoModel> partner,
    ) {
      final merged = [...my, ...partner];
      // Sort newest first
      merged.sort((a, b) {
        final timeA = a.timestamp?.toDate() ?? DateTime.now();
        final timeB = b.timestamp?.toDate() ?? DateTime.now();
        return timeB.compareTo(timeA);
      });
      return merged;
    });
  }
}
