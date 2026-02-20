enum RequestType { coupleInvite, creatorApplication }

enum RequestStatus { pending, accepted, rejected }

class RequestModel {
  final String id;
  final String fromUid;
  final String toUid; // 'admin' for creator applications
  final RequestType type;
  final RequestStatus status;
  final DateTime createdAt;
  final String? message;
  final Map<String, dynamic>? data;

  // Sender Info (Joined for UI convenience, usually fetched separate)
  final String? senderName;
  final String? senderAvatar;
  final String? senderUsername;

  RequestModel({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.type,
    this.status = RequestStatus.pending,
    required this.createdAt,
    this.message,
    this.data,
    this.senderName,
    this.senderAvatar,
    this.senderUsername,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUid': fromUid,
      'toUid': toUid,
      'type': type.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'message': message,
      'data': data,
    };
  }

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['id'] ?? '',
      fromUid: json['fromUid'] ?? '',
      toUid: json['toUid'] ?? '',
      type: RequestType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RequestType.coupleInvite,
      ),
      status: RequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RequestStatus.pending,
      ),
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      message: json['message'],
      data: json['data'],
    );
  }

  RequestModel copyWith({
    String? id,
    String? fromUid,
    String? toUid,
    RequestType? type,
    RequestStatus? status,
    DateTime? createdAt,
    String? message,
    Map<String, dynamic>? data,
    String? senderName,
    String? senderAvatar,
    String? senderUsername,
  }) {
    return RequestModel(
      id: id ?? this.id,
      fromUid: fromUid ?? this.fromUid,
      toUid: toUid ?? this.toUid,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      message: message ?? this.message,
      data: data ?? this.data,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      senderUsername: senderUsername ?? this.senderUsername,
    );
  }
}
