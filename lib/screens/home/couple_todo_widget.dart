import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../models/goal_model.dart';
import '../../models/goal_task_model.dart';
import '../../services/goal_todo_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'goal_detail_screen.dart';
import 'widgets/create_goal_bottom_sheet.dart';
import 'archived_goals_screen.dart';

class CoupleTodoWidget extends StatefulWidget {
  final UserModel currentUser;

  const CoupleTodoWidget({super.key, required this.currentUser});

  @override
  State<CoupleTodoWidget> createState() => _CoupleTodoWidgetState();
}

class _CoupleTodoWidgetState extends State<CoupleTodoWidget> {
  final GoalTodoService _goalService = GoalTodoService();
  int _selectedTab = 0; // 0: My Growth, 1: Together, 2: For Us

  Stream<List<GoalModel>>? _goalsStream;

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  void _initStreams() {
    PillarType currentPillar = PillarType.values[_selectedTab];
    switch (currentPillar) {
      case PillarType.myGrowth:
        _goalsStream = _goalService.getMyGrowthGoalsStream();
        break;
      case PillarType.together:
        _goalsStream = _goalService.getTogetherGoalsStream(
          widget.currentUser.partnerId ?? '',
        );
        break;
      case PillarType.forUs:
        _goalsStream = _goalService.getForUsGoalsStream();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildSegmentControl(),
        const SizedBox(height: 16),
        _buildMainContent(),
      ],
    ).animate().fadeIn(delay: 200.ms);
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
                const Positioned(
                  right: 0,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 18,
                      child: Icon(Icons.favorite, size: 16, color: Colors.pink),
                    ),
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
                  "Phát triển cùng nhau 🌱",
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "Hệ thống mục tiêu quan hệ",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          // Add Goal Button
          StreamBuilder<List<GoalModel>>(
            stream: _goalsStream,
            builder: (context, snapshot) {
              final goals = snapshot.data ?? [];
              if (goals.length >= 5) {
                return const SizedBox(width: 40); // Placeholder for spacing
              }
              return IconButton(
                icon: Icon(
                  Icons.add_circle,
                  color: Colors.green[600],
                  size: 28,
                ),
                onPressed: () {
                  PillarType currentPillar = PillarType.values[_selectedTab];
                  _showAddGoalBottomSheet(context, currentPillar);
                },
              );
            },
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
        onTap: () {
          if (_selectedTab != index) {
            setState(() {
              _selectedTab = index;
              _initStreams();
            });
          }
        },
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

  Widget _buildMainContent() {
    PillarType currentPillar = PillarType.values[_selectedTab];

    return StreamBuilder<List<GoalModel>>(
      stream: _goalsStream,
      builder: (context, goalSnapshot) {
        if (goalSnapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "Lỗi tải dữ liệu mục tiêu.\n\nChi tiết: ${goalSnapshot.error}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (goalSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final goals = goalSnapshot.data ?? [];

        if (goals.isEmpty) {
          return _buildEmptyState(currentPillar);
        }

        return _buildGoalSection(goals, currentPillar);
      },
    );
  }

  Widget _buildEmptyState(PillarType pillar) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              pillar == PillarType.forUs
                  ? Icons.volunteer_activism_outlined
                  : Icons.flag_outlined,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              "Chưa có mục tiêu nào",
              style: GoogleFonts.inter(color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddGoalBottomSheet(context, pillar),
              icon: const Icon(Icons.add),
              label: const Text("Tạo mục tiêu đầu tiên"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalSection(List<GoalModel> goals, PillarType pillar) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Mục tiêu hiện tại",
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ArchivedGoalsScreen(
                          pillar: pillar,
                          currentUser: widget.currentUser,
                        ),
                  ),
                );
              },
              child: Text(
                "Xem mục tiêu đã lưu trữ ->",
                style: GoogleFonts.inter(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...goals.map((goal) {
          final ownerId =
              goal.ownerId.isEmpty ? widget.currentUser.uid : goal.ownerId;

          return StreamBuilder<List<GoalTaskModel>>(
            stream: _goalService.getTasksByGoalId(ownerId, goal.id),
            builder: (context, snapshot) {
              final goalTasks = snapshot.data ?? [];
              final completed = goalTasks.where((t) => t.isCompleted).length;
              final total = goalTasks.length;
              final progress = total == 0 ? 0.0 : completed / total;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => GoalDetailScreen(
                                goal: goal,
                                currentUser: widget.currentUser,
                              ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      goal.title,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (goal.partnerStatus == 'pending' && goal.ownerId == widget.currentUser.uid)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.access_time, size: 12, color: Colors.orange.shade800),
                                            const SizedBox(width: 4),
                                            Text(
                                              "Đang chờ xác nhận",
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange.shade800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (!(goal.visibility == 'only_creator' && goal.ownerId != widget.currentUser.uid))
                                PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_vert,
                                    size: 20,
                                    color: Colors.grey[500],
                                  ),
                                  onSelected: (val) {
                                    if (val == 'archive') {
                                      _goalService.archiveGoal(goal.id);
                                    } else if (val == 'edit') {
                                      _showEditGoalDialog(goal);
                                    } else if (val == 'delete') {
                                      _confirmDeleteGoal(goal.id);
                                    }
                                  },
                                  itemBuilder:
                                      (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text("Đổi tên mục tiêu"),
                                        ),
                                        const PopupMenuItem(
                                          value: 'archive',
                                          child: Text("Lưu trữ mục tiêu"),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text(
                                            "Xóa mục tiêu",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                ),
                          ],
                        ),
                        const SizedBox(height: 8),

                          // If pending and I am NOT the creator, show Accept/Decline
                          if (goal.partnerStatus == 'pending' && goal.ownerId != widget.currentUser.uid)
                            _buildPendingGoalBanner(goal)
                          else if (goal.successMeasurement == 'streak')
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "0 ngày liên tục", // Mock streak
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[800],
                                  ),
                                ),
                              ],
                            )
                          else if (goal.successMeasurement == 'self_rating')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.purple.shade100,
                                ),
                              ),
                              child: Text(
                                "Tự đánh giá",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple[800],
                                ),
                              ),
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 8,
                                      backgroundColor: Colors.grey[100],
                                      color: _getColorForPillar(pillar),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "$completed/$total",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Color _getColorForPillar(PillarType pillar) {
    if (pillar == PillarType.myGrowth) return Colors.green[500]!;
    if (pillar == PillarType.together) return Colors.blue[500]!;
    return Colors.pink[400]!;
  }

  // Task related methods moved to GoalDetailScreen

  void _showEditGoalDialog(GoalModel goal) {
    final TextEditingController controller = TextEditingController(
      text: goal.title,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              "Đổi tên mục tiêu",
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
                    _goalService.updateGoalTitle(
                      goal.id,
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

  void _confirmDeleteGoal(String goalId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              "Xóa mục tiêu?",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            content: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
                children: const [
                  TextSpan(
                    text: "Cảnh báo: ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  TextSpan(
                    text:
                        "Xóa mục tiêu này sẽ làm mất toàn bộ nhiệm vụ bên trong và ảnh hưởng trực tiếp đến tiến độ đánh giá của bạn.\n\n",
                  ),
                  TextSpan(text: "Bạn có chắc chắn muốn xóa vĩnh viễn không?"),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  _goalService.deleteGoal(goalId);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Vẫn Xóa"),
              ),
            ],
          ),
    );
  }

  void _showAddGoalBottomSheet(BuildContext context, PillarType pillar) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CreateGoalBottomSheet(
          pillar: pillar,
          onGoalCreated: () {
            // Because CoupleTodoWidget uses a StreamBuilder,
            // the new goal will automatically appear in the UI once created.
          },
        );
      },
    );
  }

  Widget _buildPendingGoalBanner(GoalModel goal) {
    // Generate text based on visibility rule
    String pendingText = "";
    if (goal.visibility == 'both') {
      pendingText =
          "Partner muốn cùng bạn hoàn thành mục tiêu ${goal.title} này đó 💕\nHãy cùng nhau chỉnh sửa và cố gắng nhé!";
    } else {
      pendingText =
          "💌 Partner đã tạo mục tiêu ${goal.title} cùng bạn 💛\nBạn cùng đồng hành và hoàn thành nhé!";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mark_email_unread_outlined, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pendingText,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _goalService.declineGoal(goal.ownerId, goal.id);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Hủy bỏ"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _goalService.acceptGoal(goal.ownerId, goal.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Xác nhận"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
