import 'package:flutter/material.dart';
import '../../models/lesson_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLessonEditScreen extends StatefulWidget {
  final String courseId;
  final LessonModel? lesson;

  const AdminLessonEditScreen({super.key, required this.courseId, this.lesson});

  @override
  State<AdminLessonEditScreen> createState() => _AdminLessonEditScreenState();
}

class _AdminLessonEditScreenState extends State<AdminLessonEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _contentCtrl; // For text or URL
  late TextEditingController _durationCtrl;
  late TextEditingController _orderCtrl;

  // Mode Specific
  late TextEditingController _reflectionCtrl;
  late TextEditingController _coupleTaskCtrl;

  LessonType _type = LessonType.text;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.lesson?.title ?? '');
    _descCtrl = TextEditingController(text: widget.lesson?.description ?? '');
    _contentCtrl = TextEditingController(
      text:
          widget.lesson?.type == LessonType.text
              ? widget.lesson?.contentText
              : widget.lesson?.contentUrl ?? '',
    );
    _durationCtrl = TextEditingController(
      text: widget.lesson?.estimatedMinutes.toString() ?? '15',
    );
    _orderCtrl = TextEditingController(
      text: widget.lesson?.order.toString() ?? '1',
    );

    _reflectionCtrl = TextEditingController(
      text: widget.lesson?.reflectionQuestion ?? '',
    );
    _coupleTaskCtrl = TextEditingController(
      text: widget.lesson?.coupleActionTask ?? '',
    );

    _type = widget.lesson?.type ?? LessonType.text;
  }

  Future<void> _saveLesson() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final lessonData = LessonModel(
        id: widget.lesson?.id ?? '', // ID handled by add/set
        courseId: widget.courseId,
        title: _titleCtrl.text,
        description: _descCtrl.text,
        type: _type,
        contentUrl: _type != LessonType.text ? _contentCtrl.text : '',
        contentText: _type == LessonType.text ? _contentCtrl.text : '',
        order: int.tryParse(_orderCtrl.text) ?? 1,
        estimatedMinutes: int.tryParse(_durationCtrl.text) ?? 15,
        reflectionQuestion:
            _reflectionCtrl.text.isEmpty ? null : _reflectionCtrl.text,
        coupleActionTask:
            _coupleTaskCtrl.text.isEmpty ? null : _coupleTaskCtrl.text,
      );

      final collection = _firestore
          .collection('content')
          .doc('courses')
          .collection('items')
          .doc(widget.courseId)
          .collection('lessons');

      if (widget.lesson == null) {
        // Create new with auto-ID (or use a constructed ID if needed, but auto is fine for lessons)
        final doc = collection.doc(); // Generate ID
        // Reconstruct with ID
        final newLesson = LessonModel(
          id: doc.id,
          courseId: lessonData.courseId,
          title: lessonData.title,
          description: lessonData.description,
          type: lessonData.type,
          contentUrl: lessonData.contentUrl,
          contentText: lessonData.contentText,
          order: lessonData.order,
          estimatedMinutes: lessonData.estimatedMinutes,
          reflectionQuestion: lessonData.reflectionQuestion,
          coupleActionTask: lessonData.coupleActionTask,
        );
        await doc.set(newLesson.toMap());
      } else {
        await collection.doc(widget.lesson!.id).update(lessonData.toMap());
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson == null ? 'Thêm Bài học' : 'Sửa Bài học'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề bài học',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Nhập tiêu đề' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _orderCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Thứ tự',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _durationCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Phút',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mô tả ngắn',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Type Selector
              DropdownButtonFormField<LessonType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Loại bài học',
                  border: OutlineInputBorder(),
                ),
                items:
                    LessonType.values
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.name.toUpperCase()),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 16),

              // Content Area
              if (_type == LessonType.text)
                TextFormField(
                  controller: _contentCtrl,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    labelText: 'Nội dung văn bản (Markdown supported)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                )
              else
                TextFormField(
                  controller: _contentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL Video/Audio',
                    border: OutlineInputBorder(),
                  ),
                ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // Specific Fields
              const Text(
                "Nội dung tương tác (Tùy chọn)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextFormField(
                  controller: _reflectionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Câu hỏi suy ngẫm (Cho Individual Mode)',
                    hintText: 'Vd: Bạn cảm thấy thế nào về...',
                    border: InputBorder.none,
                  ),
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.pink[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextFormField(
                  controller: _coupleTaskCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nhiệm vụ Cặp đôi (Cho Couple Mode)',
                    hintText: 'Vd: Hãy cùng nhau thực hiện...',
                    border: InputBorder.none,
                  ),
                  maxLines: 2,
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveLesson,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF673AB7),
                    foregroundColor: Colors.white,
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator()
                          : const Text("Lưu Bài học"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
