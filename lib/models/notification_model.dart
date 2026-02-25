import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { moodReaction, goalInvitation, goalUpdated, goalDeleted, other }

class NotificationModel {
  final String id;
  final String receiverId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final NotificationType type;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.receiverId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.type,
    required this.content,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receiverId': receiverId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'type': type.name,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      receiverId: json['receiverId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderAvatar: json['senderAvatar'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.other,
      ),
      content: json['content'] ?? '',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      isRead: json['isRead'] ?? false,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? receiverId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    NotificationType? type,
    String? content,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      receiverId: receiverId ?? this.receiverId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      type: type ?? this.type,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
