import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/quiz_model.dart';

class QuizPlayerScreen extends StatefulWidget {
  final QuizModel quiz;

  const QuizPlayerScreen({super.key, required this.quiz});

  @override
  State<QuizPlayerScreen> createState() => _QuizPlayerScreenState();
}

class _QuizPlayerScreenState extends State<QuizPlayerScreen> {
  int _currentQuestionIndex = 0;
  Map<int, int> _userAnswers = {}; // questionIndex -> selectedOptionIndex
  bool _isSubmitted = false;
  int _score = 0;

  void _submitQuiz() {
    int score = 0;
    for (int i = 0; i < widget.quiz.questions.length; i++) {
      if (_userAnswers[i] == widget.quiz.questions[i].correctIndex) {
        score++;
      }
    }
    setState(() {
      _isSubmitted = true;
      _score = score;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quiz.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.quiz.title)),
        body: const Center(child: Text("Quiz này chưa có câu hỏi nào.")),
      );
    }

    // Result Screen
    if (_isSubmitted) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text("Kết quả", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
              const SizedBox(height: 24),
              Text(
                "Bạn đạt được",
                style: GoogleFonts.inter(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                "$_score / ${widget.quiz.questions.length}",
                style: GoogleFonts.montserrat(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 32),
              if (widget.quiz.hasReward && _score == widget.quiz.questions.length)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.pink[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.pink[100]!),
                  ),
                  child: Column(
                    children: [
                      const Text("🎉 Chúc mừng!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink)),
                      const SizedBox(height: 4),
                      Text("Phần thưởng: ${widget.quiz.rewardDescription}", textAlign: TextAlign.center),
                    ],
                  ),
                ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text("Hoàn thành"),
              ),
            ],
          ),
        ),
      );
    }

    // Question Screen
    final question = widget.quiz.questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / widget.quiz.questions.length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.quiz.title, style: GoogleFonts.montserrat(color: Colors.black, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Câu ${_currentQuestionIndex + 1}",
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.purple),
            ),
            const SizedBox(height: 12),
            Text(
              question.question,
              style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 32),
            ...List.generate(question.options.length, (index) {
              final isSelected = _userAnswers[_currentQuestionIndex] == index;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _userAnswers[_currentQuestionIndex] = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.purple[50] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.purple : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.purple : Colors.grey[400]!,
                              width: 2
                            ),
                            color: isSelected ? Colors.purple : null,
                          ),
                          child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Text(question.options[index], style: GoogleFonts.inter(fontSize: 16))),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _userAnswers[_currentQuestionIndex] == null
                    ? null
                    : () {
                        if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
                          setState(() {
                            _currentQuestionIndex++;
                          });
                        } else {
                          _submitQuiz();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF673AB7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Text(
                  _currentQuestionIndex < widget.quiz.questions.length - 1 ? "Tiếp theo" : "Hoàn thành",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
