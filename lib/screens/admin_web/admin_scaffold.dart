import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminScaffold extends StatefulWidget {
  final Widget body;
  final String title;
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const AdminScaffold({
    super.key,
    required this.body,
    required this.title,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA), // Light Gray Bg
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              children: [
                // Logo Area
                Container(
                  height: 100,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite, color: Color(0xFFFF4081), size: 32),
                      const SizedBox(width: 12),
                      Text(
                        'LOVESENSE\nADMIN',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1),
                const SizedBox(height: 20),

                // Navigation Items
                _buildNavItem(0, 'Dashboard', Icons.dashboard_outlined),
                _buildNavItem(1, 'Người dùng', Icons.people_outline),
                _buildNavItem(2, 'Video', Icons.video_library_outlined),
                _buildNavItem(3, 'Bài viết', Icons.article_outlined),
                _buildNavItem(4, 'Khóa học', Icons.school_outlined),
                _buildNavItem(5, 'Quiz', Icons.quiz_outlined),
                _buildNavItem(6, 'Cài đặt', Icons.settings_outlined),

                const Spacer(),
                
                // Footer
                _buildNavItem(99, 'Đăng xuất', Icons.logout, isDestructive: true),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(onPressed: (){}, icon: const Icon(Icons.notifications_outlined)),
                          const SizedBox(width: 16),
                          const CircleAvatar(
                            backgroundColor: Color(0xFFE3F2FD),
                            child: Icon(Icons.person, color: Color(0xFF1565C0)),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Admin', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('Super Admin', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: widget.body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, {bool isDestructive = false}) {
    final isSelected = widget.selectedIndex == index;
    final color = isDestructive ? Colors.red : (isSelected ? const Color(0xFFFF4081) : Colors.grey[600]);
    final bg = isSelected ? const Color(0xFFFF4081).withOpacity(0.08) : Colors.transparent;

    return InkWell(
      onTap: () => widget.onDestinationSelected(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
