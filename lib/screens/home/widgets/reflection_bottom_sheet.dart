import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/task_log_model.dart';

class ReflectionBottomSheet extends StatefulWidget {
  final Future<void> Function(ReflectionMood, String?) onSaved;

  const ReflectionBottomSheet({super.key, required this.onSaved});

  @override
  State<ReflectionBottomSheet> createState() => _ReflectionBottomSheetState();
}

class _ReflectionBottomSheetState extends State<ReflectionBottomSheet> {
  ReflectionMood? _selectedMood;
  String? _note;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Bạn cảm thấy thế nào\nsau khi làm điều này? 🌱",
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMoodOption(ReflectionMood.difficult, "Khó khăn", "😞"),
              _buildMoodOption(ReflectionMood.normal, "Bình thường", "😐"),
              _buildMoodOption(ReflectionMood.better, "Tốt hơn", "😊"),
            ],
          ),
          const SizedBox(height: 32),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child:
                _selectedMood != null
                    ? TextField(
                      onChanged: (val) => _note = val,
                      decoration: InputDecoration(
                        hintText: "Ghi chú thêm (Không bắt buộc)...",
                        hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.deepPurple[300]!,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      maxLines: 2,
                    )
                    : const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _selectedMood == null || _isLoading
                      ? null
                      : () async {
                        setState(() => _isLoading = true);
                        await widget.onSaved(_selectedMood!, _note);
                        if (mounted) Navigator.pop(context);
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[500],
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        "Lưu lại",
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
  }

  Widget _buildMoodOption(ReflectionMood mood, String label, String emoji) {
    final isSelected = _selectedMood == mood;
    return GestureDetector(
      onTap: () => setState(() => _selectedMood = mood),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple[50] : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.deepPurple[200]! : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: TextStyle(
                fontSize: 40,
                color: isSelected ? null : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.deepPurple[800] : Colors.grey[500],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
