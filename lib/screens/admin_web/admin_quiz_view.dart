import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../models/quiz_model.dart';
import '../../services/admin_service.dart';
import '../../services/seed_challenges.dart' as challenge_seeder;

class AdminQuizView extends StatelessWidget {
  const AdminQuizView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quản lý Quiz',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await challenge_seeder.ChallengeSeeder().seedChallenges();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Seeded Challenges & Quizzes!"),
                        ),
                      );
                    },
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text("Seed Data"),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateQuizDialog(context),
                    icon: const Icon(Icons.add_task),
                    label: const Text('Tạo Quiz Mới'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: AdminService().getQuizzesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text("Chưa có quiz nào."));
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (c, i) => const Divider(),
                  itemBuilder: (context, index) {
                    final quiz = QuizModel.fromFirestore(docs[index]);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            quiz.type == QuizType.ranked
                                ? Colors.amber
                                : Colors.purple[100],
                        child: Icon(
                          quiz.type == QuizType.ranked
                              ? Icons.emoji_events
                              : Icons.quiz,
                          color:
                              quiz.type == QuizType.ranked
                                  ? Colors.white
                                  : Colors.purple,
                        ),
                      ),
                      title: Text(
                        quiz.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${quiz.questions.length} câu hỏi • ${quiz.type == QuizType.ranked ? "Đua Top" : "Thường"}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => AdminService().deleteQuiz(quiz.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateQuizDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _CreateQuizDialog(),
    );
  }
}

class _CreateQuizDialog extends StatefulWidget {
  const _CreateQuizDialog();

  @override
  State<_CreateQuizDialog> createState() => _CreateQuizDialogState();
}

class _CreateQuizDialogState extends State<_CreateQuizDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _coverUrlController = TextEditingController();
  bool _isRanked = false;

  final List<Question> _questions = [];

  void _addQuestion() {
    showDialog(
      context: context,
      builder:
          (context) => _AddQuestionDialog(
            onSave: (q) {
              setState(() {
                _questions.add(q);
              });
            },
          ),
    );
  }

  Future<void> _saveQuiz() async {
    if (_titleController.text.isEmpty || _questions.isEmpty) return;

    final newQuiz = QuizModel(
      id: '',
      title: _titleController.text,
      description: _descController.text,
      coverUrl: _coverUrlController.text,
      type: _isRanked ? QuizType.ranked : QuizType.standard,
      mode: QuizMode.individual, // Default for manual creation for now
      difficulty: 'Easy', // Default for manual creation for now
      questions: _questions,
      startTime: _isRanked ? DateTime.now() : null,
    );

    // Save to Firestore
    await FirebaseFirestore.instance
        .collection('content')
        .doc('quizzes')
        .collection('items')
        .add(newQuiz.toMap()..remove('id'));

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tạo Quiz Mới'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Tên bộ câu hỏi'),
              ),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Mô tả'),
              ),
              TextField(
                controller: _coverUrlController,
                decoration: const InputDecoration(labelText: 'Ảnh bìa (URL)'),
              ),
              SwitchListTile(
                title: const Text('Chế độ Đua Top (Ranked)'),
                value: _isRanked,
                onChanged: (v) => setState(() => _isRanked = v),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Danh sách câu hỏi (${_questions.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add_circle, color: Colors.purple),
                  ),
                ],
              ),
              ..._questions.map((q) {
                // Polymorphic Display
                String subtitle = '';
                if (q is MultipleChoiceQuestion) {
                  subtitle = 'TRẮC NGHIỆM: ${q.options.length} lựa chọn';
                } else if (q is SliderQuestion) {
                  subtitle = 'SLIDER: ${q.min} - ${q.max}';
                } else if (q is LikertQuestion) {
                  subtitle = 'LIKERT: ${q.scale} levels';
                } else if (q is ScenarioQuestion) {
                  subtitle = 'TÌNH HUỐNG: ${q.options.length} lựa chọn';
                } else {
                  subtitle = 'TỰ DO';
                }

                return ListTile(
                  title: Text(q.text),
                  subtitle: Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  dense: true,
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(onPressed: _saveQuiz, child: const Text('Lưu Quiz')),
      ],
    );
  }
}

class _AddQuestionDialog extends StatefulWidget {
  final Function(Question) onSave;
  const _AddQuestionDialog({required this.onSave});

  @override
  State<_AddQuestionDialog> createState() => _AddQuestionDialogState();
}

class _AddQuestionDialogState extends State<_AddQuestionDialog> {
  final _qController = TextEditingController();
  QuestionType _selectedType = QuestionType.multipleChoice;

  // Multiple Choice
  final List<TextEditingController> _optionsControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  int _correctIndex = 0;

  // Slider
  double _min = 0;
  double _max = 10;
  final _minLabelController = TextEditingController(text: 'Thấp');
  final _maxLabelController = TextEditingController(text: 'Cao');

  // Likert
  int _likertScale = 5;

  // Scenario
  final List<ScenarioOption> _scenarioOptions = [];

