import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/todo_model.dart';
import '../../../models/user_model.dart';
import '../../../services/todo_service.dart';
import 'todo_detail_bottom_sheet.dart';

class CoupleTodoCard extends StatefulWidget {
  final TodoModel todo;
  final UserModel currentUser;

  const CoupleTodoCard({
    super.key,
    required this.todo,
    required this.currentUser,
  });

  @override
  State<CoupleTodoCard> createState() => _CoupleTodoCardState();
}

class _CoupleTodoCardState extends State<CoupleTodoCard> {
  final TodoService _todoService = TodoService();

  @override
  Widget build(BuildContext context) {
    final todo = widget.todo;
    final bool isCompletedByMe =
        todo.completedBy.contains(widget.currentUser.uid) || todo.done;
    final bool isFullyDone = todo.done;

    Color bgColor = isFullyDone ? Colors.grey[50]! : Colors.white;
    Color borderColor =
        isFullyDone ? Colors.green.withOpacity(0.3) : Colors.grey[200]!;

    if (todo.category == TodoCategory.forUs && !isFullyDone) {
      bgColor =
          todo.aiSuggested ? const Color(0xFFF3E5F5) : const Color(0xFFFFF0F5);
      borderColor = todo.aiSuggested ? Colors.purple[100]! : Colors.pink[100]!;
    }

    return GestureDetector(
      onTap: () => _showTaskDetailBottomSheet(context, todo),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(left: 16, right: 8, top: 12, bottom: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow:
              isFullyDone
                  ? []
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Checkbox
            GestureDetector(
              onTap: () {
                _handleCompleteTask(todo, isCompletedByMe);
                if (!isCompletedByMe &&
                    todo.category == TodoCategory.personal) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Bạn đang phát triển vì chính mình 🌿",
                        style: GoogleFonts.inter(),
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.green[600],
                    ),
                  );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompletedByMe ? Colors.green : Colors.transparent,
                  border: Border.all(
                    color: isCompletedByMe ? Colors.green : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child:
                    isCompletedByMe
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
              ),
            ),
            const SizedBox(width: 16),
            // Middle Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [_buildTaskSpecificContent(todo, isFullyDone)],
              ),
            ),
            // Three dot menu
            _buildPopupMenu(todo),
          ],
        ),
      ),
    );
  }

  void _handleCompleteTask(TodoModel todo, bool isCompletedByMe) {
    if (todo.category == TodoCategory.personal) {
      _todoService.toggleTodoDone(todo.creatorId, todo.id, !todo.done);
    } else {
      if (todo.assignedTo == TodoAssignee.both) {
        _todoService.updateTodoStatusAdvanced(
          todo.creatorId,
          todo.id,
          isCompletedByMe
              ? (todo.status == TodoStatus.completed
                  ? TodoStatus.inProgress
                  : TodoStatus.waitingPartner)
              : TodoStatus.completed,
          todo,
        );
      } else {
        _todoService.updateTodoStatusAdvanced(
          todo.creatorId,
          todo.id,
          !todo.done ? TodoStatus.completed : TodoStatus.inProgress,
          todo,
        );
      }
    }
  }

  Widget _buildPopupMenu(TodoModel todo) {
    final bool canEdit = todo.creatorId == widget.currentUser.uid;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'complete') {
          _todoService.updateTodoStatusAdvanced(
            todo.creatorId,
            todo.id,
            TodoStatus.completed,
            todo,
          );
        }
        if (value == 'edit') _showEditDialogForTodo(todo);
        if (value == 'archive') {
          _todoService.updateTodoStatusAdvanced(
            todo.creatorId,
            todo.id,
            TodoStatus.archived,
            todo,
          );
        }
        if (value == 'delete') _showDeleteDialogForTodo(todo);
      },
      itemBuilder:
          (context) => [
            if (todo.status != TodoStatus.completed)
              PopupMenuItem(
                value: 'complete',
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
                    const SizedBox(width: 8),
                    Text("Hoàn thành", style: GoogleFonts.inter()),
                  ],
                ),
              ),
            if (canEdit)
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text("Sửa", style: GoogleFonts.inter()),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'archive',
              child: Row(
                children: [
                  const Icon(
                    Icons.archive_outlined,
                    size: 20,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text("Lưu trữ", style: GoogleFonts.inter()),
                ],
              ),
            ),
            if (canEdit)
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text("Xóa", style: GoogleFonts.inter()),
                  ],
                ),
              ),
          ],
    );
  }

  void _showTaskDetailBottomSheet(BuildContext context, TodoModel todo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => TodoDetailBottomSheet(
            todo: todo,
            currentUser: widget.currentUser,
            partner: null,
            ownerId: todo.creatorId,
          ),
    );
  }

  Widget _buildTaskSpecificContent(TodoModel todo, bool isFullyDone) {
    if (todo.category == TodoCategory.personal) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedOpacity(
            opacity: isFullyDone ? 0.5 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Text(
              todo.task,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                decoration: isFullyDone ? TextDecoration.lineThrough : null,
                color: isFullyDone ? Colors.grey[600] : Colors.black87,
              ),
            ),
          ),
          if (todo.isShared || todo.partnerReaction != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (todo.isShared) ...[
                  Icon(Icons.visibility, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    "Shared",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
                if (todo.partnerReaction != null) ...[
                  if (todo.isShared) const SizedBox(width: 12),
                  Text(
                    todo.reactions.values.isNotEmpty
                        ? todo.reactions.values.first
                        : (todo.partnerReaction ?? ''),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ],
            ),
          ],
        ],
      );
    } else if (todo.category == TodoCategory.together) {
      Color statusColor;
      String statusText;
      switch (todo.status) {
        case TodoStatus.notStarted:
          statusColor = Colors.grey[600]!;
          statusText = "Not started";
          break;
        case TodoStatus.inProgress:
          statusColor = Colors.blue[600]!;
          statusText = "In progress";
          break;
        case TodoStatus.waitingPartner:
          statusColor = Colors.orange[600]!;
          statusText = "Waiting for partner";
          break;
        case TodoStatus.completed:
          statusColor = Colors.green[600]!;
          statusText = "Completed";
          break;
        case TodoStatus.archived:
          statusColor = Colors.grey[400]!;
          statusText = "Archived";
          break;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  todo.task,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: isFullyDone ? TextDecoration.lineThrough : null,
                    color: isFullyDone ? Colors.grey[600] : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (todo.assignedTo == TodoAssignee.me)
                CircleAvatar(
                  radius: 12,
                  backgroundImage:
                      widget.currentUser.photoUrl != null
                          ? NetworkImage(widget.currentUser.photoUrl!)
                          : null,
                  backgroundColor: Colors.purple[100],
                )
              else if (todo.assignedTo == TodoAssignee.partner)
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.pink[100],
                  child: const Icon(
                    Icons.favorite,
                    size: 12,
                    color: Colors.pink,
                  ),
                )
              else if (todo.assignedTo == TodoAssignee.both)
                SizedBox(
                  width: 40,
                  height: 24,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundImage:
                              widget.currentUser.photoUrl != null
                                  ? NetworkImage(widget.currentUser.photoUrl!)
                                  : null,
                          backgroundColor: Colors.purple[100],
                        ),
                      ),
                      Positioned(
                        left: 16,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.pink[100],
                          child: const Icon(
                            Icons.favorite,
                            size: 12,
                            color: Colors.pink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      );
    } else {
      // For Us
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                todo.aiSuggested ? Icons.eco_rounded : Icons.favorite_rounded,
                size: 16,
                color: todo.aiSuggested ? Colors.green[600] : Colors.pink[400],
              ),
              const SizedBox(width: 6),
              Text(
                todo.aiSuggested
                    ? "Gợi ý từ AI Coach 🌱"
                    : "Một điều nhỏ hôm nay 💛",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      todo.aiSuggested ? Colors.green[800] : Colors.pink[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            todo.task,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              decoration: isFullyDone ? TextDecoration.lineThrough : null,
              color: isFullyDone ? Colors.grey[600] : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    todo.aiSuggested ? Colors.purple[400] : Colors.pink[400],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Gửi lời nhắn"),
            ),
          ),
        ],
      );
    }
  }

  void _showEditDialogForTodo(TodoModel todo) {
    final TextEditingController controller = TextEditingController(
      text: todo.task,
    );
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              "Sửa công việc",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "Nhập nội dung công việc...",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    _todoService.updateTodoTask(
                      todo.creatorId,
                      todo.id,
                      controller.text.trim(),
                    );
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Lưu"),
              ),
            ],
          ),
    );
  }

  void _showDeleteDialogForTodo(TodoModel todo) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              "Xóa công việc?",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: Text(
              "Bạn có chắc chắn muốn xóa công việc này không?",
              style: GoogleFonts.inter(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  _todoService.deleteTodo(todo.creatorId, todo.id);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Xóa"),
              ),
            ],
          ),
    );
  }
}
