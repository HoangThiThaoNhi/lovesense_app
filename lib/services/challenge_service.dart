import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/challenge_model.dart';
import '../models/quiz_model.dart';
import '../models/quiz_attempt_model.dart';
// To update user XP

class ChallengeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // --- Challenges ---

  Stream<List<ChallengeModel>> getChallengesStream({String? type}) {
    Query query = _firestore
        .collection('challenges')
        .orderBy('endDate', descending: false);
    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ChallengeModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> createChallenge(ChallengeModel challenge) async {
    // Admin only
    await _firestore.collection('challenges').add(challenge.toMap());
  }

  // --- Quizzes ---

  Future<QuizModel?> getQuiz(String quizId) async {
    final doc =
        await _firestore
            .collection('content')
            .doc('quizzes')
            .collection('items')
            .doc(quizId)
            .get();
    if (doc.exists) {
      return QuizModel.fromFirestore(doc);
    }
    return null;
  }

  // --- Attempts ---

  Future<String> startQuiz(String quizId, {String? partnerId}) async {
    if (currentUserId == null) throw Exception("User not logged in");

    // Check for existing active attempt
    final existing =
        await _firestore
            .collection('quiz_attempts')
            .where('userId', isEqualTo: currentUserId)
            .where('quizId', isEqualTo: quizId)
            .where('completedAt', isNull: true)
            .limit(1)
            .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    // Create new
    final attemptRef = await _firestore.collection('quiz_attempts').add({
      'userId': currentUserId,
      'quizId': quizId,
      'startedAt': FieldValue.serverTimestamp(),
      'answers': {},
      'partnerId': partnerId,
      // If couple mode, might check for partner's existing attempt here to link 'partnerAttemptId'
    });
    return attemptRef.id;
  }

  Future<void> submitAnswer(
    String attemptId,
    String questionId,
    dynamic answer,
  ) async {
    await _firestore.collection('quiz_attempts').doc(attemptId).update({
      'answers.$questionId': answer,
    });
  }

  Future<QuizAttemptModel> completeQuiz(String attemptId) async {
    final docRef = _firestore.collection('quiz_attempts').doc(attemptId);
    final doc = await docRef.get();
    if (!doc.exists) throw Exception("Attempt not found");

    final attempt = QuizAttemptModel.fromFirestore(doc);
    if (attempt.isCompleted) return attempt; // Already done

    // Fetch quiz to calc score
    final quiz = await getQuiz(attempt.quizId);
    if (quiz == null) throw Exception("Quiz not found");

    int score = 0;

    // Logic to calc score based on question types
    for (var q in quiz.questions) {
      final answer = attempt.answers[q.id];
      if (answer != null) {
        if (q is MultipleChoiceQuestion) {
          if (answer == q.correctIndex) score += q.points;
        } else if (q is ScenarioOption) {
          // Scenario logic usually implies choosing an option that has a score
          // Simplifying: we need to find the option chosen.
        }
      }
    }

    // Update Attempt
    await docRef.update({
      'completedAt': FieldValue.serverTimestamp(),
      'score': score,
      'earnedXp': quiz.xpReward,
    });

    // Award XP to User
    if (currentUserId != null) {
      await _firestore.collection('users').doc(currentUserId).update({
        'xp': FieldValue.increment(quiz.xpReward),
        'completedQuizzes': FieldValue.increment(1),
      });
    }

    // Check Couple Sync
    if (attempt.partnerId != null) {
      await _checkCoupleCompatibility(attempt, quiz);
    }

    // Refresh attempt
    final updatedDoc = await docRef.get();
    return QuizAttemptModel.fromFirestore(updatedDoc);
  }

  Future<void> _checkCoupleCompatibility(
    QuizAttemptModel myAttempt,
    QuizModel quiz,
  ) async {
    // Find partner's attempt for same quiz
    final partnerAttempts =
        await _firestore
            .collection('quiz_attempts')
            .where('userId', isEqualTo: myAttempt.partnerId)
            .where('quizId', isEqualTo: quiz.id)
            .where('completedAt', isNull: false)
            .orderBy('completedAt', descending: true)
            .limit(1)
            .get();

    if (partnerAttempts.docs.isNotEmpty) {
      final partnerAttempt = QuizAttemptModel.fromFirestore(
        partnerAttempts.docs.first,
      );

      // Calculate Agreement Score (Simple logic: % of same answers for MC)
      int matches = 0;
      int total = 0;

      for (var q in quiz.questions) {
        if (q is MultipleChoiceQuestion || q is LikertQuestion) {
          total++;
          if (myAttempt.answers[q.id] == partnerAttempt.answers[q.id]) {
            matches++;
          }
        } else if (q is SliderQuestion) {
          total++;
          double diff =
              ((myAttempt.answers[q.id] ?? 0) -
                      (partnerAttempt.answers[q.id] ?? 0))
                  .abs();
          if (diff < 10) matches++; // Close enough
        }
      }

      double compatibility = total == 0 ? 0 : (matches / total) * 100;

      // Save to both attempts
      await _firestore.collection('quiz_attempts').doc(myAttempt.id).update({
        'partnerAttemptId': partnerAttempt.id,
        'compatibilityScore': compatibility,
      });
      await _firestore
          .collection('quiz_attempts')
          .doc(partnerAttempt.id)
          .update({
            'partnerAttemptId': myAttempt.id, // Mutual link
            'compatibilityScore': compatibility,
          });
    }
  }

  Stream<QuizAttemptModel?> getAttemptStream(String attemptId) {
    return _firestore
        .collection('quiz_attempts')
        .doc(attemptId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return QuizAttemptModel.fromFirestore(doc);
        });
  }
}
