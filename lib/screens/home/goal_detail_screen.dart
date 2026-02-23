import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/goal_model.dart';
import '../../models/goal_task_model.dart';
import '../../models/user_model.dart';
import '../../services/goal_todo_service.dart';
import 'widgets/reflection_bottom_sheet.dart';

class GoalDetailScreen extends StatefulWidget {
  final GoalModel goal;
  final UserModel currentUser;

  const GoalDetailScreen({
    super.key,
    required this.goal,
    required this.currentUser,
  });

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final GoalTodoService _goalService = GoalTodoService();
  late String _ownerId;

  @override
  void initState() {
    super.initState();
    _ownerId =
        widget.goal.ownerId.isEmpty
            ? widget.currentUser.uid
            : widget.goal.ownerId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Chi tiết Mục tiêu",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task),
            onPressed: () => _showAddTaskBottomSheet(context),
            tooltip: 'Thêm Nhiệm vụ',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildGoalHeader()),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: _buildTasksList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getColorForPillar(
                    widget.goal.pillar,
                  ).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconForPillar(widget.goal.pillar),
                  color: _getColorForPillar(widget.goal.pillar),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.goal.title,
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getPillarName(widget.goal.pillar),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildTasksList() {
    return StreamBuilder<List<GoalTaskModel>>(
      stream: _goalService.getTasksByGoalId(_ownerId, widget.goal.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  "Lỗi tải dữ liệu nhiệm vụ.\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final tasks = snapshot.data ?? [];

        if (tasks.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.flight_takeoff,
                      size: 64,
                      color: Colors.blue[100],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Chưa có nhiệm vụ nào.",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddTaskBottomSheet(context),
                      icon: const Icon(Icons.add),
                      label: const Text("Tạo Nhiệm vụ ngay"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final activeTasks = tasks.where((t) => !t.isCompleted).toList();
        final completedTasks = tasks.where((t) => t.isCompleted).toList();

        return SliverList(
          delegate: SliverChildListDelegate([
            if (activeTasks.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 4),
                child: Text(
                  "Cần làm (${activeTasks.length})",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                    fontSize: 15,
                  ),
                ),
              ),
              ...activeTasks.map((t) => _buildTaskItem(t)),
              const SizedBox(height: 24),
            ],
            if (completedTasks.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  "Đã hoàn thành (${completedTasks.length})",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                    fontSize: 15,
                  ),
                ),
              ),
              ...completedTasks.map((t) => _buildTaskItem(t, opacity: 0.6)),
              const SizedBox(height: 40),
            ],
          ]),
        );
      },
    );
  }

  Widget _buildTaskItem(GoalTaskModel task, {double opacity = 1.0}) {
    // Only current user handles complete action
    final bool isCompleted = task.isCompleted;

    return Opacity(
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isCompleted ? Colors.grey[100] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (isCompleted) {
                  _goalService.undoCompleteTask(_ownerId, task.id);
                } else {
                  _handleCompleteTask(task);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? Colors.green : Colors.transparent,
                  border: Border.all(
                    color: isCompleted ? Colors.green : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child:
                    isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted ? Colors.grey[600] : Colors.black87,
                    ),
                  ),
                  if (task.type == TaskType.repeating) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.repeat, size: 14, color: Colors.orange[700]),
                        const SizedBox(width: 4),
                        Text(
                          "${task.frequency ?? 'Lặp lại'} • Streak: ${task.streak} 🔥",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.orange[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 20, color: Colors.grey[600]),
              onSelected: (val) {
                if (val == 'edit') {
                  _showEditTaskDialog(task);
                } else if (val == 'delete') {
                  _confirmDeleteTask(task.id);
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text("Đổi tên nhiệm vụ"),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        "Xóa nhiệm vụ",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.05, end: 0);
  }

  void _handleCompleteTask(GoalTaskModel task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ReflectionBottomSheet(
            onSaved: (mood, note) async {
              await _goalService.completeTask(_ownerId, task.id, mood, note);
            },
          ),
    );
  }

  void _showAddTaskBottomSheet(BuildContext context) {
    String title = "";
    TaskType type = TaskType.oneTime;

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
                top: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Thêm Nhiệm Vụ",
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    autofocus: true,
                    onChanged: (val) => title = val,
                    decoration: InputDecoration(
                      hintText: "Tên nhiệm vụ...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Loại nhiệm vụ:",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text("Một lần"),
                        selected: type == TaskType.oneTime,
                        onSelected:
                            (val) =>
                                setModalState(() => type = TaskType.oneTime),
                        selectedColor: Colors.deepPurple[50],
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("Lặp lại"),
                        selected: type == TaskType.repeating,
                        onSelected:
                            (val) =>
                                setModalState(() => type = TaskType.repeating),
                        selectedColor: Colors.deepPurple[50],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (title.trim().isEmpty) return;

                        final newTask = GoalTaskModel(
                          id: '',
                          goalId: widget.goal.id,
                          title: title.trim(),
                          type: type,
                          frequency:
                              type == TaskType.repeating ? 'Hàng ngày' : null,
                          createdAt: DateTime.now(),
                        );

                        try {
                          await _goalService.createTask(_ownerId, newTask);
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Tạo Nhiệm Vụ",
                        style: TextStyle(fontSize: 16),
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

  void _showEditTaskDialog(GoalTaskModel task) {
    final TextEditingController controller = TextEditingController(
      text: task.title,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              "Đổi tên nhiệm vụ",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: "Nhập tên mới..."),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    _goalService.updateTaskTitle(
                      _ownerId,
                      task.id,
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

  void _confirmDeleteTask(String taskId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              "Xóa nhiệm vụ?",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Bạn có chắc chắn muốn xóa nhiệm vụ này không?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  _goalService.deleteTask(_ownerId, taskId);
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

  Color _getColorForPillar(PillarType pillar) {
    if (pillar == PillarType.myGrowth) return Colors.green[500]!;
    if (pillar == PillarType.together) return Colors.blue[500]!;
    return Colors.pink[400]!;
  }

  IconData _getIconForPillar(PillarType pillar) {
    if (pillar == PillarType.myGrowth) return Icons.person_outline;
    if (pillar == PillarType.together) return Icons.people_outline;
    return Icons.favorite_outline;
  }

  String _getPillarName(PillarType pillar) {
    if (pillar == PillarType.myGrowth) return "My Growth";
    if (pillar == PillarType.together) return "Together";
    return "For Us";
  }
}
