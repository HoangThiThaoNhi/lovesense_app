import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/goal_model.dart';
import '../../../services/goal_todo_service.dart';

class CreateGoalBottomSheet extends StatefulWidget {
  final PillarType pillar;
  final VoidCallback onGoalCreated;

  const CreateGoalBottomSheet({
    super.key,
    required this.pillar,
    required this.onGoalCreated,
  });

  @override
  State<CreateGoalBottomSheet> createState() => _CreateGoalBottomSheetState();
}

class _CreateGoalBottomSheetState extends State<CreateGoalBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _goalService = GoalTodoService();

  // Form values
  final _titleController = TextEditingController();
  String? _selectedCategory;
  String _selectedDuration = '1 tháng'; // Default value matches list
  DateTime? _startDate = DateTime.now();
  DateTime? _endDate;
  String _successMeasurement = 'task_based';
  int _baselineScore = 3;
  bool _requiresPartnerConfirmation = false;
  String? _commitmentLevel;
  bool _autoSuggestTasks = true;

  bool _isLoading = false;

  final Map<PillarType, List<String>> _categoriesMap = {
    PillarType.myGrowth: [
      'Emotional Control',
      'Self Improvement',
      'Discipline',
      'Learning',
      'Custom',
    ],
    PillarType.together: [
      'Communication',
      'Conflict Resolution',
      'Quality Time',
      'Trust',
      'Emotional Support',
      'Custom',
    ],
    PillarType.forUs: [
      'Financial Planning',
      'Marriage Planning',
      'Family Plan',
      'Living Arrangement',
      'Long-term Vision',
      'Custom',
    ],
  };

  final List<String> _durations = [
    '2 tuần',
    '1 tháng',
    '3 tháng',
    'Tùy chỉnh',
    'Không giới hạn',
  ];

  final List<String> _commitments = [
    'Cùng thảo luận',
    'Cam kết thực hiện',
    'Mục tiêu chính của năm',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn danh mục')));
      return;
    }

    if (widget.pillar == PillarType.forUs && _commitmentLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn mức cam kết')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final goal = GoalModel(
        id: '',
        pillar: widget.pillar,
        title: _titleController.text.trim(),
        createdAt: DateTime.now(),
        category: _selectedCategory,
        duration: _selectedDuration,
        startDate: _startDate,
        endDate: _endDate,
        successMeasurement: _successMeasurement,
        baselineScore:
            _successMeasurement == 'self_rating' ? _baselineScore : null,
        requiresPartnerConfirmation:
            widget.pillar != PillarType.myGrowth
                ? _requiresPartnerConfirmation
                : false,
        partnerStatus:
            (widget.pillar != PillarType.myGrowth &&
                    _requiresPartnerConfirmation)
                ? 'pending'
                : 'active',
        visibility: 'both', // Deprecated by user spec, keeping default
        commitmentLevel:
            widget.pillar == PillarType.forUs ? _commitmentLevel : null,
      );

      await _goalService.createGoal(goal, autoSuggestTasks: _autoSuggestTasks);

      if (mounted) {
        widget.onGoalCreated();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tạo Mục tiêu thành công! 🌱')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // PHẦN 1 - HEADER
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PHẦN 2 - GOAL INFORMATION
                      _buildTitleField(),
                      const SizedBox(height: 24),
                      _buildCategoryField(),
                      const SizedBox(height: 24),
                      _buildDurationField(),
                      const SizedBox(height: 32),

                      // PHẦN 3 - MEASUREMENT SECTION
                      _buildMeasurementField(),

                      if (_successMeasurement == 'self_rating') ...[
                        const SizedBox(height: 16),
                        _buildBaselineRating(),
                      ],
                      const SizedBox(height: 32),

                      // PHẦN 4 - CONDITIONAL SECTION
                      _buildConditionalSection(),
                      const SizedBox(height: 32),

                      // PHẦN 5 - ACTION BUTTONS
                      _buildActions(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String title = '';
    String subtext = '';
    IconData icon = Icons.star;

    switch (widget.pillar) {
      case PillarType.myGrowth:
        title = 'Mục tiêu phát triển cá nhân';
        subtext = 'Bạn muốn cải thiện điều gì ở bản thân?';
        icon = Icons.psychology; // Closest to 🌱 in standard icons without text
        break;
      case PillarType.together:
        title = 'Mục tiêu cùng nhau';
        subtext = 'Hai bạn muốn cải thiện điều gì trong mối quan hệ?';
        icon = Icons.handshake;
        break;
      case PillarType.forUs:
        title = 'Mục tiêu tương lai chung';
        subtext = 'Hai bạn đang hướng đến điều gì dài hạn?';
        icon = Icons.home;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: _getColorForPillar(), size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtext,
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: "Tên mục tiêu ",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            children: const [
              TextSpan(text: "*", style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          maxLength: 80,
          decoration: InputDecoration(
            hintText: 'Nhập mục tiêu của bạn',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Vui lòng nhập tên mục tiêu';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategoryField() {
    final categories = _categoriesMap[widget.pillar] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: "Danh mục định hướng ",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            children: const [
              TextSpan(text: "*", style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showCategoryPicker(categories),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCategory ?? "Chọn danh mục",
                  style: TextStyle(
                    color:
                        _selectedCategory == null
                            ? Colors.grey.shade600
                            : Colors.black87,
                    fontSize: 16,
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCategoryPicker(List<String> categories) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Chọn danh mục",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const Divider(height: 1),
              ...categories.map(
                (cat) => ListTile(
                  title: Text(cat),
                  onTap: () {
                    setState(() => _selectedCategory = cat);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDurationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Thời lượng",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _durations.map((dur) {
                final isSelected = _selectedDuration == dur;
                return ChoiceChip(
                  label: Text(dur),
                  selected: isSelected,
                  onSelected: (selected) async {
                    if (selected) {
                      if (dur == 'Tùy chỉnh') {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (picked != null) {
                          setState(() {
                            _startDate = picked.start;
                            _endDate = picked.end;
                            _selectedDuration = dur;
                          });
                        }
                      } else {
                        setState(() {
                          _selectedDuration = dur;
                          _endDate = null;
                        });
                      }
                    }
                  },
                );
              }).toList(),
        ),
        if (_selectedDuration == 'Tùy chỉnh' &&
            _startDate != null &&
            _endDate != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              "Từ ${_startDate!.day}/${_startDate!.month} đến ${_endDate!.day}/${_endDate!.month}",
              style: TextStyle(color: Colors.green[700]),
            ),
          ),
      ],
    );
  }

  Widget _buildMeasurementField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Bạn muốn đo lường mục tiêu này như thế nào?",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildRadioOption('task_based', 'Dựa trên hoàn thành task'),
          _buildRadioOption('streak', 'Duy trì liên tục (streak)'),
          _buildRadioOption('self_rating', 'Tự đánh giá cải thiện'),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String value, String title) {
    return RadioListTile<String>(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: value,
      groupValue: _successMeasurement,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      onChanged: (val) {
        if (val != null) setState(() => _successMeasurement = val);
      },
    );
  }

  Widget _buildBaselineRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Hiện tại bạn đánh giá mức độ này bao nhiêu?",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: _getColorForPillar(),
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: _baselineScore.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          activeColor: _getColorForPillar(),
          label: _baselineScore.toString(),
          onChanged: (val) {
            setState(() => _baselineScore = val.toInt());
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text("Thấp", style: TextStyle(color: Colors.grey)),
            Text("Cao", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildConditionalSection() {
    if (widget.pillar == PillarType.myGrowth) {
      return CheckboxListTile(
        title: const Text("Nhắc tôi thêm task ngay sau khi tạo"),
        value: _autoSuggestTasks,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        onChanged: (val) => setState(() => _autoSuggestTasks = val ?? false),
      );
    }

    if (widget.pillar == PillarType.together) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.handshake, color: Colors.blue[900], size: 20),
                const SizedBox(width: 8),
                Text(
                  "Xác nhận từ partner",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Mục tiêu này cần được cả hai đồng ý để kích hoạt.",
              style: TextStyle(fontSize: 13, color: Colors.blue[800]),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text("Gửi yêu cầu xác nhận"),
              value: _requiresPartnerConfirmation,
              contentPadding: EdgeInsets.zero,
              onChanged:
                  (val) => setState(() => _requiresPartnerConfirmation = val),
            ),
          ],
        ),
      );
    }

    // For Us
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.pink.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.home, color: Colors.pink[900], size: 20),
              const SizedBox(width: 8),
              Text(
                "Mức cam kết",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Colors.pink[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _commitmentLevel,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.pink.shade200),
              ),
            ),
            hint: const Text("Chọn mức cam kết"),
            items:
                _commitments.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
            onChanged: (val) {
              setState(() => _commitmentLevel = val);
            },
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text("Yêu cầu xác nhận từ partner"),
            value: _requiresPartnerConfirmation,
            contentPadding: EdgeInsets.zero,
            onChanged:
                (val) => setState(() => _requiresPartnerConfirmation = val),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Hủy"),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: _getColorForPillar(),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Text(
                      "Tạo mục tiêu",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  Color _getColorForPillar() {
    if (widget.pillar == PillarType.myGrowth) return Colors.green[600]!;
    if (widget.pillar == PillarType.together) return Colors.blue[600]!;
    return Colors.pink[400]!;
  }
}
