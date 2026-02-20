import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/user_model.dart';
import '../../../models/request_model.dart';
import '../../../services/profile_service.dart';
import 'requests_modal.dart';
import 'package:lovesense_app/screens/profile/widgets/couple_activation_modal.dart';
import '../public_profile_screen.dart';

class ModeStatusSection extends StatefulWidget {
  final UserModel user;
  final List<RequestModel> pendingRequests;

  const ModeStatusSection({
    super.key,
    required this.user,
    required this.pendingRequests,
  });

  @override
  State<ModeStatusSection> createState() => _ModeStatusSectionState();
}

class _ModeStatusSectionState extends State<ModeStatusSection> {
  final ProfileService _profileService = ProfileService();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRequestBadge(),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _buildModeBox(
                  mode: 'Cá nhân',
                  isActive: widget.user.role == 'single',
                  colors: [Colors.blueAccent, Colors.cyan],
                  inactiveColors: [
                    Colors.blue[50]!,
                    Colors.cyan[50]!,
                  ], // Pastel Blue
                  icon: Icons.person,
                  child: _buildPersonalContent(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StreamBuilder<List<RequestModel>>(
                  stream: _profileService.getSentRequests(),
                  builder: (context, snapshot) {
                    final sentRequests = snapshot.data ?? [];
                    final hasSentRequest = sentRequests.isNotEmpty;

                    return GestureDetector(
                      onTap: () {
                        if (widget.user.role == 'couple') {
                          return; // Do nothing if already paired
                        }

                        // Scenario B: Check Incoming
                        final incomingRequests =
                            widget.pendingRequests
                                .where(
                                  (r) => r.type == RequestType.coupleInvite,
                                )
                                .toList();

                        if (incomingRequests.isNotEmpty) {
                          _showIncomingRequestDialog(
                            context,
                            incomingRequests.first,
                          );
                        } else if (hasSentRequest) {
                          // Scenario A (Wait): Show cancel option
                          _showSentRequestPopup(
                            context,
                            sentRequests
                                .first, // We need user info here. Wait, sentRequests are just RequestModels.
                            // Problem: RequestModel only has IDs. We need the target User object.
                            // We need to fetch it. `_showSentRequestPopup` expects UserModel.
                            // Let's modify logic to fetch user first.
                          );
                        } else {
                          // Default: Show Activation
                          _showCoupleActivationModal(context);
                        }
                      },
                      child: _buildModeBox(
                        mode:
                            hasSentRequest
                                ? 'Đang chờ...'
                                : 'Cặp đôi', // Change title if waiting
                        isActive: widget.user.role == 'couple',
                        colors: [
                          const Color(0xFFFF4081),
                          const Color(0xFFFF80AB),
                        ],
                        inactiveColors: [
                          Colors.pink[50]!,
                          Colors.pink[100]!.withOpacity(0.5),
                        ],
                        icon:
                            hasSentRequest
                                ? Icons.hourglass_empty
                                : Icons.favorite,
                        child: _buildCoupleContent(hasSentRequest),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModeBox(
                  mode: 'Sáng tạo',
                  isActive: widget.user.role == 'creator',
                  colors: [Colors.purple, Colors.deepPurpleAccent],
                  inactiveColors: [
                    Colors.purple[50]!,
                    Colors.deepPurple[50]!,
                  ], // Pastel Purple
                  icon: Icons.auto_awesome,
                  child: _buildCreatorContent(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequestBadge() {
    return StreamBuilder<List<RequestModel>>(
      stream: ProfileService().getPendingRequests(),
      builder: (context, snapshot) {
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) return const SizedBox();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const RequestsModal(),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Bạn có ${requests.length} yêu cầu đang chờ",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.orange),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeBox({
    required String mode,
    required bool isActive,
    required List<Color> colors, // [Primary, Lighter/Secondary]
    required List<Color> inactiveColors, // [Pastel Tint, ..]
    required IconData icon,
    required Widget child,
  }) {
    // Modern Flat Design Concept:
    // Active: Solid vibrant color (Primary), White content.
    // Inactive: Pastel tint background, Primary color content.
    // No gradients, heavy shadows, or thick borders.

    final Color mainColor = colors.first;
    final Color backgroundColor = isActive ? mainColor : inactiveColors.first;
    final Color contentColor = isActive ? Colors.white : mainColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 170, // Slightly more compact
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24), // Modern rounded
        boxShadow:
            isActive
                ? [
                  BoxShadow(
                    color: mainColor.withOpacity(0.3),
                    offset: const Offset(0, 8),
                    blurRadius: 16,
                  ),
                ]
                : [], // Clean interactions
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header: Icon + Status Dot
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      isActive ? Colors.white.withOpacity(0.2) : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: contentColor, size: 20),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: mainColor, size: 12),
                ),
            ],
          ),

          const Spacer(),

          // Body Text
          Text(
            mode,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: contentColor,
            ),
          ),

          const SizedBox(height: 4),

          // Child Content (Buttons/Status)
          // We need to ensure child content adapts to the new color scheme
          Theme(
            data: ThemeData(
              textTheme: TextTheme(bodyMedium: TextStyle(color: contentColor)),
              iconTheme: IconThemeData(color: contentColor),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  foregroundColor: contentColor,
                  side: BorderSide(color: contentColor.withOpacity(0.5)),
                ),
              ),
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalContent() {
    return const SizedBox(); // Minimalist: No text for "Personal" if generic
  }

  Widget _buildCoupleContent(bool hasSentRequest) {
    final bool isActive = widget.user.role == 'couple';
    if (isActive && widget.user.partnerId != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _confirmUnpair(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Hủy đôi", style: TextStyle(fontSize: 10)),
            ),
          ),
        ],
      );
    }

