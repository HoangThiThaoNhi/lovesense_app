import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/todo_model.dart';
import 'add_edit_todo_dialog.dart';
import '../../screens/home/todo_history_screen.dart';

class TodoListWidget extends StatefulWidget {
  const TodoListWidget({super.key});

  @override
  State<TodoListWidget> createState() => _TodoListWidgetState();
}

class _TodoListWidgetState extends State<TodoListWidget> {
  bool _isAdding = false;
  final TextEditingController _addController = TextEditingController();

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Danh sách việc cần làm',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    // Navigate to History
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const TodoHistoryScreen()),
                    );
                  },
                  icon: const Icon(Icons.history, color: Colors.grey),
                  tooltip: 'Lịch sử công việc',
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isAdding = !_isAdding;
                    });
                  },
                  icon: Icon(
                    _isAdding ? Icons.close : Icons.add_circle,
                    color: _isAdding ? Colors.red : const Color(0xFF6200EA),
                    size: 28,
                  ),
                  tooltip: _isAdding ? 'Hủy' : 'Thêm nhiệm vụ mới',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Inline Add Input
         AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: _isAdding ? _buildInlineAddInput(uid) : const SizedBox.shrink(),
        ),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('todos')
              .where('isArchived', isEqualTo: false) // Active tasks
              .where('deletedAt', isNull: true) // Not deleted
              .orderBy('timestamp', descending: true) // Newest first
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              // Error often contains a link to create an index
              return Container(
                padding: const EdgeInsets.all(16),
                color: Colors.red[50],
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(height: 8),
                    SelectableText(
                      'Lỗi tải danh sách: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty && !_isAdding) {
              return _buildEmptyState();
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final todo = TodoModel.fromMap(docs[index].id, data);
                return _buildTodoItem(context, uid, todo);
              },
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildInlineAddInput(String uid) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.purple.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _addController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Nhập tên công việc...',
              hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: GoogleFonts.inter(fontSize: 16),
            onSubmitted: (_) => _saveNewTask(uid),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isAdding = false;
                    _addController.clear();
                  });
                },
                child: Text(
                  'Hủy',
                  style: GoogleFonts.inter(color: Colors.grey),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _saveNewTask(uid),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6200EA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(
                  'Thêm',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveNewTask(String uid) async {
    final text = _addController.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('todos')
        .add({
      'task': text,
      'done': false,
      'priority': 1,
      'isArchived': false,
      'deletedAt': null, // Explicitly null for query filter
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      setState(() {
        _isAdding = false;
        _addController.clear();
      });
    }
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_turned_in_outlined,
              size: 48, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text(
            "Tuyệt vời! Bạn đã hoàn thành hết công việc.\nThêm việc mới hoặc thư giãn nhé!",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoItem(BuildContext context, String uid, TodoModel todo) {
    return Dismissible(
      key: Key(todo.id),
      // 1. Swipe Right -> ARCHIVE (Orange)
      background: Container(
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.orangeAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            const Icon(Icons.archive_outlined, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              "Lưu trữ",
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      // 2. Swipe Left -> DELETE (Red)
      secondaryBackground: Container(
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "Xóa",
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.delete_outline, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe Left -> DELETE -> CONFIRM
          return await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Xác nhận xóa"),
              content:
                  const Text("Bạn có chắc chắn muốn xóa nhiệm vụ này không?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text("Hủy"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text("Xóa", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        } else {
          // Swipe Right -> ARCHIVE -> AUTO
          return true;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          // Swipe Left -> DELETE
          // Swipe Left -> DELETE (Soft)
          FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('todos')
              .doc(todo.id)
              .update({'deletedAt': FieldValue.serverTimestamp()});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã chuyển vào thùng rác')),
          );
        } else {
          // Swipe Right -> ARCHIVE
          FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('todos')
              .doc(todo.id)
              .update({'isArchived': true});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã lưu trữ nhiệm vụ')),
          );
        }
      },
      child: GestureDetector(
        onTap: () => _showEditDialog(context, uid, todo),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: todo.done
                  ? Colors.green.withOpacity(0.3)
                  : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: () {
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('todos')
                      .doc(todo.id)
                      .update({'done': !todo.done});
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: todo.done ? Colors.green : Colors.transparent,
                    border: Border.all(
                      color: todo.done ? Colors.green : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: todo.done
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Text(
                  todo.task,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    decoration:
                        todo.done ? TextDecoration.lineThrough : null,
                    color: todo.done ? Colors.grey : Colors.black87,
                  ),
                ),
              ),
               // Options Menu (3 dots)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'archive') {
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('todos')
                        .doc(todo.id)
                        .update({'isArchived': true});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã lưu trữ nhiệm vụ')),
                    );
                  } else if (value == 'delete') {
                     showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Xác nhận xóa"),
                          content: const Text("Bạn có chắc chắn muốn xóa nhiệm vụ này không?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text("Hủy"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .collection('todos')
                                  .doc(todo.id)
                                  .update({'deletedAt': FieldValue.serverTimestamp()}); // Soft Delete
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đã chuyển vào thùng rác')),
                                );
                              },
                              child: const Text("Xóa", style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(Icons.archive_outlined, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text('Lưu trữ'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Xóa', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _showEditDialog(BuildContext context, String uid, TodoModel todo) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddEditTodoDialog(
        initialTask: todo.task,
        isEdit: true,
      ),
    );

    if (result != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('todos')
          .doc(todo.id)
          .update({
        'task': result['task'],
      });
    }
  }
}
