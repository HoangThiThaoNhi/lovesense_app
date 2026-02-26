import 'package:cloud_firestore/cloud_firestore.dart';

enum PillarType { myGrowth, together, forUs }

enum GoalStatus { active, archived }

class GoalModel {
  final String id;
  final PillarType pillar;
  final String title;
  final GoalStatus status;
  final DateTime createdAt;
  final String ownerId;

  // --- Research & Advanced Tracking Fields ---
  final String? category;
  final String?
  duration; // e.g. "2_weeks", "1_month", "3_months", "custom", "unlimited"
  final DateTime? startDate;
  final DateTime? endDate;
  final String
  successMeasurement; // "task_based", "streak", "self_rating", "combined"
  final int? baselineScore;
  final bool requiresPartnerConfirmation;
  final String partnerStatus; // "pending", "active", "declined"
  final String visibility; // "both", "only_me"
  final String?
  commitmentLevel; // "Cùng thảo luận", "Cam kết thực hiện", "Mục tiêu chính của năm"
  final String? participationMode; // "both", "split", "flexible"
  final int? partnerBaselineScore;
  final List<String> completedBy;
  final int? targetCount;
  final String? streakType; // "both", "any", "individual"
  final int? targetScore;

  GoalModel({
    required this.id,
    required this.pillar,
    required this.title,
    this.status = GoalStatus.active,
    required this.createdAt,
    this.ownerId = '',
    // Advanced fields with defaults
    this.category,
    this.duration,
    this.startDate,
    this.endDate,
    this.successMeasurement = 'task_based',
    this.baselineScore,
    this.requiresPartnerConfirmation = false,
    this.partnerStatus = 'active',
    this.visibility = 'both',
    this.commitmentLevel,
    this.participationMode,
    this.partnerBaselineScore,
    this.completedBy = const [],
    this.targetCount,
    this.streakType,
    this.targetScore,
  });

  Map<String, dynamic> toMap() {
    return {
      'pillar': pillar.name,
      'title': title,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'ownerId': ownerId,
      // Advanced fields
      'category': category,
      'duration': duration,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'successMeasurement': successMeasurement,
      'baselineScore': baselineScore,
      'requiresPartnerConfirmation': requiresPartnerConfirmation,
      'partnerStatus': partnerStatus,
      'visibility': visibility,
      'commitmentLevel': commitmentLevel,
      'participationMode': participationMode,
      'partnerBaselineScore': partnerBaselineScore,
      'completedBy': completedBy,
      'targetCount': targetCount,
      'streakType': streakType,
      'targetScore': targetScore,
    };
  }

  factory GoalModel.fromMap(
    String id,
    Map<String, dynamic> map, {
    String ownerId = '',
  }) {
    return GoalModel(
      id: id,
      pillar: PillarType.values.firstWhere(
        (e) => e.name == map['pillar'],
        orElse: () => PillarType.myGrowth,
      ),
      title: map['title'] ?? '',
      status: GoalStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => GoalStatus.active,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ownerId: ownerId.isNotEmpty ? ownerId : (map['ownerId'] ?? ''),
      category: map['category'],
      duration: map['duration'],
      startDate: (map['startDate'] as Timestamp?)?.toDate(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
      successMeasurement: map['successMeasurement'] ?? 'task_based',
      baselineScore: map['baselineScore'],
      requiresPartnerConfirmation: map['requiresPartnerConfirmation'] ?? false,
      partnerStatus: map['partnerStatus'] ?? 'active',
      visibility: map['visibility'] ?? 'both',
      commitmentLevel: map['commitmentLevel'],
      participationMode: map['participationMode'] ?? (map['pillar'] == PillarType.together.name ? 'both' : null),
      partnerBaselineScore: map['partnerBaselineScore'],
      completedBy: List<String>.from(map['completedBy'] ?? []),
      targetCount: map['targetCount'],
      streakType: map['streakType'],
      targetScore: map['targetScore'],
    );
  }
}
