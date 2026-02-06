import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/quiz_model.dart';
import '../../services/admin_service.dart';

class AdminQuizView extends StatelessWidget {
  const AdminQuizView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text('Quản lý Quiz', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
               ElevatedButton.icon(
                 onPressed: () => _showCreateQuizDialog(context),
                 icon: const Icon(Icons.add_task),
                 label: const Text('Tạo Quiz Mới'),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.purple,
                   foregroundColor: Colors.white,
                 ),
               )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: AdminService().getQuizzesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) return const Center(child: Text("Chưa có quiz nào."));

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (c, i) => const Divider(),
                  itemBuilder: (context, index) {
                    final quiz = QuizModel.fromFirestore(docs[index]);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: quiz.type == QuizType.ranked ? Colors.amber : Colors.purple[100],
                        child: Icon(
                          quiz.type == QuizType.ranked ? Icons.emoji_events : Icons.quiz,
                          color: quiz.type == QuizType.ranked ? Colors.white : Colors.purple,
                        ),
                      ),
                      title: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${quiz.questions.length} câu hỏi • ${quiz.type == QuizType.ranked ? "Đua Top" : "Thường"}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => AdminService().deleteContent('quizzes', quiz.id), // Need to fix deleteContent arg logic
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
  final _coverUrlController = TextEditingController(); // Simplifying for now, url input
  bool _isRanked = false;
  
  List<Question> _questions = [];

  void _addQuestion() {
    showDialog(
      context: context,
      builder: (context) => _AddQuestionDialog(
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
      id: '', // Auto-gen
      title: _titleController.text,
      description: _descController.text,
      coverUrl: _coverUrlController.text,
      type: _isRanked ? QuizType.ranked : QuizType.standard,
      questions: _questions,
      startTime: _isRanked ? DateTime.now() : null, // Mock
    );

    // Manual implementation of addQuiz here since we didn't add it to AdminService yet
    await FirebaseFirestore.instance.collection('content').doc('quizzes').collection('items').add({
      'title': newQuiz.title,
      'description': newQuiz.description,
      'coverUrl': newQuiz.coverUrl,
      'type': _isRanked ? 'ranked' : 'standard',
      'questions': _questions.map((q) => {
        'question': q.question,
        'options': q.options,
        'correctIndex': q.correctIndex,
      }).toList(),
      'startTime': newQuiz.startTime,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tạo Quiz Mới'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Tên bộ câu hỏi')),
              TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Mô tả')),
              TextField(controller: _coverUrlController, decoration: const InputDecoration(labelText: 'Ảnh bìa (URL)')),
              SwitchListTile(
                title: const Text('Chế độ Đua Top (Ranked)'),
                value: _isRanked,
                onChanged: (v) => setState(() => _isRanked = v),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Danh sách câu hỏi (${_questions.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(onPressed: _addQuestion, icon: const Icon(Icons.add_circle, color: Colors.purple)),
                ],
              ),
              ..._questions.map((q) => ListTile(
                title: Text(q.question),
                subtitle: Text('Đúng: ${q.options[q.correctIndex]}'),
                dense: true,
              )),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
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
  final List<TextEditingController> _optionsControllers = List.generate(4, (_) => TextEditingController());
  int _correctIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm câu hỏi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _qController, decoration: const InputDecoration(labelText: 'Câu hỏi')),
          const SizedBox(height: 16),
          ...List.generate(4, (index) => Row(
            children: [
              Radio<int>(
                value: index, 
                groupValue: _correctIndex, 
                onChanged: (v) => setState(() => _correctIndex = v!)
              ),
              Expanded(
                child: TextField(
                  controller: _optionsControllers[index],
                  decoration: InputDecoration(labelText: 'Đáp án ${index + 1}'),
                ),
              ),
            ],
          )),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (_qController.text.isNotEmpty) {
              widget.onSave(Question(
                question: _qController.text,
                options: _optionsControllers.map((c) => c.text).toList(),
                correctIndex: _correctIndex,
              ));
              Navigator.pop(context);
            }
          },
          child: const Text('Thêm'),
        ),
      ],
    );
  }
}
