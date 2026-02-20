import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lovesense_app/services/profile_service.dart';
import 'package:lovesense_app/models/user_model.dart';
import 'package:lovesense_app/models/request_model.dart';
import 'package:flutter/services.dart';
import '../public_profile_screen.dart';

class CoupleActivationModal extends StatefulWidget {
  final UserModel user;
  const CoupleActivationModal({super.key, required this.user});

  @override
  State<CoupleActivationModal> createState() => _CoupleActivationModalState();
}

class _CoupleActivationModalState extends State<CoupleActivationModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final ProfileService _profileService = ProfileService();

  bool _isSearching = false;
  List<UserModel>? _searchResults;
  String? _searchError;
  bool _isSending = false;

  // Code State
  String? _myCode;
  bool _isGeneratingCode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _myCode = widget.user.coupleCode;
    // Auto-generate code if missing
    if (_myCode == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateCode();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
      _searchResults = null;
    });

    try {
      final results = await _profileService.searchUsers(query);
      setState(() {
        _searchResults = results;
        if (results.isEmpty) {
          _searchError = "Không tìm thấy người dùng nào.";
        }
      });
    } catch (e) {
      setState(() {
        _searchError = "Lỗi tìm kiếm: $e";
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _sendInvite(UserModel user) async {
    setState(() => _isSending = true);
    try {
      await _profileService.sendCoupleRequest(
        user.uid,
        "Chào ${user.name}, hãy trở thành cặp đôi của mình nhé!",
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đã gửi lời mời tới ${user.name}")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi: ${e.toString().replaceAll('Exception: ', '')}"),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showSentRequestPopup(
    BuildContext context,
    UserModel user,
    String requestId,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "Bạn đã gửi lời mời",
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
                        await _profileService.cancelSentRequest(requestId);
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
  }

  Widget _buildSendInviteTab() {
    return StreamBuilder<List<RequestModel>>(
      stream: _profileService.getSentRequests(),
      builder: (context, snapshot) {
        final sentRequests = snapshot.data ?? [];

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Nhập email, SĐT hoặc tên...",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _performSearch,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onSubmitted: (_) => _performSearch(),
              ),
              const SizedBox(height: 20),

              if (_isSearching)
                const CircularProgressIndicator()
              else if (_searchError != null)
                Text(_searchError!, style: const TextStyle(color: Colors.red))
              else if (_searchResults != null)
                Expanded(
                  child: ListView.separated(
                    itemCount: _searchResults!.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final user = _searchResults![index];
                      // Check if already sent
                      final existingReq = sentRequests.firstWhere(
                        (r) =>
                            r.toUid == user.uid &&
                            r.status == RequestStatus.pending,
                        orElse:
                            () => RequestModel(
                              id: '',
                              fromUid: '',
                              toUid: '',
                              type: RequestType.coupleInvite,
                              createdAt: DateTime.now(),
                            ),
                      );
                      final isSent = existingReq.id.isNotEmpty;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundImage:
                                  user.photoUrl != null
                                      ? NetworkImage(user.photoUrl!)
                                      : null,
                              child:
                                  user.photoUrl == null
                                      ? const Icon(Icons.person)
                                      : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    user.email,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSent)
                              OutlinedButton.icon(
                                onPressed:
                                    () => _showSentRequestPopup(
                                      context,
                                      user,
                                      existingReq.id,
                                    ),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text("Đã gửi"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  side: const BorderSide(color: Colors.blue),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                ),
                              )
                            else
                              ElevatedButton(
                                onPressed:
                                    _isSending ? null : () => _sendInvite(user),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                                child: const Text("Mời"),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          "Lời mời đã gửi",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(
                        child:
                            sentRequests.isEmpty
                                ? Center(
                                  child: Text(
                                    "Chưa gửi lời mời nào.",
                                    style: TextStyle(color: Colors.grey[400]),
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: sentRequests.length,
                                  itemBuilder: (context, index) {
                                    final req = sentRequests[index];
                                    return FutureBuilder<UserModel?>(
                                      future: _profileService.getUser(
                                        req.toUid,
                                      ),
                                      builder: (context, userSnapshot) {
                                        final targetUser = userSnapshot.data;
                                        return ListTile(
                                          onTap:
                                              targetUser != null
                                                  ? () => _showSentRequestPopup(
                                                    context,
                                                    targetUser,
                                                    req.id,
                                                  )
                                                  : null,
                                          leading: CircleAvatar(
                                            backgroundImage:
                                                targetUser?.photoUrl != null
                                                    ? NetworkImage(
                                                      targetUser!.photoUrl!,
                                                    )
                                                    : null,
                                            child:
                                                targetUser?.photoUrl == null
                                                    ? const Icon(Icons.person)
                                                    : null,
                                          ),
                                          title: Text(
                                            targetUser?.name ?? "Người dùng",
                                          ),
                                          subtitle: Text(
                                            "Đã gửi: ${_formatDate(req.createdAt)}",
                                          ),
                                          trailing: const Icon(
                                            Icons.chevron_right,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  void _generateCode() async {
    setState(() => _isGeneratingCode = true);
    try {
      final code = await _profileService.generateCoupleCode();
      setState(() {
        _myCode = code;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi tạo mã: $e")));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingCode = false);
    }
  }

  void _copyCode() {
    if (_myCode == null) return;
    Clipboard.setData(ClipboardData(text: _myCode!));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Đã sao chép mã!")));
  }

  void _submitCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    if (code == _myCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không thể tự nhập mã của chính mình!")),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      await _profileService.sendCoupleRequestByCode(code);
      if (mounted) {
        Navigator.pop(context); // Close modal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã gửi lời mời thành công!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi: ${e.toString().replaceAll('Exception: ', '')}"),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (Container structure same)
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: 550, // Increased height
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle Bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // ... (Title/Desc same)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                  Text(
                    "Kích hoạt chế độ Cặp đôi",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Sử dụng mã hoặc tìm kiếm để kết nối với người ấy.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: Colors.pink,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.pink,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
              tabs: const [Tab(text: "Gửi lời mời"), Tab(text: "Mã kết nối")],
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildSendInviteTab(), _buildEnterCodeTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // _buildSendInviteTab remains mostly same ...

  Widget _buildEnterCodeTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // My Code Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.pink[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.pink[100]!),
            ),
            child: Column(
              children: [
                Text(
                  "Mã Kết Nối Của Bạn",
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.pink),
                ),
                const SizedBox(height: 8),
                if (_myCode != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _myCode!,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          color: Colors.pink[800],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _copyCode,
                        icon: const Icon(
                          Icons.copy,
                          size: 20,
                          color: Colors.pinkAccent,
                        ),
                      ),
                    ],
                  )
                else
                  _isGeneratingCode
                      ? const CircularProgressIndicator()
                      : TextButton.icon(
                        onPressed: _generateCode,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Tạo mã ngay"),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.pink,
                        ),
                      ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Text(
            "Hoặc nhập mã của đối phương",
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _codeController,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
            decoration: InputDecoration(
              hintText: "XXXXXX",
              hintStyle: TextStyle(color: Colors.grey[300]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.pink, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSending ? null : _submitCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child:
                  _isSending
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Text(
                        "Kết nối ngay",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
