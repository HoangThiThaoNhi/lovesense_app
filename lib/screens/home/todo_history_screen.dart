import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/todo_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TodoHistoryScreen extends StatefulWidget {
  const TodoHistoryScreen({super.key});

  @override
  State<TodoHistoryScreen> createState() => _TodoHistoryScreenState();
}

class _TodoHistoryScreenState extends State<TodoHistoryScreen> {
  // Filter State: 'all', 'completed', 'archived', 'deleted'
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập")));

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text("Lịch sử công việc", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
      ),
      body: Column(
        children: [
          // Dropdown Filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Trạng thái:", 
                  style: GoogleFonts.inter(
                    fontSize: 16, 
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700]
                  )
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filter,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6200EA)),
                      style: GoogleFonts.inter(color: Colors.black87, fontSize: 14),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text("Tất cả")),
                        DropdownMenuItem(value: 'completed', child: Text("Đã xong")),
                        DropdownMenuItem(value: 'archived', child: Text("Đã lưu trữ")),
                        DropdownMenuItem(value: 'deleted', child: Text("Đã xóa", style: TextStyle(color: Colors.red))),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _filter = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _buildHistoryList(uid),
          ),
        ],
      ),
    );
  }

  // Removed _buildFilterChip

  Widget _buildHistoryList(String uid) {
    // 6 months limit
    final limitDate = DateTime.now().subtract(const Duration(days: 180));
    final limitTimestamp = Timestamp.fromDate(limitDate);

    // If filter is 'archived', we might need different query or client side filter
    // To keep it simple and consistent with Firestore limitations, we query ALL in range and filter client side.
    Query query = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('todos')
        .where('timestamp', isGreaterThanOrEqualTo: limitTimestamp)
        .orderBy('timestamp', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        
        // Filter logic
        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final bool isDone = data['done'] ?? false;
          final bool isArchived = data['isArchived'] ?? false;
          final Timestamp? deletedAt = data['deletedAt'];
          final bool isDeleted = deletedAt != null;

          if (_filter == 'all') return true; // Show everything
          if (_filter == 'completed') return isDone && !isDeleted && !isArchived; // Strict completed (not archived/deleted)
          if (_filter == 'archived') return isArchived && !isDeleted; // Strict archived (not deleted)
          if (_filter == 'deleted') return isDeleted; // Strict deleted
          
          return true;
        }).toList();

        if (filteredDocs.isEmpty) {
           return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_list_off, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text("Không tìm thấy công việc nào", style: GoogleFonts.inter(color: Colors.grey)),
              ],
            ),
          );
        }

        // Group by Date (DD/MM/YYYY)
        Map<String, List<DocumentSnapshot>> grouped = {};
        for (var doc in filteredDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final ts = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
          final key = DateFormat('dd/MM/yyyy').format(ts);
          if (grouped[key] == null) grouped[key] = [];
          grouped[key]!.add(doc);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: grouped.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateHeader(entry.key),
                        style: GoogleFonts.montserrat(
                          fontSize: 14, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.grey[700]
                        ),
                      ),
                    ],
                  ),
                ),
                ...entry.value.map((doc) {
                   final data = doc.data() as Map<String, dynamic>;
                   final todo = TodoModel.fromMap(doc.id, data);
                   return _buildHistoryItem(todo);
                }),
              ],
            );
          }).toList(),
        );
      },
    );
  }
  
  String _formatDateHeader(String dateStr) {
    try {
      final date = DateFormat('dd/MM/yyyy').parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      
      if (date == today) return "Hôm nay ($dateStr)";
      if (date == yesterday) return "Hôm qua ($dateStr)";
    } catch (_) {}
    return dateStr;
  }

  Widget _buildHistoryItem(TodoModel todo) {
    Color tagColor = Colors.grey;
    String tagText = "";
    Color bgColor = Colors.white;

    if (todo.deletedAt != null) {
      tagColor = Colors.red;
      tagText = "Đã xóa";
      bgColor = Colors.red.withOpacity(0.05);
    } else if (todo.isArchived) {
      tagColor = Colors.orange;
      tagText = "Đã lưu trữ";
      bgColor = Colors.orange.withOpacity(0.05);
    } else if (todo.done) {
      tagColor = Colors.green;
      tagText = "Đã xong";
      bgColor = Colors.green.withOpacity(0.05);
    } else {
      tagColor = Colors.blue;
      tagText = "Chưa xong";
      bgColor = Colors.white;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.task,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    decoration: (todo.deletedAt != null || todo.done) ? TextDecoration.lineThrough : null,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('HH:mm').format(todo.timestamp!.toDate()),
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: tagColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tagColor.withOpacity(0.3)),
            ),
            child: Text(
              tagText,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: tagColor,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