  void _addScenarioOption() {
    showDialog(
      context: context,
      builder:
          (context) => _AddScenarioOptionDialog(
            onSave: (opt) {
              setState(() => _scenarioOptions.add(opt));
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm câu hỏi'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButton<QuestionType>(
                value: _selectedType,
                isExpanded: true,
                items:
                    QuestionType.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.name.toUpperCase()),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _qController,
                decoration: const InputDecoration(
                  labelText: 'Nội dung câu hỏi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Dynamic Fields based on Type
              if (_selectedType == QuestionType.multipleChoice) ...[
                const Text(
                  "Các lựa chọn:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...List.generate(
                  4,
                  (index) => Row(
                    children: [
                      Radio<int>(
                        value: index,
                        groupValue: _correctIndex,
                        onChanged: (v) => setState(() => _correctIndex = v!),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _optionsControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Đáp án ${index + 1}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_selectedType == QuestionType.slider) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _min.toString(),
                        decoration: const InputDecoration(labelText: 'Min'),
                        onChanged: (v) => _min = double.tryParse(v) ?? 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: _max.toString(),
                        decoration: const InputDecoration(labelText: 'Max'),
                        onChanged: (v) => _max = double.tryParse(v) ?? 10,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minLabelController,
                        decoration: const InputDecoration(
                          labelText: 'Nhãn Min',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _maxLabelController,
                        decoration: const InputDecoration(
                          labelText: 'Nhãn Max',
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (_selectedType == QuestionType.likert) ...[
                DropdownButtonFormField<int>(
                  initialValue: _likertScale,
                  items:
                      [3, 5, 7]
                          .map(
                            (i) => DropdownMenuItem(
                              value: i,
                              child: Text('$i điểm'),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _likertScale = v!),
                  decoration: const InputDecoration(
                    labelText: 'Thang đo Likert',
                  ),
                ),
              ] else if (_selectedType == QuestionType.scenario) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Lựa chọn tình huống:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: _addScenarioOption,
                      icon: const Icon(Icons.add),
                      label: const Text("Thêm Opt"),
                    ),
                  ],
                ),
                ..._scenarioOptions.map(
                  (o) => ListTile(
                    title: Text(o.text),
                    subtitle: Text("Impact: ${o.scoreImpact}"),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        setState(() => _scenarioOptions.remove(o));
                      },
                    ),
                  ),
                ),
              ] else if (_selectedType == QuestionType.text) ...[
                const Text(
                  "Người dùng sẽ nhập câu trả lời tự do.",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (_qController.text.isNotEmpty) {
              final id = const Uuid().v4();
              Question q;
              switch (_selectedType) {
                case QuestionType.multipleChoice:
                  q = MultipleChoiceQuestion(
                    id: id,
                    text: _qController.text,
                    options: _optionsControllers.map((c) => c.text).toList(),
                    correctIndex: _correctIndex,
                  );
                  break;
                case QuestionType.slider:
                  q = SliderQuestion(
                    id: id,
                    text: _qController.text,
                    min: _min,
                    max: _max,
                    minLabel: _minLabelController.text,
                    maxLabel: _maxLabelController.text,
                  );
                  break;
                case QuestionType.likert:
                  q = LikertQuestion(
                    id: id,
                    text: _qController.text,
                    scale: _likertScale,
                  );
                  break;
                case QuestionType.scenario:
                  q = ScenarioQuestion(
                    id: id,
                    text: _qController.text,
                    options: _scenarioOptions,
                  );
                  break;
                case QuestionType.text:
                  q = TextQuestion(id: id, text: _qController.text);
                  break;
              }
              widget.onSave(q);
              Navigator.pop(context);
            }
          },
          child: const Text('Thêm'),
        ),
      ],
    );
  }
}

class _AddScenarioOptionDialog extends StatefulWidget {
  final Function(ScenarioOption) onSave;
  const _AddScenarioOptionDialog({required this.onSave});
  @override
  State<_AddScenarioOptionDialog> createState() =>
      _AddScenarioOptionDialogState();
}

class _AddScenarioOptionDialogState extends State<_AddScenarioOptionDialog> {
  final _textCtrl = TextEditingController();
  final _feedbackCtrl = TextEditingController();
  int _impact = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Thêm lựa chọn tình huống"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _textCtrl,
            decoration: const InputDecoration(labelText: "Nội dung lựa chọn"),
          ),
          TextField(
            controller: _feedbackCtrl,
            decoration: const InputDecoration(labelText: "Phản hồi (Feedback)"),
          ),
          TextFormField(
            initialValue: _impact.toString(),
            decoration: const InputDecoration(labelText: "Điểm tác động (+/-)"),
            keyboardType: TextInputType.number,
            onChanged: (v) => _impact = int.tryParse(v) ?? 0,
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (_textCtrl.text.isNotEmpty) {
              widget.onSave(
                ScenarioOption(
                  text: _textCtrl.text,
                  feedback: _feedbackCtrl.text,
                  scoreImpact: _impact,
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text("Lưu"),
        ),
      ],
    );
  }
}
