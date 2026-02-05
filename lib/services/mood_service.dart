
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mood_model.dart';
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
       return {'allowed': false, 'reason': 'Chưa đến giờ điểm danh sáng (05:00)'};
     }

     if (summary == null) {
       return {'allowed': true}; // No data for today yet, and it's past 5am, so valid.
     }

     // Rule 2: Max 3 edits
     if (summary.editCount >= 3) {
       return {'allowed': false, 'reason': 'Bạn đã dùng hết 3 lượt check-in hôm nay'};
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
          'reason': 'Bạn đã check-in ${currentSlot.label} rồi. Hẹn bạn vào $nextSlotName nhé!',
          'currentMood': summary.currentMood
        };
     }
     
     return {'allowed': true};
  }

  // Check Eligibility (Async - Deprecated or for double check)
  Future<Map<String, dynamic>> checkEligibility() async {
    if (_currentUserId.isEmpty) return {'allowed': false, 'reason': 'Chưa đăng nhập'};

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
         return {'allowed': false, 'reason': 'Chưa đến giờ điểm danh sáng (05:00)'};
       }
       return {'allowed': true};
    }

    final summary = DailyMoodSummary.fromSnapshot(snapshot);
    final currentSlot = getCurrentTimeSlot();

    // Rule 2: Max 3 edits
    if (summary.editCount >= 3) {
      return {'allowed': false, 'reason': 'Bạn đã dùng hết 3 lượt check-in hôm nay'};
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
         'reason': 'Bạn đã check-in ${currentSlot.label} rồi. Hẹn bạn vào $nextSlotName nhé!',
         'currentMood': summary.currentMood // To show current state
       };
    }
    
    // Initial check regarding strict hours (e.g. 00:00 - 05:00 not allowed)
    final hour = DateTime.now().hour;
    if (hour < 5) {
       return {'allowed': false, 'reason': 'Chưa đến giờ điểm danh sáng (05:00)'};
    }

    return {'allowed': true};
  }

  // Get stream for real-time UI updates
  Stream<DailyMoodSummary> getDailySummaryStream() {
    if (_currentUserId.isEmpty) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('daily_moods')
        .doc(_todayDocId)
        .snapshots()
        .map((doc) => DailyMoodSummary.fromSnapshot(doc));
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
    // 1. Pre-validation
    final snapshotPre = await userMoodRef.get();
    DailyMoodSummary? summaryPre;
    if (snapshotPre.exists) {
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
    if (summaryPre == null || !snapshotPre.exists) {
      summary = DailyMoodSummary(id: todayId);
    } else {
      summary = summaryPre;
    }

    // Rules Re-verification (Soft check)
    if (summary.editCount >= 3) throw Exception("Đã hết lượt check-in hôm nay");
    if (summary.slotsUsed.contains(currentSlot)) throw Exception("Khung giờ này đã check-in rồi");

    // Update Summary
    final updatedSlots = List<TimeSlot>.from(summary.slotsUsed)..add(currentSlot);
    final updatedSummary = DailyMoodSummary(
      id: todayId,
      currentMood: mood,
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
    );
    
    batch.set(historyRef, entry.toJson());

    await batch.commit();
  }
}
