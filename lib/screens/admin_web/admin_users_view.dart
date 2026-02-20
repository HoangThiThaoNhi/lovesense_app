import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';

class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key});

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  final AdminService _adminService = AdminService();
  String _searchQuery = '';
  String _filterRole = 'all'; // all, single, couple, creator, admin

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Tools
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quản lý Người dùng',
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Xem, chỉnh sửa và quản lý tài khoản người dùng hệ thống.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              _buildAddUserButton(context),
            ],
          ),
          const SizedBox(height: 32),

          // Filters & Search
          Row(
            children: [
              // Search Bar
              Expanded(
                flex: 2,
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên hoặc email...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Role Filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filterRole,
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('Tất cả vai trò'),
                      ),
                      DropdownMenuItem(value: 'single', child: Text('User')),
                      DropdownMenuItem(
                        value: 'creator',
                        child: Text('Creator'),
                      ),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (val) => setState(() => _filterRole = val!),
                    icon: const Icon(Icons.filter_list),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Data Table
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _adminService.getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: SelectableText(
                      'Lỗi: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var users = snapshot.data ?? [];

                // Filter Logic
                users =
                    users.where((u) {
                      final matchesSearch =
                          u.email.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          u.name.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          );
                      final matchesRole =
                          _filterRole == 'all' || u.role == _filterRole;
                      return matchesSearch && matchesRole;
                    }).toList();

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không tìm thấy người dùng phù hợp',
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.grey[200]),
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          Colors.grey[50],
                        ),
                        dataRowHeight: 60,
                        columns: const [
                          DataColumn(label: Text('Thông tin')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Vai trò')),
                          DataColumn(label: Text('Trạng thái')),
                          DataColumn(label: Text('Ngày tham gia')),
                          DataColumn(
                            label: Align(
                              alignment: Alignment.centerRight,
                              child: Text('Hành động'),
                            ),
                          ),
                        ],
                        rows:
                            users
                                .map((user) => _buildUserRow(context, user))
                                .toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildAddUserButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _showAddUserDialog(context),
      icon: const Icon(Icons.add),
      label: const Text('Thêm người dùng'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF4081),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        shadowColor: Colors.pink.withOpacity(0.3),
      ),
    );
  }

  DataRow _buildUserRow(BuildContext context, UserModel user) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
                child: Icon(
                  Icons.person,
                  color: _getRoleColor(user.role),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // if (user.isCreatorRequestPending)
                  //   const Text('Đang yêu cầu Creator', style: TextStyle(fontSize: 10, color: Colors.orange)),
                ],
              ),
            ],
          ),
        ),
        DataCell(SelectableText(user.email)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getRoleColor(user.role).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getRoleColor(user.role).withOpacity(0.2),
              ),
            ),
            child: Text(
              user.role.toUpperCase(),
              style: TextStyle(
                color: _getRoleColor(user.role),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:
                  user.status == UserStatus.active
                      ? Colors.green[50]
                      : Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              user.status.name.toUpperCase(),
              style: TextStyle(
                color:
                    user.status == UserStatus.active
                        ? Colors.green
                        : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            "${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        DataCell(
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                tooltip: 'Chỉnh sửa',
                onPressed: () => _showEditUserDialog(context, user),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Xóa',
                onPressed: () => _showDeleteConfirmDialog(context, user),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'creator':
        return Colors.purple;
      case 'couple':
        return Colors.pink;
      default:
        return Colors.blue;
    }
  }

  // --- Dialogs ---

  void _showAddUserDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String role = 'single';
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Thêm người dùng mới'),
                  content: SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Họ tên',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: emailCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: passCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Mật khẩu',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: role,
                          decoration: const InputDecoration(
                            labelText: 'Vai trò',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'single',
                              child: Text('User'),
                            ),
                            DropdownMenuItem(
                              value: 'creator',
                              child: Text('Creator'),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Admin'),
                            ),
                          ],
                          onChanged: (val) => role = val!,
                        ),
                        if (isLoading)
                          const Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: CircularProgressIndicator(),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () async {
                                if (emailCtrl.text.isEmpty ||
                                    passCtrl.text.isEmpty ||
                                    nameCtrl.text.isEmpty) {
                                  return;
                                }
                                setState(() => isLoading = true);
                                try {
                                  await _adminService.createUser(
                                    email: emailCtrl.text.trim(),
                                    password: passCtrl.text,
                                    name: nameCtrl.text.trim(),
                                    role: role,
                                  );
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Thêm người dùng thành công!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  setState(() => isLoading = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Lỗi: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                      child: const Text('Tạo người dùng'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showEditUserDialog(BuildContext context, UserModel user) {
    final nameCtrl = TextEditingController(text: user.name);
    String role = user.role;
    UserStatus status = user.status;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text('Sửa thông tin: ${user.name}'),
                  content: SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Họ tên',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: role,
                          decoration: const InputDecoration(
                            labelText: 'Vai trò',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'single',
                              child: Text('User'),
                            ),
                            DropdownMenuItem(
                              value: 'creator',
                              child: Text('Creator'),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Admin'),
                            ),
                          ],
                          onChanged: (val) => setState(() => role = val!),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<UserStatus>(
                          initialValue: status,
                          decoration: const InputDecoration(
                            labelText: 'Trạng thái',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              UserStatus.values.map((s) {
                                return DropdownMenuItem(
                                  value: s,
                                  child: Text(s.name.toUpperCase()),
                                );
                              }).toList(),
                          onChanged: (val) => setState(() => status = val!),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _adminService.updateUserDetails(
                          uid: user.uid,
                          name: nameCtrl.text,
                          role: role,
                          status: status.name,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Lưu thay đổi'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: Text(
              'Bạn có chắc chắn muốn xóa vĩnh viễn người dùng "${user.name}" không?\nHành động này không thể hoàn tác.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await _adminService.deleteUser(user.uid);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa người dùng'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                child: const Text('Xóa vĩnh viễn'),
              ),
            ],
          ),
    );
  }
}
