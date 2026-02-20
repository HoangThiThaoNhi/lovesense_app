import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../models/mood_model.dart';
import '../../services/auth_service.dart';
import '../../services/mood_service.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;

class CoupleMoodWidget extends StatefulWidget {
  final UserModel currentUser;

  const CoupleMoodWidget({super.key, required this.currentUser});

  @override
  State<CoupleMoodWidget> createState() => _CoupleMoodWidgetState();
}

class _CoupleMoodWidgetState extends State<CoupleMoodWidget> {
  final _moodService = MoodService();
  final _reactionController = TextEditingController();

  late Future<UserModel?> _partnerFuture;
  late Stream<DailyMoodSummary?> _partnerMoodStream;
  late Stream<DailyMoodSummary?> _myMoodStream;

  @override
  void initState() {
    super.initState();
    _partnerFuture = _getPartnerData();
    _partnerMoodStream =
        widget.currentUser.partnerId != null
            ? _moodService.getPartnerTodayMoodStream(
              widget.currentUser.partnerId!,
            )
            : Stream.value(null);
    _myMoodStream = _moodService.getDailySummaryStream();
  }

  Future<UserModel?> _getPartnerData() async {
    if (widget.currentUser.partnerId == null) return null;
    return await AuthService().getUser(widget.currentUser.partnerId!);
  }

  // Floating Emoji Logic
  final List<Widget> _floatingEmojis = [];
  final math.Random _random = math.Random();

  void _sendQuickEmoji(String partnerId, String emoji) {
    // 1. Local Animation state FIRST (Optimistic UI)
    final uniqueKey = UniqueKey();
    final startX = _random.nextDouble() * 100 - 50; // Random horizontal offset

    setState(() {
      _floatingEmojis.add(
        Positioned(
          bottom: 20,
          left: MediaQuery.of(context).size.width / 2 - 20 + startX,
          key: uniqueKey,
          child: DefaultTextStyle(
                style: const TextStyle(fontSize: 32),
                child: Text(emoji),
              )
              .animate(
                onComplete: (controller) {
                  if (mounted) {
                    setState(() {
                      _floatingEmojis.removeWhere((w) => w.key == uniqueKey);
                    });
                  }
                },
              )
              .moveY(
                begin: 0,
                end: -150,
                duration: 1500.ms,
                curve: Curves.easeOut,
              )
              .fadeIn(duration: 200.ms)
              .fadeOut(delay: 1000.ms, duration: 500.ms)
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.5, 1.5),
                duration: 1500.ms,
              ),
        ),
      );
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã gửi $emoji'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // 2. Send to backend asynchronously without awaiting
    _moodService.sendReactionToPartner(partnerId, emoji, null);
  }

  List<String> _getSuggestions(MoodType mood) {
    switch (mood) {
      case MoodType.happy:
        return [
          "Hôm nay vui quá ta! 🥰",
          "Lan tỏa năng lượng này báo! ✨",
          "Nhìn e/a vui anh/e cũng vui lây 😍",
        ];
      case MoodType.sad:
        return [
          "Hôm nay mệt à? Anh/Em ở đây nhé. 🫂",
          "Nghỉ ngơi chút đi. ❤️",
          "Muốn kể anh/em nghe không?",
        ];
      case MoodType.terrible:
        return [
          "Thở sâu nào, thư giãn chút nhé. 🍵",
          "Đừng bực mình quá, hại sức khỏe đó. 💪",
          "Thương thương, qua đây ôm cái nào. 🫂",
        ];
      case MoodType.awesome:
        return [
          "Bình yên là nhất rồi! ☕",
          "Tuyệt vời quá! 🥰",
          "Chúc một ngày luôn nhẹ nhàng như thế này nhé. ✨",
        ];
      case MoodType.neutral:
        return [
          "Ngày hôm nay thế nào? Trổ tài kể chuyện xem nào.",
          "Cố lên nha! 🥰",
          "Nhớ uống đủ nước đó! 💧",
        ];
    }
  }

