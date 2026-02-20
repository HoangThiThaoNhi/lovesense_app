import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/todo_service.dart';
import '../../models/todo_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CoupleTodoWidget extends StatefulWidget {
  final UserModel currentUser;

  const CoupleTodoWidget({super.key, required this.currentUser});

  @override
  State<CoupleTodoWidget> createState() => _CoupleTodoWidgetState();
}

class _CoupleTodoWidgetState extends State<CoupleTodoWidget> {
  final TodoService _todoService = TodoService();
  int _selectedTab = 0; // 0: My Growth, 1: Together, 2: For Us

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 60), // Space for FAB
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildSegmentControl(),
              const SizedBox(height: 16),
              _buildTaskList(),
            ],
          ).animate().fadeIn(delay: 200.ms),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: FloatingActionButton(
            heroTag: 'coupleTodoFab',
            mini: true,
            onPressed: () => _showAddTaskBottomSheet(context),
            backgroundColor: Colors.pink[400],
            elevation: 2,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[50]!, Colors.pink[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Avatars
          SizedBox(
            width: 60,
            height: 40,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage:
                          widget.currentUser.photoUrl != null &&
                                  widget.currentUser.photoUrl!.isNotEmpty
                              ? NetworkImage(widget.currentUser.photoUrl!)
                              : null,
                      child:
                          widget.currentUser.photoUrl == null ||
                                  widget.currentUser.photoUrl!.isEmpty
                              ? const Icon(
                                Icons.person,
                                size: 20,
                                color: Colors.grey,
                              )
                              : null,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: const CircleAvatar(
                      radius: 18,
                      child: Icon(Icons.favorite, size: 16, color: Colors.pink),
                    ), // Placeholder for Partner Avatar
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Phát triển cùng nhau mỗi ngày 🌱",
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "Cùng nhau hoàn thành mục tiêu nhé",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentControl() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTabButton(0, "My Growth", Icons.person_outline),
          _buildTabButton(1, "Together", Icons.people_outline),
          _buildTabButton(2, "For Us", Icons.favorite_outline),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.deepPurple : Colors.grey[500],
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                  color: isSelected ? Colors.deepPurple : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    return StreamBuilder<List<TodoModel>>(
      stream: _todoService.getCoupleTodosStream(
        widget.currentUser.partnerId ?? '',
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allTasks = snapshot.data ?? [];

        // Filter based on selected tab
        List<TodoModel> filteredTasks = [];
        if (_selectedTab == 0) {
          filteredTasks =
              allTasks
                  .where(
                    (t) =>
                        t.category == TodoCategory.personal &&
                        t.creatorId == widget.currentUser.uid,
                  )
                  .toList();
        } else if (_selectedTab == 1) {
          filteredTasks =
              allTasks
                  .where((t) => t.category == TodoCategory.together)
                  .toList();
        } else {
          filteredTasks =
              allTasks.where((t) => t.category == TodoCategory.forUs).toList();
        }

        if (filteredTasks.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    _selectedTab == 2
                        ? Icons.volunteer_activism_outlined
                        : Icons.assignment_outlined,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedTab == 0
                        ? "Bạn đã hoàn thành việc cá nhân!"
                        : _selectedTab == 1
                        ? "Chưa có danh sách việc chung nào."
                        : "Tạo một bất ngờ nhỏ cho người ấy nào 💛",
                    style: GoogleFonts.inter(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredTasks.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final todo = filteredTasks[index];
            return _buildTaskCard(todo);
          },
        );
      },
    );
  }

  Widget _buildTaskCard(TodoModel todo) {
    switch (todo.category) {
      case TodoCategory.personal:
        return _buildPersonalTaskCard(todo);
      case TodoCategory.together:
        return _buildTogetherTaskCard(todo);
      case TodoCategory.forUs:
        return _buildForUsTaskCard(todo);
    }
  }

  Widget _buildPersonalTaskCard(TodoModel todo) {
    final isMine = todo.creatorId == widget.currentUser.uid;
    // We only show personal tasks if they are mine, but if we later support partner's shared tasks, we handle it here.

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: todo.done ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: todo.done ? Colors.green.withOpacity(0.3) : Colors.grey[200]!,
        ),
        boxShadow:
            todo.done
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
        children: [
          GestureDetector(
            onTap: () {
              // Play animation or show toast here later
              _todoService.toggleTodoDone(
                widget.currentUser.uid,
                todo.id,
                !todo.done,
              );
              if (!todo.done) {
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
                color: todo.done ? Colors.green : Colors.transparent,
                border: Border.all(
                  color: todo.done ? Colors.green : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child:
                  todo.done
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedOpacity(
                  opacity: todo.done ? 0.5 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    todo.task,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      decoration: todo.done ? TextDecoration.lineThrough : null,
                      color: todo.done ? Colors.grey[600] : Colors.black87,
                    ),
                  ),
                ),
                if (todo.isShared || todo.partnerReaction != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (todo.isShared) ...[
                        Icon(
                          Icons.visibility,
                          size: 14,
                          color: Colors.grey[500],
                        ),
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
                          todo.partnerReaction!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTogetherTaskCard(TodoModel todo) {
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
      case TodoStatus.waiting:
        statusColor = Colors.orange[600]!;
        statusText = "Waiting for partner";
        break;
      case TodoStatus.completed:
        statusColor = Colors.green[600]!;
        statusText = "Completed";
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            todo.status == TodoStatus.completed
                ? Colors.green[50]
                : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  todo.task,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration:
                        todo.status == TodoStatus.completed
                            ? TextDecoration.lineThrough
                            : null,
                    color:
                        todo.status == TodoStatus.completed
                            ? Colors.grey[600]
                            : Colors.black87,
                  ),
                ),
              ),
              // Avatars mapped to assignee
              Row(
                children: [
                  if (todo.assignedTo == TodoAssignee.me ||
                      todo.assignedTo == TodoAssignee.both)
                    CircleAvatar(
                      radius: 12,
                      backgroundImage:
                          widget.currentUser.photoUrl != null
                              ? NetworkImage(widget.currentUser.photoUrl!)
                              : null,
                      backgroundColor: Colors.purple[100],
                    ),
                  if (todo.assignedTo == TodoAssignee.both)
                    const SizedBox(width: -8), // Overlap
                  if (todo.assignedTo == TodoAssignee.partner ||
                      todo.assignedTo == TodoAssignee.both)
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.pink[100],
                      child: const Icon(
                        Icons.favorite,
                        size: 12,
                        color: Colors.pink,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
              Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.add_reaction_outlined,
                    size: 18,
                    color: Colors.grey[500],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForUsTaskCard(TodoModel todo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            todo.aiSuggested
                ? const Color(0xFFF3E5F5)
                : const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: todo.aiSuggested ? Colors.purple[100]! : Colors.pink[100]!,
        ),
      ),
      child: Column(
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
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _todoService.toggleTodoDone(
                      widget.currentUser.uid,
                      todo.id,
                      !todo.done,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: todo.done ? Colors.green : Colors.black87,
                    side: BorderSide(
                      color: todo.done ? Colors.green : Colors.grey[300]!,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(todo.done ? "Đã làm" : "Đánh dấu hoàn thành"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        todo.aiSuggested
                            ? Colors.purple[400]
                            : Colors.pink[400],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Gửi lời nhắn"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddTaskBottomSheet(BuildContext context) {
    String taskContent = '';
    TodoCategory selectedCategory =
        TodoCategory.values[_selectedTab] == TodoCategory.forUs
            // fallback if necessary but typically handled by index mapping
            ? TodoCategory.forUs
            : TodoCategory.values[_selectedTab];
    TodoAssignee assignedTo = TodoAssignee.me;
    bool isShared = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Thêm việc cần làm",
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Selector
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          TodoCategory.values.map((cat) {
                            final isSelected = selectedCategory == cat;
                            String label = '';
                            IconData iconData = Icons.star;
                            Color iconColor = Colors.grey;
                            if (cat == TodoCategory.personal) {
                              label = "Cá nhân";
                              iconData = Icons.person;
                              iconColor = Colors.green;
                            } else if (cat == TodoCategory.together) {
                              label = "Cùng nhau";
                              iconData = Icons.people;
                              iconColor = Colors.blue;
                            } else {
                              label = "Tình yêu";
                              iconData = Icons.favorite;
                              iconColor = Colors.pink;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Row(
                                  children: [
                                    Icon(
                                      iconData,
                                      size: 14,
                                      color:
                                          isSelected ? Colors.white : iconColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(label),
                                  ],
                                ),
                                selected: isSelected,
                                selectedColor: iconColor,
                                labelStyle: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                ),
                                onSelected: (val) {
                                  setModalState(() {
                                    selectedCategory = cat;
                                    if (cat == TodoCategory.personal)
                                      assignedTo = TodoAssignee.me;
                                    if (cat == TodoCategory.forUs)
                                      assignedTo = TodoAssignee.both;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Assignee Selector (Only for Together)
                  if (selectedCategory == TodoCategory.together) ...[
                    Text(
                      "Ai sẽ làm?",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children:
                          TodoAssignee.values.map((assignee) {
                            String label =
                                assignee == TodoAssignee.me
                                    ? "Mình"
                                    : assignee == TodoAssignee.partner
                                    ? "Người ấy"
                                    : "Cả hai";
                            return ChoiceChip(
                              label: Text(label),
                              selected: assignedTo == assignee,
                              onSelected:
                                  (val) => setModalState(
                                    () => assignedTo = assignee,
                                  ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Share toggle (Only for Personal)
                  if (selectedCategory == TodoCategory.personal) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Chia sẻ tiến độ với người ấy",
                          style: GoogleFonts.inter(fontSize: 14),
                        ),
                        Switch(
                          value: isShared,
                          onChanged:
                              (val) => setModalState(() => isShared = val),
                          activeColor: Colors.deepPurple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  TextField(
                    autofocus: true,
                    onChanged: (val) => taskContent = val,
                    decoration: InputDecoration(
                      hintText:
                          selectedCategory == TodoCategory.forUs
                              ? "VD: Nấu một bữa tối bất ngờ..."
                              : "Nhập việc cần làm...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (taskContent.trim().isEmpty) return;

                        _todoService.addTodo(
                          task: taskContent.trim(),
                          category: selectedCategory,
                          assignedTo: assignedTo,
                          isShared: isShared,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Tạo Mới",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
