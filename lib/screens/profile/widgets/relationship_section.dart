import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/user_model.dart';
import '../../../services/profile_service.dart';

class RelationshipSection extends StatefulWidget {
  final UserModel currentUser;

  const RelationshipSection({super.key, required this.currentUser});

  @override
  State<RelationshipSection> createState() => _RelationshipSectionState();
}

class _RelationshipSectionState extends State<RelationshipSection> {
  UserModel? _partner;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPartner();
  }

  Future<void> _loadPartner() async {
    if (widget.currentUser.partnerId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final partner = await ProfileService().getUser(
        widget.currentUser.partnerId!,
      );
      if (mounted) {
        setState(() {
          _partner = partner;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _unpair() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Hủy ghép đôi?"),
            content: const Text(
              "Bạn có chắc chắn muốn hủy ghép đôi? Mọi dữ liệu chung sẽ bị ẩn đi.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Hủy"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text("Đồng ý"),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      }

      await ProfileService().unpairCouple();

      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã hủy ghép đôi thành công")),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_partner == null) return const SizedBox();

    final startDate = widget.currentUser.coupleStartDate;
    String dateString = "Chưa cập nhật";
    if (startDate != null) {
      dateString = DateFormat('dd/MM/yyyy').format(startDate);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pink.shade100, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "💞 Đang ghép đôi với:",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.pink.shade800,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.broken_image_outlined, size: 18),
                color: Colors.grey,
                tooltip: "Hủy ghép đôi",
                onPressed: _unpair,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      _partner!.photoUrl != null
                          ? NetworkImage(_partner!.photoUrl!)
                          : null,
                  child:
                      _partner!.photoUrl == null
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _partner!.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Ngày ghép đôi: $dateString",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "Đang hẹn hò",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.pink.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