  void _showReactionSheet(
    String partnerId,
    String partnerName,
    MoodType? partnerMood,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final suggestions =
            partnerMood != null ? _getSuggestions(partnerMood) : <String>[];
        return _buildReactionSheet(partnerId, partnerName, suggestions);
      },
    );
  }

  Widget _buildReactionSheet(
    String partnerId,
    String partnerName,
    List<String> suggestions,
  ) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Gửi lời nhắn",
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                "💬 Gợi ý nhanh:",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.pink[400],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    suggestions.map((s) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          _reactionController.text = s;
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.pink[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.pink[100]!),
                          ),
                          child: Text(
                            s,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.pink[900],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _reactionController,
                    maxLength: 100,
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Viết lời nhắn nhẹ nhàng…",
                      hintStyle: GoogleFonts.inter(fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Colors.pink),
                      ),
                      counterText:
                          "", // Hide max length counter to save space if wanted, but fine to keep.
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.pink,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () async {
                      if (_reactionController.text.trim().isEmpty) return;
                      final text = _reactionController.text.trim();
                      _reactionController.clear();
                      Navigator.pop(context);
                      await _moodService.sendReactionToPartner(
                        partnerId,
                        null,
                        text,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã gửi lời nhắn!')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReactionHistoryModal(
    BuildContext context,
    String partnerId,
    String partnerName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Lịch sử thả tim hôm nay",
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<List<NotificationModel>>(
                  stream: NotificationService().getPartnerMoodReactionsToday(
                    partnerId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Đã xảy ra lỗi: ${snapshot.error}'),
                      );
                    }

                    final notifications = snapshot.data ?? [];
                    if (notifications.isEmpty) {
                      return Center(
                        child: Text(
                          "Chưa có tương tác nào hôm nay.",
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notif = notifications[index];
                        final timeString = DateFormat(
                          'HH:mm',
                        ).format(notif.createdAt);

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.pink[50],
                            backgroundImage:
                                notif.senderAvatar.isNotEmpty
                                    ? NetworkImage(notif.senderAvatar)
                                    : null,
                            child:
                                notif.senderAvatar.isEmpty
                                    ? Icon(
                                      Icons.favorite,
                                      color: Colors.pink[300],
                                      size: 16,
                                    )
                                    : null,
                          ),
                          title: Text(
                            notif.content,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            timeString,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPartnerMoodCard(
    UserModel? partner,
    DailyMoodSummary? partnerMood,
  ) {
    final partnerName = partner?.name.split(' ').last ?? 'Partner';

    // PRIVACY CHECK
    if (partner != null && !partner.shareMood) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline, size: 28, color: Colors.grey[400]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "$partnerName hiện không chia sẻ Mood",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (partnerMood == null || partnerMood.currentMood == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.nights_stay_outlined, size: 28, color: Colors.grey[400]),
            const SizedBox(width: 12),
            Text(
              "$partnerName chưa chia sẻ hôm nay",
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final moodType = partnerMood.currentMood!;
    final moodColor = MoodEntry.getColor(moodType);
    final moodLabel = MoodEntry.getLabel(moodType);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: moodColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: moodColor.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Smaller 3D Icon Container
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      MoodEntry.getIcon(moodType),
                      size: 48,
                      color: moodColor.withOpacity(0.2),
                    ),
                    Lottie.network(
                      MoodEntry.getLottieUrl(moodType),
                      fit: BoxFit.contain,
                      animate: true,
                      errorBuilder: (context, error, stack) => const SizedBox(),
                    ),
                  ],
                ),
              ).animate().scale(
                delay: 200.ms,
                duration: 400.ms,
                curve: Curves.easeOutBack,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$partnerName đang cảm thấy",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      moodLabel,
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: moodColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Write message button
              GestureDetector(
                onTap:
                    () =>
                        _showReactionSheet(partner!.uid, partnerName, moodType),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: moodColor.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.edit_note_rounded,
                    color: moodColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quick Emojis Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                ['❤️', '🫂', '✨', '💪', '🥰'].map((emoji) {
                  return GestureDetector(
                    onTap: () => _sendQuickEmoji(partner!.uid, emoji),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[100]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  );
                }).toList(),
          ).animate().slideY(begin: 0.2, end: 0, delay: 300.ms),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentUser.partnerId == null) return const SizedBox.shrink();

    return FutureBuilder<UserModel?>(
      future: _partnerFuture,
      builder: (context, partnerSnapshot) {
        if (partnerSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final partner = partnerSnapshot.data;
        final partnerName = partner?.name.split(' ').last ?? 'Partner';

        return StreamBuilder<DailyMoodSummary?>(
          stream: _partnerMoodStream,
          builder: (context, partnerMoodSnapshot) {
            final partnerMood = partnerMoodSnapshot.data;

            return Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Tâm trạng của $partnerName",
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const Icon(
                            Icons.favorite,
                            color: Colors.pink,
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _buildPartnerMoodCard(partner, partnerMood),

                      // In-app Reaction Display
                      StreamBuilder<DailyMoodSummary?>(
                        stream: _myMoodStream,
                        builder: (context, myMoodSnapshot) {
                          final myMood = myMoodSnapshot.data;

                          if (myMood != null &&
                              (myMood.partnerReaction != null ||
                                  myMood.partnerReactionText != null)) {
                            final hasText =
                                myMood.partnerReactionText != null &&
                                myMood.partnerReactionText!.isNotEmpty;

                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: GestureDetector(
                                onTap: () {
                                  _showReactionHistoryModal(
                                    context,
                                    partner!.uid,
                                    partnerName,
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors
                                            .pink[50], // Soft pink background for notifications
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.pink[100]!,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.pink[100],
                                        backgroundImage:
                                            partner?.photoUrl != null &&
                                                    partner!
                                                        .photoUrl!
                                                        .isNotEmpty
                                                ? NetworkImage(
                                                  partner.photoUrl!,
                                                )
                                                : null,
                                        child:
                                            partner?.photoUrl == null ||
                                                    partner!.photoUrl!.isEmpty
                                                ? Icon(
                                                  Icons.favorite,
                                                  color: Colors.pink[300],
                                                  size: 16,
                                                )
                                                : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          hasText
                                              ? "\"${myMood.partnerReactionText}\""
                                              : "${myMood.partnerReaction}",
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: Colors.pink[900],
                                            fontWeight: FontWeight.w500,
                                            fontStyle:
                                                hasText
                                                    ? FontStyle.italic
                                                    : FontStyle.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      if (!widget.currentUser.shareMood) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.visibility_off_outlined,
                                color: Colors.orange[800],
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Bạn đang không chia sẻ Mood với đối phương",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.orange[900],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(),
                      ],
                    ],
                  ),
                ).animate().fadeIn().moveY(begin: 10, end: 0),

                // Overlay for floating emojis
                ..._floatingEmojis,
              ],
            );
          },
        );
      },
    );
  }
}
