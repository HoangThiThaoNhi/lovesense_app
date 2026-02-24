import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/goal_model.dart';
import '../../models/user_model.dart';
import 'goal_detail_screen.dart';
import '../../services/goal_todo_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ArchivedGoalsScreen extends StatelessWidget {
  final PillarType pillar;
  final UserModel currentUser;

  const ArchivedGoalsScreen({
    super.key,
    required this.pillar,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final goalService = GoalTodoService();

    String getPillarName() {
      if (pillar == PillarType.myGrowth) return "My Growth";
      if (pillar == PillarType.together) return "Together";
      return "For Us";
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Mục tiêu đã lưu trữ - ${getPillarName()}",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: StreamBuilder<List<GoalModel>>(
        stream: goalService.getArchivedGoalsStream(pillar),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final goals = snapshot.data ?? [];
          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.archive_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Trống",
                    style: GoogleFonts.inter(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => GoalDetailScreen(
                            goal: goal,
                            currentUser: currentUser,
                          ),
                    ),
                  );
                },
                child: Container(
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.archive, color: Colors.grey[400]),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goal.title,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.unarchive_outlined,
                            color: Colors.blue,
                          ),
                          tooltip: 'Khôi phục Mục tiêu',
                          onPressed: () async {
                            await goalService.unarchiveGoal(goal.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Đã khôi phục mục tiêu thành công!',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: 0.1, end: 0),
              );
            },
          );
        },
      ),
    );
  }
}
