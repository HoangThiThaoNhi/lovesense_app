import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/quiz_model.dart';
import '../../models/challenge_model.dart';
import 'package:uuid/uuid.dart';

class ChallengeSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  Future<void> seedChallenges() async {
    // 1. Daily Emotion Check-in (Quiz + Challenge)
    final dailyQuizId = _uuid.v4();
    await _createQuiz(
      QuizModel(
        id: dailyQuizId,
        title: "Daily EQ Check",
        description: "How are you feeling today?",
        coverUrl:
            "https://images.unsplash.com/photo-1518020382113-a7e8fc38eac9",
        type: QuizType.standard,
        mode: QuizMode.individual,
        difficulty: "Easy",
        questions: [
          SliderQuestion(
            id: _uuid.v4(),
            text: "How is your energy level?",
            min: 1,
            max: 10,
            minLabel: "Low",
            maxLabel: "High",
          ),
          LikertQuestion(
            id: _uuid.v4(),
            text: "I felt connected to my partner today.",
            scale: 5,
          ),
          TextQuestion(id: _uuid.v4(), text: "One thing you are grateful for?"),
        ],
        xpReward: 50,
      ),
    );

    await _createChallenge(
      ChallengeModel(
        id: _uuid.v4(),
        title: "Daily Emotion Check-in",
        description: "Take 2 mins to reflect on your day.",
        coverUrl:
            "https://images.unsplash.com/photo-1518020382113-a7e8fc38eac9?w=500",
        type: ChallengeType.daily,
        difficulty: "Easy",
        endDate: DateTime.now().add(const Duration(hours: 24)),
        xpReward: 50,
        quizId: dailyQuizId,
      ),
    );

    // 2. Weekly Relationship Quiz (Scenario)
    final weeklyQuizId = _uuid.v4();
    await _createQuiz(
      QuizModel(
        id: weeklyQuizId,
        title: "Conflict Resolution Master",
        description: "Test your skills in resolving arguments.",
        coverUrl:
            "https://images.unsplash.com/photo-1573497620053-ea5300f94f21",
        type: QuizType.ranked,
        mode: QuizMode.couple,
        difficulty: "Hard",
        questions: [
          ScenarioQuestion(
            id: _uuid.v4(),
            text: "Your partner forgot your anniversary. How do you react?",
            options: [
              ScenarioOption(
                text: "Silent treatment until they remember.",
                scoreImpact: 0,
                feedback: "This creates distance.",
              ),
              ScenarioOption(
                text:
                    "Calmly express disappointment and ask for a make-up dinner.",
                scoreImpact: 10,
                feedback: "Excellent use of 'I' statements.",
              ),
              ScenarioOption(
                text: "Yell at them immediately.",
                scoreImpact: -5,
                feedback: "Aggression escalates conflict.",
              ),
            ],
          ),
          MultipleChoiceQuestion(
            id: _uuid.v4(),
            text: "What is the key to active listening?",
            options: [
              "Interrupting to solve",
              "Nodding but looking at phone",
              "Reflecting back what you heard",
              "Preparing your counter-argument",
            ],
            correctIndex: 2,
            points: 20,
          ),
        ],
        isRanked: true,
        xpReward: 200,
      ),
    );

    await _createChallenge(
      ChallengeModel(
        id: _uuid.v4(),
        title: "Conflict Resolution Master",
        description: "Weekly ranked challenge for couples.",
        coverUrl:
            "https://images.unsplash.com/photo-1573497620053-ea5300f94f21?w=500",
        type: ChallengeType.weekly,
        difficulty: "Hard",
        endDate: DateTime.now().add(const Duration(days: 7)),
        xpReward: 200,
        quizId: weeklyQuizId,
      ),
    );
  }

  Future<void> _createQuiz(QuizModel quiz) async {
    await _firestore
        .collection('content')
        .doc('quizzes')
        .collection('items')
        .doc(quiz.id)
        .set(quiz.toMap());
  }

  Future<void> _createChallenge(ChallengeModel challenge) async {
    await _firestore
        .collection('challenges')
        .doc(challenge.id)
        .set(challenge.toMap());
  }
}
