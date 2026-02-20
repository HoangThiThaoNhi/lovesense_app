import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mood_model.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';

class MoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helpers
  String get _currentUserId => _auth.currentUser?.uid ?? '';
  String get _todayDocId => DateFormat('yyyy-MM-dd').format(DateTime.now());

  TimeSlot getCurrentTimeSlot() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return TimeSlot.morning;
    if (hour >= 12 && hour < 18) return TimeSlot.afternoon;
    return TimeSlot.evening;
  }

  // Check Eligibility (Synchonous - Fast)
  Map<String, dynamic> checkEligibilityLocal(DailyMoodSummary? summary) {
    final currentSlot = getCurrentTimeSlot();
    final hour = DateTime.now().hour;

    // Rule: strict start time
    if (hour < 5) {
      return {
        'allowed': false,
        'reason': 'Chưa đến giờ điểm danh sáng (05:00)',
      };
    }

    if (summary == null) {
      return {
        'allowed': true,
      }; // No data for today yet, and it's past 5am, so valid.
    }

    // Rule 2: Max 3 edits
    if (summary.editCount >= 3) {
      return {
        'allowed': false,
        'reason': 'Bạn đã dùng hết 3 lượt check-in hôm nay',
      };
    }

    // Rule 3: One per slot
    if (summary.slotsUsed.contains(currentSlot)) {
      // Find next slot name
      String nextSlotName = '';
      if (currentSlot == TimeSlot.morning) nextSlotName = 'Buổi chiều (12:00)';
      if (currentSlot == TimeSlot.afternoon) nextSlotName = 'Buổi tối (18:00)';
      if (currentSlot == TimeSlot.evening) nextSlotName = 'Ngày mai';

      return {
        'allowed': false,
        'reason':
            'Bạn đã check-in ${currentSlot.label} rồi. Hẹn bạn vào $nextSlotName nhé!',
        'currentMood': summary.currentMood,
      };
    }

    return {'allowed': true};
  }

  // Check Eligibility (Async - Deprecated or for double check)
  Future<Map<String, dynamic>> checkEligibility() async {
    if (_currentUserId.isEmpty) {
      return {'allowed': false, 'reason': 'Chưa đăng nhập'};
    }

    final docRef = _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('daily_moods')
        .doc(_todayDocId);

    final snapshot = await docRef.get();

    // Default valid state if no data yet
    if (!snapshot.exists) {
      final hour = DateTime.now().hour;
      // Prevent editing before 5AM? (Rule 3 says Morning starts 5:00)
      if (hour < 5) {
        return {
          'allowed': false,
          'reason': 'Chưa đến giờ điểm danh sáng (05:00)',
        };
      }
      return {'allowed': true};
    }

    final summary = DailyMoodSummary.fromSnapshot(snapshot);
    final currentSlot = getCurrentTimeSlot();

    // Rule 2: Max 3 edits
    if (summary.editCount >= 3) {
      return {
        'allowed': false,
        'reason': 'Bạn đã dùng hết 3 lượt check-in hôm nay',
      };
    }

    // Rule 3: One per slot
    if (summary.slotsUsed.contains(currentSlot)) {
      // Find next slot name
      String nextSlotName = '';
      if (currentSlot == TimeSlot.morning) nextSlotName = 'Buổi chiều (12:00)';
      if (currentSlot == TimeSlot.afternoon) nextSlotName = 'Buổi tối (18:00)';
      if (currentSlot == TimeSlot.evening) nextSlotName = 'Ngày mai';

      return {
        'allowed': false,
        'reason':
            'Bạn đã check-in ${currentSlot.label} rồi. Hẹn bạn vào $nextSlotName nhé!',
        'currentMood': summary.currentMood, // To show current state
      };
    }

    // Initial check regarding strict hours (e.g. 00:00 - 05:00 not allowed)
    final hour = DateTime.now().hour;
    if (hour < 5) {
      return {
        'allowed': false,
        'reason': 'Chưa đến giờ điểm danh sáng (05:00)',
      };
    }

    return {'allowed': true};
  }

  // Get stream for real-time UI updates
  Stream<DailyMoodSummary?> getDailySummaryStream() {
    if (_currentUserId.isEmpty) return Stream.value(null);
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('daily_moods')
        .doc(_todayDocId)
        .snapshots()
        .map((doc) => doc.exists ? DailyMoodSummary.fromSnapshot(doc) : null);
  }

  // Get Partner's Mood Stream
  Stream<DailyMoodSummary?> getPartnerTodayMoodStream(String partnerId) {
    if (partnerId.isEmpty) return Stream.value(null);
    return _firestore
        .collection('users')
        .doc(partnerId)
        .collection('daily_moods')
        .doc(_todayDocId)
        .snapshots()
        .map((doc) => doc.exists ? DailyMoodSummary.fromSnapshot(doc) : null);
  }

  // Send a light reaction to partner's mood
  Future<void> sendReactionToPartner(
    String partnerId,
    String? emoji,
    String? text,
  ) async {
    if (_currentUserId.isEmpty || partnerId.isEmpty) return;

    final todayId = _todayDocId;
    final partnerMoodRef = _firestore
        .collection('users')
        .doc(partnerId)
        .collection('daily_moods')
        .doc(todayId);

    // Make sure we only add reaction if the partner actually has a mood doc
    final docSnap = await partnerMoodRef.get();
    if (docSnap.exists) {
      await partnerMoodRef.update({
        'partnerReaction': emoji,
        'partnerReactionText': text,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });
      // Send notification with prefixes so we can easily filter them later.
      final String notifContent =
          emoji != null ? '[EMOJI] đã gửi $emoji' : '[TEXT] $text';
      await NotificationService().sendNotification(
        targetUserId: partnerId,
        type: NotificationType.moodReaction,
        content: notifContent,
      );
    }
  }

  // Log Mood
  Future<void> logMood(MoodType mood, {String? note}) async {
    if (_currentUserId.isEmpty) return;

    final todayId = _todayDocId;
    final userMoodRef = _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('daily_moods')
        .doc(todayId);

    // 1. Pre-transaction validation (Read-only) to fail fast and avoid "Transaction Aborted" errors
    // This fixes the "Dart exception thrown from converted Future" on Web
    // 1. Pre-transaction validation (Read-only)
    // Fix: Offline Fallback
    DailyMoodSummary? summaryPre;
    DocumentSnapshot<Map<String, dynamic>>? snapshotPre;

    try {
      // Try Server first (or default)
      snapshotPre = await userMoodRef.get();
    } catch (e) {
      try {
        // Fallback to Cache
        snapshotPre = await userMoodRef.get(
          const GetOptions(source: Source.cache),
        );
      } catch (_) {
        // Totally offline and no cache? Assume empty/new day.
        summaryPre = null;
      }
    }

    if (snapshotPre != null && snapshotPre.exists) {
      summaryPre = DailyMoodSummary.fromSnapshot(snapshotPre);
    }

    // Use the sync check we already wrote
    final eligibility = checkEligibilityLocal(summaryPre);
    if (eligibility['allowed'] == false) {
      throw Exception(eligibility['reason']);
    }

    final now = DateTime.now();
    final currentSlot = getCurrentTimeSlot();

    // 2. Flexible Write (Batch - Supports Offline/Flaky Network)
    // We switched from runTransaction (Strict) to Batch to avoid "unavailable" errors
    final batch = _firestore.batch();

    // We already have summaryPre from step 1.
    // If it was null (new day), create it.
    DailyMoodSummary summary;
    // Fix lint: snapshotPre can be null now
    if (summaryPre == null || snapshotPre?.exists != true) {
      summary = DailyMoodSummary(id: todayId);
    } else {
      summary = summaryPre;
    }

    // Rules Re-verification (Soft check)
    if (summary.editCount >= 3) throw Exception("Đã hết lượt check-in hôm nay");
    if (summary.slotsUsed.contains(currentSlot)) {
      throw Exception("Khung giờ này đã check-in rồi");
    }

    // Generate Quote
    final quote = MoodEntry.getRandomQuote(mood);

    // Update Summary
    final updatedSlots = List<TimeSlot>.from(summary.slotsUsed)
      ..add(currentSlot);
    final updatedSummary = DailyMoodSummary(
      id: todayId,
      currentMood: mood,
      quote: quote, // Save the quote
      editCount: summary.editCount + 1,
      slotsUsed: updatedSlots,
      lastUpdatedAt: now,
    );

    batch.set(userMoodRef, updatedSummary.toJson());

    // Add History (Sub-collection)
    final historyRef = userMoodRef.collection('history').doc();
    final entry = MoodEntry(
      id: historyRef.id,
      mood: mood,
      timeSlot: currentSlot,
      timestamp: now,
      note: note,
      quote: quote, // Save the quote in history too
    );

    batch.set(historyRef, entry.toJson());

    await batch.commit();
  }
}