    // Scenario A: Waiting state text
    if (hasSentRequest) {
      return Text(
        "Đang chờ đối phương...",
        style: GoogleFonts.inter(fontSize: 11, color: Colors.pink),
      );
    }

    return Text(
      "Chưa ghép đôi",
      style: GoogleFonts.inter(
        fontSize: 11,
        color: Colors.grey[600],
      ), // Keep grey for inactive description
    );
  }

  Widget _buildCreatorContent() {
    final bool isActive = widget.user.role == 'creator';
    if (isActive) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.purple,
            elevation: 0,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text("Dashboard", style: TextStyle(fontSize: 10)),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _showCreatorApplicationDialog(context),
        style: OutlinedButton.styleFrom(
          // Theme data in _buildModeBox handles color
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 28),
          side: BorderSide(
            color:
                widget.user.role == 'creator'
                    ? Colors.white.withOpacity(0.5)
                    : Colors.purple.withOpacity(0.5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text("Đăng ký", style: TextStyle(fontSize: 10)),
      ),
    );
  }

  void _showCoupleActivationModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CoupleActivationModal(user: widget.user),
    );
  }

  void _showIncomingRequestDialog(BuildContext context, RequestModel request) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Lời mời ghép đôi"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => PublicProfileScreen(uid: request.fromUid),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage:
                            request.senderAvatar != null
                                ? NetworkImage(request.senderAvatar!)
                                : null,
                        child:
                            request.senderAvatar == null
                                ? const Icon(Icons.person)
                                : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "${request.senderName ?? 'Người dùng'} muốn ghép đôi với bạn!",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "(Chạm để xem hồ sơ)",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _profileService.declineRequest(request.id);
                },
                child: const Text(
                  "Từ chối",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _profileService.acceptRequest(request);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                child: const Text("Đồng ý"),
              ),
            ],
          ),
    );
  }

  void _confirmUnpair(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Hủy ghép đôi?"),
            content: const Text(
              "Bạn có chắc chắn muốn hủy chế độ Cặp đôi? Hành động này không thể hoàn tác.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Hủy"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await ProfileService().unpairCouple();
                },
                child: const Text(
                  "Đồng ý",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _showCreatorApplicationDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Đăng ký Nhà sáng tạo"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Vui lòng nhập lý do hoặc kế hoạch nội dung của bạn:",
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Nội dung...",
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Hủy"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    try {
                      await ProfileService().sendCreatorApplication(
                        controller.text,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Đã gửi đơn đăng ký!")),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
                      }
                    }
                  }
                },
                child: const Text("Gửi"),
              ),
            ],
          ),
    );
  }

  void _showSentRequestPopup(BuildContext context, RequestModel request) async {
    // Show loading while fetching user
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final user = await _profileService.getUser(request.toUid);
      if (context.mounted) Navigator.pop(context); // Close loading

      if (user == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Không tìm thấy người dùng")),
          );
        }
        return;
      }

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Đang chờ phản hồi",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PublicProfileScreen(uid: user.uid),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[200],
                          backgroundImage:
                              user.photoUrl != null
                                  ? NetworkImage(user.photoUrl!)
                                  : null,
                          child:
                              user.photoUrl == null
                                  ? const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.grey,
                                  )
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.name,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (user.username != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "@${user.username}",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        try {
                          await _profileService.cancelSentRequest(request.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Đã hủy lời mời")),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
                          }
                        }
                      },
                      icon: const Icon(
                        Icons.person_remove_outlined,
                        color: Colors.red,
                      ),
                      label: const Text(
                        "Hủy lời mời",
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      "Đóng",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading if error
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    }
  }
}
