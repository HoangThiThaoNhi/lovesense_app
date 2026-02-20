import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CoupleSpaceSection extends StatelessWidget {
  const CoupleSpaceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            "Không gian Cặp đôi",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildCoupleItem(
                context,
                icon: Icons.timeline,
                title: "Timeline chung",
                color: Colors.blue,
                onTap: () {
                  // Navigate to Shared Timeline
                },
              ),
              _buildCoupleItem(
                context,
                icon: Icons.favorite,
                title: "Kỷ niệm",
                color: Colors.pink,
                onTap: () {
                  // Navigate to Memories
                },
              ),
              _buildCoupleItem(
                context,
                icon: Icons.mood,
                title: "Mood chung",
                color: Colors.orange,
                onTap: () {
                  // Navigate to Mood
                },
              ),
              _buildCoupleItem(
                context,
                icon: Icons.quiz,
                title: "Quiz chung",
                color: Colors.purple,
                onTap: () {
                  // Navigate to Quiz
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoupleItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
