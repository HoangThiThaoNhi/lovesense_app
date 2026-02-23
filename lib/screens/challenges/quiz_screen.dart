import 'package:flutter/material.dart';
import '../../models/quiz_model.dart';
import '../../services/challenge_service.dart';
import 'package:google_fonts/google_fonts.dart';

class QuizScreen extends StatefulWidget {
  final String quizId;
  const QuizScreen({super.key, required this.quizId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final ChallengeService _service = ChallengeService();
  QuizModel? _quiz;
  String? _attemptId;

  bool _isLoading = true;
  int _currentIndex = 0;

  // Local state for current answers before submission
  final Map<String, dynamic> _currentAnswers = {};

  @override
  void initState() {
    super.initState();
    _initQuiz();
  }

  Future<void> _initQuiz() async {
    _quiz = await _service.getQuiz(widget.quizId);
    if (_quiz != null) {
      // Start Attempt
      _attemptId = await _service.startQuiz(
        widget.quizId,
      ); // Add partner logic here if needed
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _answerQuestion(String qId, dynamic value) {
    setState(() {
      _currentAnswers[qId] = value;
    });
    // Async save
    if (_attemptId != null) {
      _service.submitAnswer(_attemptId!, qId, value);
    }
  }

  void _next() {
    if (_currentIndex < _quiz!.questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    setState(() => _isLoading = true);
    if (_attemptId != null) {
      await _service.completeQuiz(_attemptId!);
    }
    if (mounted) {
      Navigator.pop(context); // Go back to list, or replace with Result Screen
      // Navigate to Result Screen (TODO)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Quiz Completed! +XP")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_quiz == null) {
      return const Scaffold(body: Center(child: Text("Quiz not found")));
    }

    final question = _quiz!.questions[_currentIndex];
    final progress = (_currentIndex + 1) / _quiz!.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_quiz!.title),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation(Colors.purple),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Question Counter
            Text(
              "Question ${_currentIndex + 1}/${_quiz!.questions.length}",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),

            // Question Text
            Text(
              question.text,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Dynamic Content
            Expanded(child: _buildQuestionContent(question)),

            // Nav
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed:
                    _currentAnswers.containsKey(question.id) ? _next : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF673AB7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _currentIndex == _quiz!.questions.length - 1
                      ? "FINISH"
                      : "NEXT",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionContent(Question q) {
    // Polymorphic UI
    if (q is MultipleChoiceQuestion) {
      return ListView.separated(
        itemCount: q.options.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, idx) {
          final isSelected = _currentAnswers[q.id] == idx;
          return InkWell(
            onTap: () => _answerQuestion(q.id, idx),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.purple[50] : Colors.white,
                border: Border.all(
                  color: isSelected ? Colors.purple : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor:
                        isSelected ? Colors.purple : Colors.grey[300],
                    child:
                        isSelected
                            ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                            : null,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    q.options[idx],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else if (q is SliderQuestion) {
      final val = _currentAnswers[q.id] ?? q.min;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(q.minLabel ?? ''),
              Text(
                val.toStringAsFixed(0),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.purple,
                ),
              ),
              Text(q.maxLabel ?? ''),
            ],
          ),
          Slider(
            value: (val as num).toDouble(),
            min: q.min,
            max: q.max,
            divisions: q.divisions,
            label: val.round().toString(),
            onChanged: (v) => _answerQuestion(q.id, v),
          ),
        ],
      );
    } else if (q is LikertQuestion) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            spacing: 12,
            children: List.generate(q.scale, (index) {
              final val = index + 1;
              final isSelected = _currentAnswers[q.id] == val;
              return GestureDetector(
                onTap: () => _answerQuestion(q.id, val),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      isSelected ? Colors.purple : Colors.grey[200],
                  child: Text(
                    val.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text("Disagree"), Text("Agree")],
          ),
        ],
      );
    } else if (q is TextQuestion) {
      return TextField(
        onChanged: (v) => _answerQuestion(q.id, v),
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: "Type your answer...",
          border: OutlineInputBorder(),
        ),
      );
    }

    return const Center(child: Text("Unknown Question Type"));
  }
}
