import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import '../models/todo_model.dart';

class TodoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUserId => _auth.currentUser?.uid ?? '';

  /// Thêm Todo mới
  Future<void> addTodo({
    required String task,
    required TodoCategory category,
    TodoAssignee assignedTo = TodoAssignee.me,
    bool isShared = false,
    bool aiSuggested = false,
  }) async {
    if (_currentUserId.isEmpty) return;

    final newTodo = TodoModel(
      id: '', // Firestore sẽ tự tạo ID
      task: task,
      category: category,
      assignedTo: assignedTo,
      isShared: isShared,
      aiSuggested: aiSuggested,
      creatorId: _currentUserId,
    );

    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('todos')
        .add(newTodo.toMap());
  }

  /// Cập nhật trạng thái Checkbox cho My Growth
  Future<void> toggleTodoDone(String uid, String todoId, bool isDone) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('todos')
        .doc(todoId)
        .update({'done': isDone});
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

  /// Xóa (vào thùng rác)
  Future<void> deleteTodo(String uid, String todoId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('todos')
        .doc(todoId)
        .update({'deletedAt': FieldValue.serverTimestamp()});
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
