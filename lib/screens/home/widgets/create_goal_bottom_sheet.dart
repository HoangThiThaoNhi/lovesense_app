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
  DateTime? _endDate = DateTime.now().add(const Duration(days: 30));
  String _successMeasurement = 'task_based';
  int _baselineScore = 3;
  bool _requiresPartnerConfirmation = false;
  String? _commitmentLevel;
  int? _targetCount;
  String? _streakType = 'both';
  int? _targetScore = 4;

  // Together specific
  String _participationMode = 'both';
  String _visibility = 'both';

  bool _isLoading = false;

  final Map<PillarType, Map<String, String>> _categoriesMap = {
    PillarType.myGrowth: {
      'Emotional Control': 'Kiểm soát cảm xúc',
      'Self Improvement': 'Phát triển bản thân',
      'Discipline': 'Kỷ luật',
      'Learning': 'Học tập & Kỹ năng',
      'Custom': 'Khác',
    },
    PillarType.together: {
      'Communication': 'Giao tiếp',
      'Conflict Resolution': 'Giải quyết xung đột',
      'Quality Time': 'Thời gian chất lượng',
      'Trust': 'Niềm tin',
      'Emotional Support': 'Hỗ trợ tinh thần',
      'Custom': 'Khác',
    },
    PillarType.forUs: {
      'Financial Planning': 'Tài chính',
      'Marriage Planning': 'Kế hoạch kết hôn',
      'Family Plan': 'Gia đình',
      'Living Arrangement': 'Chỗ ở & Cuộc sống',
      'Long-term Vision': 'Tầm nhìn dài hạn',
      'Custom': 'Khác',
    },
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
  void initState() {
    super.initState();
    if (widget.pillar == PillarType.together) {
      _requiresPartnerConfirmation = true; // Default to true for Together
    }
  }

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
        targetScore:
            _successMeasurement == 'self_rating' ? _targetScore : null,
        targetCount:
            (_successMeasurement == 'task_based' && _participationMode == 'flexible') ? _targetCount : null,
        streakType:
            _successMeasurement == 'streak' ? _streakType : null,
        requiresPartnerConfirmation:
            widget.pillar == PillarType.together
                ? true
                : widget.pillar != PillarType.myGrowth
                    ? _requiresPartnerConfirmation
                    : false,
        partnerStatus:
            (widget.pillar == PillarType.together || (widget.pillar != PillarType.myGrowth && _requiresPartnerConfirmation))
                ? 'pending'
                : 'active',
        visibility: widget.pillar == PillarType.together ? _visibility : 'both',
        participationMode:
            widget.pillar == PillarType.together ? _participationMode : null,
        commitmentLevel:
            widget.pillar == PillarType.forUs ? _commitmentLevel : null,
      );

      await _goalService.createGoal(goal);

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
    final Map<String, String> categories = _categoriesMap[widget.pillar] ?? <String, String>{};
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
        _buildDropdownAlternative(
          label: "Danh mục",
          valueKey: _selectedCategory,
          items: categories,
          hint: "Chọn danh mục",
          onChanged: (val) {
            setState(() => _selectedCategory = val);
          },
        ),
      ],
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
                          initialDateRange: DateTimeRange(
                            start: DateTime.now(),
                            end: DateTime.now().add(const Duration(days: 7)),
                          ),
                          firstDate:
                              DateTime.now(), // Prevent selecting past dates
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
                          if (dur == '2 tuần') {
                            _endDate = DateTime.now().add(
                              const Duration(days: 14),
                            );
                          } else if (dur == '1 tháng') {
                            _endDate = DateTime.now().add(
                              const Duration(days: 30),
                            );
                          } else if (dur == '3 tháng') {
                            _endDate = DateTime.now().add(
                              const Duration(days: 90),
                            );
                          } else {
                            _endDate = null;
                          }
                        });
                      }
                    }
                  },
                );
              }).toList(),
        ),
        if (['2 tuần', '1 tháng', '3 tháng'].contains(_selectedDuration))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              "* Tính thời gian từ thời điểm hiện tại.",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ),
        if (_selectedDuration == 'Tùy chỉnh' &&
            _startDate != null &&
            _endDate != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              "Từ ${_startDate!.day}/${_startDate!.month}/${_startDate!.year} đến ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}",
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
          if (_successMeasurement == 'streak' && widget.pillar == PillarType.together)
            Padding(
               padding: const EdgeInsets.only(left: 32, bottom: 8, right: 16),
               child: _buildDropdownAlternative(
                 label: "Quy tắc tính streak",
                 valueKey: _streakType,
                 items: const {
                   'both': 'Cả hai phải check-in',
                   'any': 'Chỉ cần 1 trong 2',
                   'individual': 'Tính riêng',
                 },
                 hint: "Chọn quy tắc tính streak",
                 onChanged: (val) => setState(() => _streakType = val),
               ),
            ),
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
          "Hiện tại bạn đánh giá vấn đề này ở mức nào?",
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
        const SizedBox(height: 16),
        Text(
          "Mục tiêu hoàn thành khi đánh giá đạt:",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: (_targetScore ?? 4).toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          activeColor: Colors.green[600],
          label: _targetScore.toString(),
          onChanged: (val) {
            setState(() => _targetScore = val.toInt());
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
            const SizedBox(height: 16),
            Text(
              "Hình thức tham gia",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 8),
            _buildDropdownAlternative(
              label: "Hình thức tham gia",
              valueKey: _participationMode,
              items: const {
                'both': 'Cả hai cùng thực hiện task',
                'split': 'Phân chia nhiệm vụ',
                'flexible': 'Linh hoạt (ai làm cũng được)',
              },
              hint: "Chọn hình thức tham gia",
              onChanged: (val) {
                setState(() => _participationMode = val);
              },
            ),
            const SizedBox(height: 16),
            if (_successMeasurement == 'task_based' && _participationMode == 'flexible')
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  initialValue: _targetCount?.toString() ?? '',
                  decoration: InputDecoration(
                    labelText: "Số lượng task tổng cần đạt",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (val) => _targetCount = int.tryParse(val),
                  validator: (val) {
                    if (_successMeasurement == 'task_based' && _participationMode == 'flexible') {
                      if (val == null || int.tryParse(val) == null || int.parse(val) <= 0) {
                        return 'Vui lòng nhập số lượng (VD: 10)';
                      }
                    }
                    return null;
                  }
                ),
              ),
            if (_participationMode == 'both')
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Goal cần sự tham gia của cả hai",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.orange.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Mục tiêu chỉ hoàn thành khi cả hai đều xác nhận đã thực hiện.",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              "Quyền chỉnh sửa",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 8),
            _buildDropdownAlternative(
              label: "Quyền chỉnh sửa",
              valueKey: _visibility,
              items: const {
                'both': 'Cả hai chỉnh sửa',
                'only_creator': 'Chỉ người tạo chỉnh sửa',
              },
              hint: "Quyền chỉnh sửa",
              onChanged: (val) {
                setState(() => _visibility = val);
              },
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
          _buildDropdownAlternative(
            label: "Mức cam kết",
            valueKey: _commitmentLevel,
            items: { for (var c in _commitments) c : c },
            hint: "Chọn mức cam kết",
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

  Widget _buildDropdownAlternative({
    required String label,
    required String? valueKey,
    required Map<String, String> items,
    required Function(String) onChanged,
    required String hint,
  }) {
    final selectedText = valueKey != null && items.containsKey(valueKey) ? items[valueKey]! : hint;

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Padding(
                     padding: const EdgeInsets.all(16),
                     child: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                   ),
                   const Divider(height: 1),
                   Flexible(
                     child: SingleChildScrollView(
                       child: Column(
                         mainAxisSize: MainAxisSize.min,
                         children: items.entries.map((entry) => ListTile(
                           title: Text(entry.value, style: GoogleFonts.inter(
                             fontWeight: entry.key == valueKey ? FontWeight.bold : FontWeight.normal,
                             color: entry.key == valueKey ? _getColorForPillar() : Colors.black,
                           )),
                           trailing: entry.key == valueKey ? Icon(Icons.check, color: _getColorForPillar()) : null,
                           onTap: () {
                             onChanged(entry.key);
                             Navigator.pop(context);
                           },
                         )).toList(),
                       ),
                     ),
                   ),
                   const SizedBox(height: 16),
                ]
              )
            );
          }
        );
      },
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(selectedText, style: GoogleFonts.inter(
              color: valueKey == null ? Colors.grey.shade600 : Colors.black,
            )),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
