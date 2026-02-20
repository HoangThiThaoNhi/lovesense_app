import 'package:cloud_firestore/cloud_firestore.dart';

class PolicyModel {
  final String id; // e.g., 'terms_of_use', 'privacy_policy'
  final String title;
  final String content; // Markdown formatted
  final DateTime updatedAt;

  PolicyModel({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PolicyModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PolicyModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      updatedAt:
          data['updatedAt'] != null
              ? DateTime.parse(data['updatedAt'])
              : DateTime.now(),
    );
  }
}
