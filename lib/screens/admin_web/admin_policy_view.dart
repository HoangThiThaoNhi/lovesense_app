import 'package:flutter/material.dart';
import '../../models/policy_model.dart';
import '../../services/admin_service.dart';

class AdminPolicyView extends StatefulWidget {
  const AdminPolicyView({super.key});

  @override
  State<AdminPolicyView> createState() => _AdminPolicyViewState();
}

class _AdminPolicyViewState extends State<AdminPolicyView> {
  final AdminService _adminService = AdminService();
  final List<String> _requiredPolicies = [
    'terms_of_use',
    'privacy_policy',
    'ai_policy',
  ];

  final Map<String, String> _policyTitles = {
    'terms_of_use': 'Điều khoản sử dụng',
    'privacy_policy': 'Chính sách quyền riêng tư',
    'ai_policy': 'Chính sách AI',
  };

  PolicyModel? _selectedPolicy;
  final TextEditingController _contentController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _selectPolicy(PolicyModel policy) {
    setState(() {
      _selectedPolicy = policy;
      _contentController.text = policy.content;
    });
  }

  Future<void> _savePolicy() async {
    if (_selectedPolicy == null) return;
    setState(() => _isSaving = true);

    try {
      final updatedPolicy = PolicyModel(
        id: _selectedPolicy!.id,
        title: _selectedPolicy!.title,
        content: _contentController.text,
        updatedAt: DateTime.now(),
      );

      await _adminService.updatePolicy(updatedPolicy);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Lưu thành công!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _createMissingPolicy(String id) {
    final newPolicy = PolicyModel(
      id: id,
      title: _policyTitles[id] ?? 'Chính sách',
      content: '# ${_policyTitles[id]}\n\nNội dung đang cập nhật...',
      updatedAt: DateTime.now(),
    );
    _selectPolicy(newPolicy);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sidebar List
        Container(
          width: 300,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Colors.black12)),
          ),
          child: StreamBuilder<List<PolicyModel>>(
            stream: _adminService.getPoliciesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final existingPolicies = snapshot.data ?? [];
              final Map<String, PolicyModel> policyMap = {
                for (var p in existingPolicies) p.id: p,
              };

              return ListView.builder(
                itemCount: _requiredPolicies.length,
                itemBuilder: (context, index) {
                  final id = _requiredPolicies[index];
                  final exists = policyMap.containsKey(id);
                  final title = _policyTitles[id] ?? id;
                  final isSelected = _selectedPolicy?.id == id;

                  return ListTile(
                    title: Text(title),
                    subtitle: Text(
                      exists ? "Đã có nội dung" : "Chưa tạo",
                      style: TextStyle(
                        fontSize: 12,
                        color: exists ? Colors.green : Colors.grey,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: Colors.pink.withOpacity(0.1),
                    onTap: () {
                      if (exists) {
                        _selectPolicy(policyMap[id]!);
                      } else {
                        _createMissingPolicy(id);
                      }
                    },
                    trailing:
                        isSelected
                            ? const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.pink,
                            )
                            : null,
                  );
                },
              );
            },
          ),
        ),

        // Editor Area
        Expanded(
          child:
              _selectedPolicy == null
                  ? const Center(
                    child: Text(
                      "Chọn một chính sách để chỉnh sửa",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                  : Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(color: Colors.black12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedPolicy!.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _isSaving ? null : _savePolicy,
                              icon:
                                  _isSaving
                                      ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Icon(Icons.save),
                              label: const Text("Lưu thay đổi"),
                            ),
                          ],
                        ),
                      ),

                      // Editor
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: TextField(
                            controller: _contentController,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: "Nhập nội dung Markdown ở đây...",
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ],
                  ),
        ),
      ],
    );
  }
}
