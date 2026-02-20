import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _notifications =>
      _firestore.collection('notifications');
  CollectionReference get _users => _firestore.collection('users');

  /// Send a notification to a specific user
  Future<void> sendNotification({
    required String targetUserId,
    required NotificationType type,
    required String content,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Fetch sender info for display
    final senderDoc = await _users.doc(uid).get();
    if (!senderDoc.exists) return;
    final senderData = senderDoc.data() as Map<String, dynamic>;
    final senderName = senderData['name'] ?? 'Partner';
    final senderAvatar = senderData['photoUrl'] ?? '';

    final newNotifRef = _notifications.doc();
    final notif = NotificationModel(
      id: newNotifRef.id,
      receiverId: targetUserId,
      senderId: uid,
      senderName: senderName,
      senderAvatar: senderAvatar,
      type: type,
      content: content,
      createdAt: DateTime.now(),
      isRead: false,
    );

    await newNotifRef.set(notif.toJson());
  }

  /// Get stream of notifications for the current user
  Stream<List<NotificationModel>> getMyNotifications() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _notifications.where('receiverId', isEqualTo: uid).snapshots().map((
      snapshot,
    ) {
      final docs =
          snapshot.docs
              .map(
                (doc) => NotificationModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();

      // Sort chronologically (newest first)
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Limit to recent 50 locally
      if (docs.length > 50) {
        return docs.sublist(0, 50);
      }
      return docs;
    });
  }

  /// Get stream of partner's mood reactions for today
  Stream<List<NotificationModel>> getPartnerMoodReactionsToday(
    String partnerId,
  ) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    final todayStart = DateTime.now().copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
    );

    return _notifications.where('receiverId', isEqualTo: uid).snapshots().map((
      snapshot,
    ) {
      final docs =
          snapshot.docs
              .map(
                (doc) => NotificationModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              // Lọc theo memory để né lỗi bắt buộc tạo Index của Firebase
              .where(
                (notif) =>
                    notif.senderId == partnerId &&
                    notif.type == NotificationType.moodReaction &&
                    notif.createdAt.isAfter(todayStart),
              )
              .toList();

      // Lọc CHỈ LẤY những tin nhắn là chữ (những cái có prefix [TEXT])
      final textOnlyDocs =
          docs
              .where((notif) {
                return notif.content.startsWith('[TEXT]');
              })
              .map((notif) {
                // Bỏ đi cái tiền tố [TEXT] để hiển thị ra UI cho đẹp
                return notif.copyWith(
                  content: notif.content.replaceFirst('[TEXT] ', ''),
                );
              })
              .toList();

      // Sort chronologically (newest to oldest)
      textOnlyDocs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return textOnlyDocs;
    });
  }

  /// Get stream of unread notification count
  Stream<int> getUnreadCount() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    return _notifications
        .where('receiverId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark a specific notification as read
  Future<void> markAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'isRead': true});
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final unreadQuery =
        await _notifications
            .where('receiverId', isEqualTo: uid)
            .where('isRead', isEqualTo: false)
            .get();

    final batch = _firestore.batch();
    for (var doc in unreadQuery.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
