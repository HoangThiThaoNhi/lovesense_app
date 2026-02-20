import 'package:cloud_firestore/cloud_firestore.dart';

enum Gender { male, female, other, notDisclosed }

enum UserStatus { active, suspended, softDeleted }

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'single', 'couple', 'creator', 'admin'
  final DateTime createdAt;

  // Extended Profile Fields
  final String? username;
  final String? phoneNumber;
  final Gender gender;
  final DateTime? dateOfBirth;
  final String? photoUrl;
  final String? coverUrl;
  final String? bio;
  final String? coupleCode; // New field for pairing

  // Relationship
  final String? partnerId; // Link to partner
  final DateTime? coupleStartDate;

  // Gamification & System
  final int accountLevel;
  final int points;
  final UserStatus status;

  // Privacy Settings
  final bool showStatus;
  final bool
  showPrivateInfo; // Hides personal info (dob, gender, etc) from others

  // System
  final DateTime? lastUsernameChangeAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.role = 'single',
    required this.createdAt,
    this.username,
    this.phoneNumber,
    this.gender = Gender.notDisclosed,
    this.dateOfBirth,
    this.photoUrl,
    this.coverUrl,
    this.bio,
    this.coupleCode,
    this.partnerId,
    this.coupleStartDate,
    this.accountLevel = 1,
    this.points = 0,
    this.status = UserStatus.active,
    this.showStatus = true,
    this.showPrivateInfo = true,
    this.shareMood = true,
    this.shareDiary = true,
    this.shareQuiz = true,
    this.lastUsernameChangeAt,
  });

  // Partner Sharing Settings
  final bool shareMood;
  final bool shareDiary;
  final bool shareQuiz;

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'username': username,
      'phoneNumber': phoneNumber,
      'gender': gender.name,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'photoUrl': photoUrl,
      'coverUrl': coverUrl,
      'bio': bio,
      'coupleCode': coupleCode,
      'partnerId': partnerId,
      'coupleStartDate': coupleStartDate?.toIso8601String(),
      'accountLevel': accountLevel,
      'points': points,
      'status': status.name,
      'showStatus': showStatus,
      'showPrivateInfo': showPrivateInfo,
      'lastUsernameChangeAt': lastUsernameChangeAt?.toIso8601String(),
      'shareMood': shareMood,
      'shareDiary': shareDiary,
      'shareQuiz': shareQuiz,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      if (date is int) return DateTime.fromMillisecondsSinceEpoch(date);
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic date) {
      if (date == null) return null;
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date);
      if (date is int) return DateTime.fromMillisecondsSinceEpoch(date);
      return null;
    }

    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'single',
      createdAt: parseDate(json['createdAt']),
      username: json['username'],
      phoneNumber: json['phoneNumber'],
      gender: Gender.values.firstWhere(
        (e) => e.name == json['gender'],
        orElse: () => Gender.notDisclosed,
      ),
      dateOfBirth: parseNullableDate(json['dateOfBirth']),
      photoUrl: json['photoUrl'],
      coverUrl: json['coverUrl'],
      bio: json['bio'],
      coupleCode: json['coupleCode'],
      partnerId: json['partnerId'],
      accountLevel: json['accountLevel'] ?? 1,
      points: json['points'] ?? 0,
      status: UserStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => UserStatus.active,
      ),
      showStatus: json['showStatus'] ?? true,
      showPrivateInfo: json['showPrivateInfo'] ?? true,
      lastUsernameChangeAt: parseNullableDate(json['lastUsernameChangeAt']),
      shareMood: json['shareMood'] ?? true,
      shareDiary: json['shareDiary'] ?? true,
      shareQuiz: json['shareQuiz'] ?? true,
      coupleStartDate: parseNullableDate(json['coupleStartDate']),
    );
  }
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }
}
