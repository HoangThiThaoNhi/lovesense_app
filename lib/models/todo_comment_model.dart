import 'package:cloud_firestore/cloud_firestore.dart';

class TodoCommentModel {
  final String id;
  final String text;
  final String senderId;
  final Timestamp timestamp;
  final bool isSystemMessage;

  TodoCommentModel({
    required this.id,
    required this.text,
    required this.senderId,
    required this.timestamp,
    this.isSystemMessage = false,
  });

  factory TodoCommentModel.fromMap(String id, Map<String, dynamic> data) {
    return TodoCommentModel(
      id: id,
      text: data['text'] ?? '',
      senderId: data['senderId'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      isSystemMessage: data['isSystemMessage'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'timestamp': timestamp,
      'isSystemMessage': isSystemMessage,
    };
  }
}
