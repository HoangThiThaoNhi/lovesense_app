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
  // Handles various answer types: int (index/likert), double (slide), String (text)
  final Map<int, dynamic> _userAnswers = {};
  bool _isSubmitted = false;
  int _score = 0;

  void _submitQuiz() {
    int score = 0;
    for (int i = 0; i < widget.quiz.questions.length; i++) {
      final q = widget.quiz.questions[i];
      if (q is MultipleChoiceQuestion) {
        if (_userAnswers[i] == q.correctIndex) score += q.points;
      } else if (q is ScenarioQuestion) {
        final index = _userAnswers[i] as int?;
        if (index != null && index >= 0 && index < q.options.length) {
          score += q.options[index].scoreImpact;
        }
      }
      // Others might just be data collection (Text, Likert) or subjective
      // We can add logic to score Likert if needed (e.g. positive alignment)
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
      return _buildResultScreen();
    }

    // Question Screen
    final question = widget.quiz.questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / widget.quiz.questions.length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.quiz.title,
          style: GoogleFonts.montserrat(color: Colors.black, fontSize: 16),
        ),
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
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              question.text,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 32),

            Expanded(
              child: SingleChildScrollView(child: _buildQuestionBody(question)),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _userAnswers[_currentQuestionIndex] == null
                        ? null
                        : () {
                          if (_currentQuestionIndex <
                              widget.quiz.questions.length - 1) {
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Text(
                  _currentQuestionIndex < widget.quiz.questions.length - 1
                      ? "Tiếp theo"
                      : "Hoàn thành",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionBody(Question q) {
    if (q is MultipleChoiceQuestion) {
      return Column(
        children: List.generate(q.options.length, (index) {
          final isSelected = _userAnswers[_currentQuestionIndex] == index;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap:
                  () => setState(
                    () => _userAnswers[_currentQuestionIndex] = index,
                  ),
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
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: isSelected ? Colors.purple : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        q.options[index],
                        style: GoogleFonts.inter(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      );
    } else if (q is SliderQuestion) {
      double currentValue =
          (_userAnswers[_currentQuestionIndex] as double?) ?? q.min;
      return Column(
        children: [
          Slider(
            value: currentValue,
            min: q.min,
            max: q.max,
            divisions: q.divisions > 0 ? q.divisions : 10,
            label: currentValue.toStringAsFixed(1),
            onChanged:
                (v) => setState(() => _userAnswers[_currentQuestionIndex] = v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                q.minLabel ?? "${q.min}",
                style: const TextStyle(color: Colors.grey),
              ),
              Text(
                q.maxLabel ?? "${q.max}",
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "Giá trị: ${currentValue.toStringAsFixed(1)}",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
        ],
      );
    } else if (q is LikertQuestion) {
      int? selected = _userAnswers[_currentQuestionIndex] as int?;
      return Column(
        children: List.generate(q.scale, (i) {
          final val = i + 1; // 1-based
          final isSelected = selected == val;
          String label = "";
          if (val == 1) label = "Hoàn toàn không đồng ý";
          if (val == q.scale) label = "Hoàn toàn đồng ý";

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap:
                  () =>
                      setState(() => _userAnswers[_currentQuestionIndex] = val),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.purple[50] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.purple : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          isSelected ? Colors.purple : Colors.grey[200],
                      child: Text(
                        "$val",
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(label.isNotEmpty ? label : "Mức độ $val"),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      );
    } else if (q is ScenarioQuestion) {
      int? selectedIndex = _userAnswers[_currentQuestionIndex] as int?;
      return Column(
        children: List.generate(q.options.length, (index) {
          final opt = q.options[index];
          final isSelected = selectedIndex == index;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap:
                  () => setState(
                    () => _userAnswers[_currentQuestionIndex] = index,
                  ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[50] : Colors.white,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(opt.text, style: const TextStyle(fontSize: 16)),
                    if (isSelected && opt.feedback.isNotEmpty) ...[
                      const Divider(),
                      Text(
                        "💡 ${opt.feedback}",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      );
    } else if (q is TextQuestion) {
      return TextField(
        onChanged: (v) => _userAnswers[_currentQuestionIndex] = v,
        decoration: const InputDecoration(
          hintText: "Nhập câu trả lời của bạn...",
          border: OutlineInputBorder(),
        ),
        maxLines: 4,
      );
    }
    return const Text("Unknown Question Type");
  }

  Widget _buildResultScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Kết quả",
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
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
              "$_score", // Using generic score
              style: GoogleFonts.montserrat(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            // Simple AI Coach Message Mockup
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Text(
                    "🤖 AI Coach",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Bạn đã làm rất tốt! Hãy tiếp tục duy trì thói quen này để cải thiện trí tuệ cảm xúc của mình.",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hoàn thành"),
            ),
          ],
        ),
      ),
    );
  }
}
