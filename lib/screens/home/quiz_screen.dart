import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/quiz_model.dart';

class QuizScreen extends StatefulWidget {
  final QuizModel quiz;

  const QuizScreen({super.key, required this.quiz});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int _score = 0;
  bool _answered = false;
  int? _selectedOptionIndex;
  
  @override
  Widget build(BuildContext context) {
    final question = widget.quiz.questions[_currentIndex];
    final totalQuestions = widget.quiz.questions.length;
    final progress = (_currentIndex + 1) / totalQuestions;

    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5), // Light purple bg
      appBar: AppBar(
        title: Text(
          widget.quiz.title,
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white,
              color: Colors.purpleAccent,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            Text(
              "Câu ${_currentIndex + 1}/$totalQuestions",
              style: GoogleFonts.inter(
                color: Colors.purple[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            // Question
            Text(
              question.question,
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ).animate().fadeIn().slideX(),
            const SizedBox(height: 32),

            // Options
            ...List.generate(question.options.length, (index) {
              final option = question.options[index];
              return _buildOption(index, option, question.correctIndex);
            }),

            const Spacer(),

            // Next Button
            if (_answered)
              ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6200EA),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _currentIndex < totalQuestions - 1 ? 'Tiếp theo' : 'Hoàn thành',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ).animate().scale(),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(int index, String text, int correctIndex) {
    Color borderColor = Colors.transparent;
    Color bgColor = Colors.white;
    IconData? icon;

    if (_answered) {
      if (index == correctIndex) {
        borderColor = Colors.green;
        bgColor = Colors.green.withOpacity(0.1);
        icon = Icons.check_circle;
      } else if (index == _selectedOptionIndex) {
        borderColor = Colors.red;
        bgColor = Colors.red.withOpacity(0.1);
        icon = Icons.cancel;
      }
    } else if (index == _selectedOptionIndex) {
      borderColor = Colors.purple;
      bgColor = Colors.purple.withOpacity(0.05);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: _answered ? null : () {
          setState(() {
            _selectedOptionIndex = index;
            _answered = true;
            if (index == correctIndex) {
              _score++;
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(
              color: borderColor == Colors.transparent ? Colors.white : borderColor, 
              width: 2
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (icon != null)
                Icon(icon, color: borderColor),
            ],
          ),
        ),
      ),
    );
  }

  void _nextQuestion() {
    if (_currentIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _answered = false;
        _selectedOptionIndex = null;
      });
    } else {
      _showResult();
    }
  }

  void _showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Kết quả"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Bạn trả lời đúng", style: GoogleFonts.inter(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              "$_score / ${widget.quiz.questions.length}",
              style: GoogleFonts.montserrat(
                fontSize: 32, 
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            if (widget.quiz.type == QuizType.ranked) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              if (_score == widget.quiz.questions.length)
                Text(
                  "🏆 Tuyệt vời! Bạn nhận được ${widget.quiz.reward ?? 'quà'}",
                  style: GoogleFonts.inter(color: Colors.orange[800], fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                )
              else 
                 Text(
                  "Hãy cố gắng lần sau để nhận quà nhé!",
                  style: GoogleFonts.inter(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
            ]
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Hoàn thành", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
