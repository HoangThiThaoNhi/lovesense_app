import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../models/goal_model.dart';
import '../../models/goal_task_model.dart';
import '../../services/goal_todo_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'goal_detail_screen.dart';
import 'widgets/create_goal_bottom_sheet.dart';

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
        Text(
          "Mục tiêu hiện tại",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
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
                                child: Text(
                                  goal.title,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  size: 18,
                                  color: Colors.grey[500],
                                ),
                                onSelected: (val) {
                                  if (val == 'archive') {
                                    _goalService.archiveGoal(goal.id);
                                  }
                                },
                                itemBuilder:
                                    (context) => [
                                      const PopupMenuItem(
                                        value: 'archive',
                                        child: Text("Lưu trữ mục tiêu"),
                                      ),
                                    ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (goal.successMeasurement == 'streak')
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
}
