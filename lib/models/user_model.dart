class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'single', 'couple', 'creator', 'admin'
  final DateTime createdAt;
  final String status;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.role = 'single',
    required this.createdAt,
    this.status = 'active',
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'single',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      status: json['status'] ?? 'active',
    );
  }
}
