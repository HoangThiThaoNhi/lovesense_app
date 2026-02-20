import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';

enum MoodType { terrible, sad, neutral, happy, awesome }

enum TimeSlot {
  morning, // 05:00 - 11:59
  afternoon, // 12:00 - 17:59
  evening; // 18:00 - 23:59

  String get label {
    switch (this) {
      case TimeSlot.morning:
        return 'Buổi sáng';
      case TimeSlot.afternoon:
        return 'Buổi chiều';
      case TimeSlot.evening:
        return 'Buổi tối';
    }
  }
}

class MoodEntry {
  final String id;
  final MoodType mood;
  final TimeSlot timeSlot;
  final DateTime timestamp;
  final String? note;
  final String? quote;

  MoodEntry({
    required this.id,
    required this.mood,
    required this.timeSlot,
    required this.timestamp,
    this.note,
    this.quote,
  });

  Map<String, dynamic> toJson() {
    return {
      'mood': mood.name,
      'timeSlot': timeSlot.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'note': note,
      'quote': quote,
    };
  }

  factory MoodEntry.fromJson(String id, Map<String, dynamic> json) {
    return MoodEntry(
      id: id,
      mood: MoodType.values.byName(json['mood']),
      timeSlot: TimeSlot.values.byName(json['timeSlot']),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      note: json['note'],
      quote: json['quote'],
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
      case MoodType.terrible:
        return Icons.sentiment_very_dissatisfied;
      case MoodType.sad:
        return Icons.sentiment_dissatisfied;
      case MoodType.neutral:
        return Icons.sentiment_neutral;
      case MoodType.happy:
        return Icons.sentiment_satisfied;
      case MoodType.awesome:
        return Icons.favorite;
    }
  }

  static Color getColor(MoodType type) {
    switch (type) {
      case MoodType.terrible:
        return Colors.grey;
      case MoodType.sad:
        return Colors.blueGrey;
      case MoodType.neutral:
        return Colors.amber;
      case MoodType.happy:
        return Colors.lightGreen;
      case MoodType.awesome:
        return Colors.pink;
    }
  }

  static String getLabel(MoodType type) {
    switch (type) {
      case MoodType.terrible:
        return 'Tệ';
      case MoodType.sad:
        return 'Buồn';
      case MoodType.neutral:
        return 'Bình thường';
      case MoodType.happy:
        return 'Vui';
      case MoodType.awesome:
        return 'Hạnh phúc';
    }
  }

  static String getRandomQuote(MoodType type) {
    final List<String> quotes;
    switch (type) {
      case MoodType.terrible:
        quotes = [
          'Hôm nay sống sót được thôi cũng đã đủ rồi.',
          'Bạn không cần mạnh mẽ vào những ngày như thế này.',
          'Có những lúc, mệt mỏi không cần lý do.',
          'Cảm xúc này không phải lỗi của bạn.',
          'Chậm lại một chút cũng không sao.',
        ];
        break;
      case MoodType.sad:
        quotes = [
          'Buồn không làm bạn yếu đi.',
          'Có lẽ hôm nay lòng bạn hơi nặng.',
          'Buồn cũng là một cách để cảm nhận.',
          'Cảm xúc này rồi sẽ trôi qua.',
          'Bạn không cần phải vui ngay.',
        ];
        break;
      case MoodType.neutral:
        quotes = [
          'Một ngày không quá tệ cũng đã ổn.',
          'Bình thường đôi khi chính là bình yên.',
          'Không có gì nổi bật, nhưng vẫn ổn.',
          'Ở giữa mọi thứ cũng là một trạng thái.',
          'Hôm nay trôi qua nhẹ nhàng.',
        ];
        break;
      case MoodType.happy:
        quotes = [
          'Hôm nay có gì đó dễ chịu.',
          'Một chút vui cũng đủ làm nhẹ lòng.',
          'Cảm giác này thật dễ thở.',
          'Có vẻ bạn đang ổn hơn rồi.',
          'Niềm vui nhỏ vẫn là niềm vui.',
        ];
        break;
      case MoodType.awesome:
        quotes = [
          'Khoảnh khắc này thật đáng trân trọng.',
          'Bạn đang toả ra năng lượng rất đẹp.',
          'Cảm giác này thật ấm.',
          'Hạnh phúc đang ở đây.',
          'Giữ lấy cảm xúc này nhé.',
        ];
        break;
    }
    return quotes[Random().nextInt(quotes.length)];
  }
}

class DailyMoodSummary {
  final String id; // Date YYYY-MM-DD
  final MoodType? currentMood;
  final String? quote; // Store the quote for the current mood
  final int editCount;
  final List<TimeSlot> slotsUsed;
  final DateTime? lastUpdatedAt;

  // Partner Reactions
  final String? partnerReaction;
  final String? partnerReactionText;

  DailyMoodSummary({
    required this.id,
    this.currentMood,
    this.quote,
    this.editCount = 0,
    this.slotsUsed = const [],
    this.lastUpdatedAt,
    this.partnerReaction,
    this.partnerReactionText,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentMood': currentMood?.name,
      'quote': quote,
      'editCount': editCount,
      'slotsUsed': slotsUsed.map((e) => e.name).toList(),
      'lastUpdatedAt':
          lastUpdatedAt != null ? Timestamp.fromDate(lastUpdatedAt!) : null,
      'partnerReaction': partnerReaction,
      'partnerReactionText': partnerReactionText,
    };
  }

  factory DailyMoodSummary.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return DailyMoodSummary(id: doc.id);
    }
    return DailyMoodSummary(
      id: doc.id,
      currentMood:
          data['currentMood'] != null
              ? MoodType.values.byName(data['currentMood'])
              : null,
      quote: data['quote'],
      editCount: data['editCount'] ?? 0,
      slotsUsed:
          (data['slotsUsed'] as List<dynamic>?)
              ?.map((e) => TimeSlot.values.byName(e))
              .toList() ??
          [],
      lastUpdatedAt: (data['lastUpdatedAt'] as Timestamp?)?.toDate(),
      partnerReaction: data['partnerReaction'],
      partnerReactionText: data['partnerReactionText'],
    );
  }
}
