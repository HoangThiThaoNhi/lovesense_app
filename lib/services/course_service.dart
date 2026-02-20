import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';
import '../models/course_progress_model.dart';

class CourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  CollectionReference get _coursesRef => _firestore.collection('courses');
  CollectionReference get _progressRef =>
      _firestore.collection('user_course_progress');
  CollectionReference get _coupleProgressRef =>
      _firestore.collection('couple_course_progress');

  // --- COURSES ---

  Stream<List<CourseModel>> getCoursesStream({
    String? targetAudience,
    String? tag,
  }) {
    Query query = _coursesRef.where('isApproved', isEqualTo: true);

    if (targetAudience != null && targetAudience != 'Both') {
      // If user is 'Individual', show 'Individual' AND 'Both'
      // Firestore IN query limited to 10
      query = query.where('targetAudience', whereIn: [targetAudience, 'Both']);
    }

    if (tag != null) {
      query = query.where('tags', arrayContains: tag);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CourseModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<CourseModel?> getCourse(String courseId) async {
    final doc = await _coursesRef.doc(courseId).get();
    if (!doc.exists) return null;
    return CourseModel.fromFirestore(doc);
  }

  // --- LESSONS ---

  Stream<List<LessonModel>> getLessonsStream(String courseId) {
    return _coursesRef
        .doc(courseId)
        .collection('lessons')
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => LessonModel.fromFirestore(doc))
              .toList();
        });
  }

  // --- INDIVIDUAL PROGRESS ---

  Stream<UserCourseProgress?> getUserProgressStream(String courseId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);

    return _progressRef
        .where('userId', isEqualTo: uid)
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return UserCourseProgress.fromFirestore(snapshot.docs.first);
        });
  }

  Future<void> startCourse(String courseId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final progressToCheck =
        await _progressRef
            .where('userId', isEqualTo: uid)
            .where('courseId', isEqualTo: courseId)
            .limit(1)
            .get();

    if (progressToCheck.docs.isEmpty) {
      await _progressRef.add({
        'userId': uid,
        'courseId': courseId,
        'completedLessonIds': [],
        'journalEntries': {},
        'progressPercent': 0.0,
        'updatedAt': FieldValue.serverTimestamp(),
        'isCompleted': false,
      });
    }
  }

  Future<void> completeLesson({
    required String courseId,
    required String lessonId,
    required int totalLessons,
    String? journalEntry,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final snapshot =
        await _progressRef
            .where('userId', isEqualTo: uid)
            .where('courseId', isEqualTo: courseId)
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) {
      // Should have started, but auto-start just in case
      await startCourse(courseId);
      return completeLesson(
        courseId: courseId,
        lessonId: lessonId,
        totalLessons: totalLessons,
        journalEntry: journalEntry,
      );
    }

    final docRef = snapshot.docs.first.reference;
    final currentProgress = UserCourseProgress.fromFirestore(
      snapshot.docs.first,
    );

    // Avoid duplicates
    if (!currentProgress.completedLessonIds.contains(lessonId)) {
      final newCompleted = List<String>.from(currentProgress.completedLessonIds)
        ..add(lessonId);
      final newPercent = (newCompleted.length / totalLessons).clamp(0.0, 1.0);

      // Update
      await docRef.update({
        'completedLessonIds': FieldValue.arrayUnion([lessonId]),
        if (journalEntry != null) 'journalEntries.$lessonId': journalEntry,
        'progressPercent': newPercent,
        'updatedAt': FieldValue.serverTimestamp(),
        'isCompleted': newPercent >= 1.0,
      });
    } else if (journalEntry != null) {
      // Just updating journal for existing lesson
      await docRef.update({
        'journalEntries.$lessonId': journalEntry,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // --- COUPLE PROGRESS ---
  // (Assuming CoupleID is derived or stored. For now, we query by both UserIDs)

  Stream<CoupleCourseProgress?> getCoupleProgressStream(
    String courseId,
    String partnerId,
  ) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);

    // This query depends on how we store the ID.
    // Ideally we have a 'coupleId'.
    // Fallback: Query where user1 == me OR user2 == me, AND courseId matches.

    // Simplification for MVP: We assume we can find it.
    // Better approach: Store coupleId in User model? Or just search.

    return _coupleProgressRef
        .where('courseId', isEqualTo: courseId)
        .where(
          'userIds',
          arrayContains: uid,
        ) // Requires a helper field 'userIds' array in doc
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          // Match partner?
          // For now just return the first one found for this course and user.
          return CoupleCourseProgress.fromFirestore(snapshot.docs.first);
        });
  }
}
