import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/todo_model.dart';
import '../../../models/user_model.dart';
import '../../../models/todo_comment_model.dart';
import '../../../services/todo_service.dart';

class TodoDetailBottomSheet extends StatefulWidget {
  final TodoModel todo;
  final UserModel currentUser;
  final UserModel? partner;
  final String ownerId;

  const TodoDetailBottomSheet({
    super.key,
    required this.todo,
    required this.currentUser,
    this.partner,
    required this.ownerId,
  });

  @override
  State<TodoDetailBottomSheet> createState() => _TodoDetailBottomSheetState();
}

class _TodoDetailBottomSheetState extends State<TodoDetailBottomSheet> {
  final TodoService _todoService = TodoService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late TodoModel _currentTodo;

  @override
  void initState() {
    super.initState();
    _currentTodo = widget.todo;
    // Mark as viewed when opening
    _todoService.markTodoAsViewed(widget.ownerId, _currentTodo.id);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to real-time updates for the current todo to update state (likes, status, etc)
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(widget.ownerId)
              .collection('todos')
              .doc(_currentTodo.id)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          _currentTodo = TodoModel.fromMap(
            snapshot.data!.id,
            snapshot.data!.data() as Map<String, dynamic>,
          );
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _buildDragHandle(),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 16),
                            _buildTaskTitle(),
                            const SizedBox(height: 24),
                            _buildStatusToggle(),
                            const SizedBox(height: 24),
                            _buildReactionBar(),
                            const SizedBox(height: 24),
                            const Divider(),
                            Text(
                              "Thảo luận",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: _buildCommentsStream(),
                    ),
                  ],
                ),
              ),
              _buildCommentInput(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 16),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    bool partnerViewed = false;
    DateTime? partnerViewTime;

    if (widget.partner != null &&
        _currentTodo.viewedBy.containsKey(widget.partner!.uid)) {
      partnerViewed = true;
      partnerViewTime = _currentTodo.viewedBy[widget.partner!.uid]?.toDate();
    }

    // AI Tracking hint if not viewed for 3 days
    bool isOld = false;
    if (_currentTodo.timestamp != null) {
      final daysOld =
          DateTime.now().difference(_currentTodo.timestamp!.toDate()).inDays;
      if (daysOld >= 3 &&
          _currentTodo.status != TodoStatus.completed &&
          !partnerViewed) {
        isOld = true;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    _currentTodo.category == TodoCategory.personal
                        ? Colors.green[50]
                        : _currentTodo.category == TodoCategory.together
                        ? Colors.blue[50]
                        : Colors.pink[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _currentTodo.category == TodoCategory.personal
                    ? "Cá nhân"
                    : _currentTodo.category == TodoCategory.together
                    ? "Cùng nhau"
                    : "Tình yêu",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      _currentTodo.category == TodoCategory.personal
                          ? Colors.green[700]
                          : _currentTodo.category == TodoCategory.together
                          ? Colors.blue[700]
                          : Colors.pink[700],
                ),
              ),
            ),
            if (partnerViewed)
              Row(
                children: [
                  Icon(Icons.visibility, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  CircleAvatar(
                    radius: 8,
                    backgroundImage:
                        widget.partner?.photoUrl != null
                            ? NetworkImage(widget.partner!.photoUrl!)
                            : null,
                    backgroundColor: Colors.pink[100],
                    child:
                        widget.partner?.photoUrl == null
                            ? const Icon(
                              Icons.favorite,
                              size: 8,
                              color: Colors.pink,
                            )
                            : null,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    partnerViewTime != null
                        ? DateFormat('HH:mm').format(partnerViewTime)
                        : "Đã xem",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
          ],
        ),
        if (isOld) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: Colors.amber[800],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Hai bạn đã tạo việc này vài ngày trước, hãy nhắc nhở người ấy nhé!",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.amber[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTaskTitle() {
    final bool canEdit = _currentTodo.creatorId == widget.currentUser.uid;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            _currentTodo.task,
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        if (canEdit) ...[
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
            onPressed: () => _showEditDialog(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
            onPressed: () => _showDeleteDialog(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ],
    );
  }

  void _showEditDialog() {
    final TextEditingController controller = TextEditingController(
      text: _currentTodo.task,
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
                      widget.ownerId,
                      _currentTodo.id,
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

  void _showDeleteDialog() {
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
                  _todoService.deleteTodo(widget.ownerId, _currentTodo.id);
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close bottom sheet
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

  Widget _buildStatusToggle() {
    final bool isBoth = _currentTodo.assignedTo == TodoAssignee.both;
    final bool iCompleted = _currentTodo.completedBy.contains(
      widget.currentUser.uid,
    );
    final bool partnerCompleted =
        widget.partner != null &&
        _currentTodo.completedBy.contains(widget.partner!.uid);

    // Status visual mapping
    Color statusColor = Colors.grey[600]!;
    String statusText = "Chưa bắt đầu";
    IconData statusIcon = Icons.radio_button_unchecked;

    if (_currentTodo.status == TodoStatus.completed) {
      statusColor = Colors.green[600]!;
      statusText = "Đã hoàn thành";
      statusIcon = Icons.check_circle;
    } else if (_currentTodo.status == TodoStatus.waitingPartner) {
      statusColor = Colors.orange[600]!;
      statusText = "Chờ đối phương";
      statusIcon = Icons.hourglass_top;
    } else if (_currentTodo.status == TodoStatus.inProgress) {
      statusColor = Colors.blue[600]!;
      statusText = "Đang diễn ra";
      statusIcon = Icons.timelapse;
    } else if (_currentTodo.status == TodoStatus.archived) {
      statusColor = Colors.grey[400]!;
      statusText = "Đã lưu trữ";
      statusIcon = Icons.archive;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Trạng thái:",
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (_currentTodo.status != TodoStatus.archived)
                  IconButton(
                    icon: Icon(Icons.archive_outlined, color: Colors.grey[500]),
                    onPressed: () {
                      _todoService.updateTodoStatusAdvanced(
                        widget.ownerId,
                        _currentTodo.id,
                        TodoStatus.archived,
                        _currentTodo,
                      );
                    },
                    tooltip: "Lưu trữ",
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                <TodoStatus>[
                  TodoStatus.notStarted,
                  TodoStatus.inProgress,
                  if (_currentTodo.status == TodoStatus.waitingPartner)
                    TodoStatus.waitingPartner,
                  TodoStatus.completed,
                ].map<Widget>((status) {
                  String label = "Chưa làm";
                  Color color = Colors.grey;
                  if (status == TodoStatus.inProgress) {
                    label = "Đang làm";
                    color = Colors.blue;
                  } else if (status == TodoStatus.completed) {
                    label = "Hoàn thành";
                    color = Colors.green;
                  } else if (status == TodoStatus.waitingPartner) {
                    label = "Chờ đối phương";
                    color = Colors.orange;
                  }

                  final isSelected = _currentTodo.status == status;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      selectedColor: color.withOpacity(0.2),
                      onSelected: (val) {
                        if (!val ||
                            isSelected ||
                            status == TodoStatus.waitingPartner) {
                          return;
                        }
                        _todoService.updateTodoStatusAdvanced(
                          widget.ownerId,
                          _currentTodo.id,
                          status,
                          _currentTodo,
                        );
                      },
                    ),
                  );
                }).toList(),
          ),
        ),
        if (isBoth) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAssignedConfirmCard(
                  user: widget.currentUser,
                  isMe: true,
                  hasCompleted: iCompleted,
                  onTap: () {
                    // Cập nhật riêng phần mình
                    _todoService.updateTodoStatusAdvanced(
                      widget.ownerId,
                      _currentTodo.id,
                      iCompleted ? TodoStatus.inProgress : TodoStatus.completed,
                      _currentTodo,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAssignedConfirmCard(
                  user: widget.partner,
                  isMe: false,
                  hasCompleted: partnerCompleted,
                  onTap: () {},
                ),
              ),
            ],
          ),
          if (iCompleted && !partnerCompleted) ...[
            const SizedBox(height: 8),
            Text(
              "Đang chờ người ấy cùng xác nhận...",
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.orange[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildAssignedConfirmCard({
    required UserModel? user,
    required bool isMe,
    required bool hasCompleted,
    required VoidCallback onTap,
  }) {
    if (user == null) return const SizedBox();

    return GestureDetector(
      onTap: isMe ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: hasCompleted ? Colors.green[50] : Colors.grey[50],
          border: Border.all(
            color: hasCompleted ? Colors.green[300]! : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      user.photoUrl != null
                          ? NetworkImage(user.photoUrl!)
                          : null,
                  backgroundColor: isMe ? Colors.purple[100] : Colors.pink[100],
                  child:
                      user.photoUrl == null
                          ? Icon(
                            isMe ? Icons.person : Icons.favorite,
                            color: isMe ? Colors.purple : Colors.pink,
                          )
                          : null,
                ),
                if (hasCompleted)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isMe ? "Mình" : "Người ấy",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: hasCompleted ? Colors.green[800] : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionBar() {
    final emojis = ['❤️', '🔥', '👏', '😂', '🥺', '💪'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Cảm xúc:",
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                emojis.map((emoji) {
                  final isSelected =
                      _currentTodo.reactions[widget.currentUser.uid] == emoji;
                  return GestureDetector(
                    onTap: () {
                      _todoService.toggleReaction(
                        widget.ownerId,
                        _currentTodo.id,
                        emoji,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? Colors.deepPurple[50]
                                : Colors.grey[100],
                        border: Border.all(
                          color:
                              isSelected
                                  ? Colors.deepPurple[300]!
                                  : Colors.transparent,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: _todoService.getCommentsStream(widget.ownerId, _currentTodo.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 40,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Chưa có thảo luận nào",
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final comment = TodoCommentModel.fromMap(
              docs[index].id,
              docs[index].data() as Map<String, dynamic>,
            );
            return _buildCommentBubble(comment);
          }, childCount: docs.length),
        );
      },
    );
  }

  Widget _buildCommentBubble(TodoCommentModel comment) {
    final timeString =
        DateFormat(
              'HH:mm : dd/MM/yyyy',
            ).format(comment.timestamp!.toDate());

    if (comment.isSystemMessage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              "${comment.senderId == widget.currentUser.uid ? 'Bạn' : 'Người ấy'} ${comment.text} ${timeString.isNotEmpty ? '($timeString)' : ''}",
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    final isMe = comment.senderId == widget.currentUser.uid;
    final user = isMe ? widget.currentUser : widget.partner;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundImage:
                  user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
              backgroundColor: Colors.pink[100],
              child:
                  user?.photoUrl == null
                      ? const Icon(Icons.favorite, size: 14, color: Colors.pink)
                      : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.deepPurple : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    comment.text,
                    style: GoogleFonts.inter(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (timeString.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                    child: Text(
                      timeString,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: "Thêm bình luận...",
                hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _submitComment(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _submitComment,
            ),
          ),
        ],
      ),
    );
  }

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    _todoService.addComment(widget.ownerId, _currentTodo.id, text);
    _commentController.clear();
  }
}
