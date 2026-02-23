import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/todo_model.dart';
import '../../models/user_model.dart';
import '../../services/todo_service.dart';
import 'widgets/couple_todo_card.dart';

class CoupleTodoDetailScreen extends StatelessWidget {
  final UserModel currentUser;
  final int selectedTab; // 0: Personal, 1: Together, 2: For Us
  final TodoService todoService = TodoService();

  CoupleTodoDetailScreen({
    super.key,
    required this.currentUser,
    required this.selectedTab,
  });

  String get title {
    if (selectedTab == 0) return "Mục tiêu cá nhân";
    if (selectedTab == 1) return "Danh sách việc chung";
    return "Tình yêu & Bất ngờ";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<List<TodoModel>>(
          stream: todoService.getCoupleTodosStream(currentUser.partnerId ?? ''),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allTasks = snapshot.data ?? [];
            List<TodoModel> filteredTasks = [];

            if (selectedTab == 0) {
              filteredTasks =
                  allTasks
                      .where(
                        (t) =>
                            t.category == TodoCategory.personal &&
                            t.creatorId == currentUser.uid,
                      )
                      .toList();
            } else if (selectedTab == 1) {
              filteredTasks =
                  allTasks
                      .where((t) => t.category == TodoCategory.together)
                      .toList();
            } else {
              filteredTasks =
                  allTasks
                      .where(
                        (t) =>
                            t.category == TodoCategory.forUs &&
                            t.creatorId == currentUser.uid,
                      )
                      .toList();
            }

            if (filteredTasks.isEmpty) {
              return Center(
                child: Text(
                  "Không có công việc nào.",
                  style: GoogleFonts.inter(color: Colors.grey[500]),
                ),
              );
            }

            return ListView.separated(
              itemCount: filteredTasks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final todo = filteredTasks[index];
                return CoupleTodoCard(todo: todo, currentUser: currentUser);
              },
            );
          },
        ),
      ),
    );
  }
}
