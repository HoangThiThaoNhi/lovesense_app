import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_service.dart';

// --- DASHBOARD VIEW ---
class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row
          Row(
            children: [
              Expanded(child: _buildStatCard('Tổng người dùng', '5,234', '+12%', Icons.people, Colors.blue)),
              const SizedBox(width: 20),
              Expanded(child: _buildStatCard('Bài viết mới', '128', '+5%', Icons.article, Colors.orange)),
              const SizedBox(width: 20),
              Expanded(child: _buildStatCard('Người sáng tạo', '45', '+2', Icons.verified, Colors.purple)),
              const SizedBox(width: 20),
              Expanded(child: _buildStatCard('Cảm xúc hôm nay', 'Tích cực', '85%', Icons.sentiment_satisfied_alt, Colors.green)),
            ],
          ),

          const SizedBox(height: 32),

          // Charts Row
          SizedBox(
            height: 400,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Xu hướng cảm xúc (7 ngày)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 24),
                        Expanded(
                          child: BarChart(
                            BarChartData(
                              barGroups: [
                                _makeGroupData(0, 5, 12, 4),
                                _makeGroupData(1, 10, 8, 3),
                                _makeGroupData(2, 6, 15, 2),
                                _makeGroupData(3, 8, 10, 5),
                                _makeGroupData(4, 12, 6, 4),
                                _makeGroupData(5, 10, 9, 3),
                                _makeGroupData(6, 15, 5, 2),
                              ],
                              titlesData: const FlTitlesData(
                                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: _bottomTitles)),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: const FlGridData(show: false),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        Text('Phân bố Cảm xúc', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Expanded(child: Center(child: Icon(Icons.pie_chart, size: 150, color: Colors.pinkAccent))),
                        Text('Tích cực chiếm ưu thế', style: GoogleFonts.inter(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _bottomTitles(double value, TitleMeta meta) {
    const titles = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(titles[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 12)),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y1, double y2, double y3) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(toY: y1, color: Colors.green, width: 10),
      BarChartRodData(toY: y2, color: Colors.blue, width: 10),
      BarChartRodData(toY: y3, color: Colors.red, width: 10),
    ]);
  }

  Widget _buildStatCard(String title, String value, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(sub, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: GoogleFonts.inter(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }
}

// --- USERS VIEW DEPRECATED MOVED TO admin_users_view.dart ---

// --- CONTENT VIEW ---
class AdminContentView extends StatelessWidget {
  const AdminContentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text('Thư viện nội dung (Firebase)', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
               ElevatedButton.icon(
                 onPressed: () => _showAddContentDialog(context),
                 icon: const Icon(Icons.upload),
                 label: const Text('Đăng bài viết'),
                 style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4081), foregroundColor: Colors.white),
               )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: AdminService().getContentStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Text("Lỗi tải dữ liệu");
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) return const Center(child: Text("Chưa có bài viết nào. Hãy thêm mới!"));

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (c, i) => const Divider(),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final id = docs[index].id;
                    return ListTile(
                      leading: data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty
                          ? Image.network(data['imageUrl'], width: 60, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image)) 
                          : const Icon(Icons.image, size: 40, color: Colors.grey),
                      title: Text(data['title'] ?? 'Không tiêu đề', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Danh mục: ${data['category']} • Views: ${data['views'] ?? 0}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => AdminService().deleteContent('contents', id),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  void _showAddContentDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final imgController = TextEditingController();
    String category = 'Mental Health';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm bài viết mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Tiêu đề')),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Mô tả ngắn'), maxLines: 2),
              TextField(controller: imgController, decoration: const InputDecoration(labelText: 'Link ảnh (URL)')),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: category,
                items: ['Mental Health', 'Relationship', 'Self-care', 'Love']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => category = val!,
                decoration: const InputDecoration(labelText: 'Danh mục'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                AdminService().addContent({
                  'title': titleController.text,
                  'description': descController.text,
                  'imageUrl': imgController.text,
                  'category': category,
                  'createdAt': DateTime.now().toIso8601String(),
                  'status': 'published',
                  'views': 0,
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Đăng bài'),
          ),
        ],
      ),
    );
  }
}

