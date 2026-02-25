import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/request_model.dart';
import '../../../models/notification_model.dart';
import '../../../services/profile_service.dart';
import '../../../services/notification_service.dart';
import '../../main_screen.dart';

class RequestsModal extends StatefulWidget {
  const RequestsModal({super.key});

  @override
  State<RequestsModal> createState() => _RequestsModalState();
}

class _RequestsModalState extends State<RequestsModal> {
  @override
  void initState() {
    super.initState();
    // Mark notifications as read when opening the modal
    NotificationService().markAllAsRead();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              labelColor: const Color(0xFFFF4081),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFFF4081),
              tabs: const [Tab(text: "Thông báo"), Tab(text: "Yêu cầu")],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: TabBarView(
                children: [_buildNotificationsTab(), _buildRequestsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return StreamBuilder<List<NotificationModel>>(
      stream: NotificationService().getMyNotifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Lỗi: ${snapshot.error}"));
        }

        final notifications = snapshot.data ?? [];

        return notifications.isEmpty
            ? Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                "Chưa có thông báo nào.",
                style: GoogleFonts.inter(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
            : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                String displayContent = notif.content;
                if (displayContent.startsWith('[TEXT] ')) {
                  displayContent = displayContent.replaceFirst('[TEXT] ', '');
                } else if (displayContent.startsWith('[EMOJI] ')) {
                  displayContent = displayContent.replaceFirst('[EMOJI] ', '');
                }

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        notif.senderAvatar.isNotEmpty
                            ? NetworkImage(notif.senderAvatar)
                            : null,
                    child:
                        notif.senderAvatar.isEmpty
                            ? const Icon(Icons.person, color: Colors.grey)
                            : null,
                  ),
                  title: Text(
                    displayContent.contains('lời nhắn')
                        ? "${notif.senderName} $displayContent"
                        : "${notif.senderName} $displayContent",
                    style: GoogleFonts.inter(
                      fontWeight:
                          notif.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('dd/MM HH:mm').format(notif.createdAt),
                    style: GoogleFonts.inter(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    // Caculate routing if it's a goal invitation
                    if (notif.type == NotificationType.goalInvitation) {
                      Navigator.pop(context); // Đóng modal hiện tại
                      final mainState = context.findAncestorStateOfType<MainScreenState>();
                      mainState?.navigateToTab(0); // Dashboard => Tab 0
                    }
                  },
                );
              },
            );
      },
    );
  }

  Widget _buildRequestsTab() {
    return StreamBuilder<List<RequestModel>>(
      stream: ProfileService().getPendingRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Lỗi: ${snapshot.error}"));
        }

        final requests = snapshot.data ?? [];

        return requests.isEmpty
            ? Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                "Không có yêu cầu nào.",
                style: GoogleFonts.inter(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
            : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final req = requests[index];
                if (req.type == RequestType.coupleInvite) {
                  return _buildCoupleInviteItem(context, req);
                } else {
                  return _buildCreatorAppItem(context, req);
                }
              },
            );
      },
    );
  }

  Widget _buildCoupleInviteItem(BuildContext context, RequestModel req) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage:
                    req.senderAvatar != null
                        ? NetworkImage(req.senderAvatar!)
                        : null,
                child:
                    req.senderAvatar == null
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.senderName ?? "Người dùng",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      req.senderUsername != null
                          ? "@${req.senderUsername}"
                          : "Gửi yêu cầu ghép đôi",
                      style: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM HH:mm').format(req.createdAt),
                      style: GoogleFonts.inter(
                        color: Colors.grey[400],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (req.message != null && req.message!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "\"${req.message}\"",
                style: GoogleFonts.inter(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await ProfileService().declineRequest(req.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Từ chối"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await ProfileService().acceptRequest(req);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Đã chấp nhận ghép đôi!"),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4081),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Chấp nhận"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorAppItem(BuildContext context, RequestModel req) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.amber[100],
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.star, color: Colors.amber),
      ),
      title: const Text("Đăng ký Nhà sáng tạo"),
      subtitle: Text(
        "Trạng thái: ${req.status == RequestStatus.pending ? 'Đang xét duyệt' : 'Đã xử lý'}",
      ),
      trailing: const Icon(Icons.info_outline),
      onTap: () {
        // Show detailed status popup if needed
      },
    );
  }
}
