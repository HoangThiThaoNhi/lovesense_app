
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum MoodType {
  terrible,
  sad,
  neutral,
  happy,
  awesome,
}

enum TimeSlot {
  morning,   // 05:00 - 11:59
  afternoon, // 12:00 - 17:59
  evening;   // 18:00 - 23:59

  String get label {
    switch (this) {
      case TimeSlot.morning: return 'Buổi sáng';
      case TimeSlot.afternoon: return 'Buổi chiều';
      case TimeSlot.evening: return 'Buổi tối';
    }
  }
}

class MoodEntry {
  final String id;
  final MoodType mood;
  final TimeSlot timeSlot;
  final DateTime timestamp;
  final String? note;

  MoodEntry({
    required this.id,
    required this.mood,
    required this.timeSlot,
    required this.timestamp,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'mood': mood.name,
      'timeSlot': timeSlot.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'note': note,
    };
  }

  factory MoodEntry.fromJson(String id, Map<String, dynamic> json) {
    return MoodEntry(
      id: id,
      mood: MoodType.values.byName(json['mood']),
      timeSlot: TimeSlot.values.byName(json['timeSlot']),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      note: json['note'],
    );
  }
  
  // Helper to get 3D/Animated Lottie URL (Using Google Noto Emojis for reliability)
  static String getLottieUrl(MoodType type) {
    switch (type) {
      case MoodType.terrible: 
        return 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f62d/lottie.json'; // Loudly Crying
      case MoodType.sad: 
        return 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f614/lottie.json'; // Pensive
      case MoodType.neutral: 
        return 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f610/lottie.json'; // Neutral
      case MoodType.happy: 
        return 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f600/lottie.json'; // Grinning
      case MoodType.awesome: 
        return 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f970/lottie.json'; // Heart Face
    }
  }

  static IconData getIcon(MoodType type) {
    switch (type) {
      case MoodType.terrible: return Icons.sentiment_very_dissatisfied;
      case MoodType.sad: return Icons.sentiment_dissatisfied;
      case MoodType.neutral: return Icons.sentiment_neutral;
      case MoodType.happy: return Icons.sentiment_satisfied;
      case MoodType.awesome: return Icons.favorite;
    }
  }

  static Color getColor(MoodType type) {
    switch (type) {
      case MoodType.terrible: return Colors.grey;
      case MoodType.sad: return Colors.blueGrey;
      case MoodType.neutral: return Colors.amber;
      case MoodType.happy: return Colors.lightGreen;
      case MoodType.awesome: return Colors.pink;
    }
  }
  
   static String getLabel(MoodType type) {
    switch (type) {
      case MoodType.terrible: return 'Tệ';
      case MoodType.sad: return 'Buồn';
      case MoodType.neutral: return 'Bình thường';
      case MoodType.happy: return 'Vui';
      case MoodType.awesome: return 'Hạnh phúc';
    }
  }
}

class DailyMoodSummary {
  final String id; // Date YYYY-MM-DD
  final MoodType? currentMood;
  final int editCount;
  final List<TimeSlot> slotsUsed;
  final DateTime? lastUpdatedAt;

  DailyMoodSummary({
    required this.id,
    this.currentMood,
    this.editCount = 0,
    this.slotsUsed = const [],
    this.lastUpdatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentMood': currentMood?.name,
      'editCount': editCount,
      'slotsUsed': slotsUsed.map((e) => e.name).toList(),
      'lastUpdatedAt': lastUpdatedAt != null ? Timestamp.fromDate(lastUpdatedAt!) : null,
    };
  }

  factory DailyMoodSummary.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return DailyMoodSummary(id: doc.id);
    }
    return DailyMoodSummary(
      id: doc.id,
      currentMood: data['currentMood'] != null ? MoodType.values.byName(data['currentMood']) : null,
      editCount: data['editCount'] ?? 0,
      slotsUsed: (data['slotsUsed'] as List<dynamic>?)
              ?.map((e) => TimeSlot.values.byName(e))
              .toList() ?? [],
      lastUpdatedAt: (data['lastUpdatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
