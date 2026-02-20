import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;

  Gender _selectedGender = Gender.notDisclosed; // Initialize with default
  DateTime? _selectedDob;

  // Image states
  bool _isUploadingAvatar = false;
  bool _isUploadingCover = false;
  String? _newAvatarUrl;
  String? _newCoverUrl;

  // To track changes
  late UserModel _initialUser;

  bool _isLoading = false;

  // Username Logic
  bool _canEditUsername = true;
  String? _usernameError;

  // Default Assets
  // Since we don't have guaranteed assets, we use these placeholders or high-quality dummy URLs if null.
  // Ideally this would be 'assets/images/logo.png'.
  static const String kDefaultAvatarUrl =
      "https://ui-avatars.com/api/?name=User&background=random";
  static const String kDefaultCoverUrl =
      "https://picsum.photos/800/200"; // Or a specific app branding image

  @override
  void initState() {
    super.initState();
    _initialUser = widget.user;

    _nameController = TextEditingController(text: widget.user.name);
    _usernameController = TextEditingController(text: widget.user.username);
    _bioController = TextEditingController(text: widget.user.bio);

    // Format phone: Strip +84 if present to show local, or just show as is if raw.
    // User requested "Show correct VN phone... if user enters 0 remove it".
    // We will assume storage is +84...
    // Let's just show the suffix for editing if it starts with +84
    String phoneDisplay = widget.user.phoneNumber ?? '';
    if (phoneDisplay.startsWith('+84')) {
      phoneDisplay = phoneDisplay.substring(3);
    }
    _phoneController = TextEditingController(text: phoneDisplay);

    _selectedGender = widget.user.gender;
    _selectedDob = widget.user.dateOfBirth;

    _checkUsernameEditable();
  }

  void _checkUsernameEditable() {
    if (widget.user.lastUsernameChangeAt != null) {
      final daysSince =
          DateTime.now().difference(widget.user.lastUsernameChangeAt!).inDays;
      if (daysSince < 30) {
        _canEditUsername = false;
        _usernameError = "Bạn chỉ có thể đổi lại sau ${30 - daysSince} ngày";
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    if (_newAvatarUrl != null || _newCoverUrl != null) return true;
    if (_nameController.text != _initialUser.name) return true;
    if (_usernameController.text != (_initialUser.username ?? '')) return true;
    if (_bioController.text != (_initialUser.bio ?? '')) return true;

    // Phone comparison need to account for +84 prefix logic
    String currentPhone = _phoneController.text.trim();
    if (currentPhone.isNotEmpty) currentPhone = "+84$currentPhone";
    if ((currentPhone.isEmpty ? null : currentPhone) !=
        _initialUser.phoneNumber) {
      return true;
    }

    if (_selectedGender != _initialUser.gender) return true;
    if (_selectedDob != _initialUser.dateOfBirth) return true;

    return false;
  }

  Future<void> _pickImage(bool isAvatar) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      // Check if we have path (mobile) or bytes (web)
      final hasPath = !kIsWeb && result.files.single.path != null;
      final hasBytes = kIsWeb && result.files.single.bytes != null;

      if (!hasPath && !hasBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Không thể chọn ảnh này")),
          );
        }
        return;
      }
      setState(() {
        if (isAvatar) {
          _isUploadingAvatar = true;
        } else {
          _isUploadingCover = true;
        }
      });

      Uint8List? fileBytes;
      File? file;

      if (kIsWeb) {
        fileBytes = result.files.single.bytes;
      } else {
        if (result.files.single.path != null) {
          file = File(result.files.single.path!);
        }
      }

      final fileName = result.files.single.name;

      try {
        String url;
        if (isAvatar) {
          url = await ProfileService().uploadAvatar(
            file: file,
            bytes: fileBytes,
            fileName: fileName,
          );
          if (mounted) setState(() => _newAvatarUrl = url);
        } else {
          url = await ProfileService().uploadCover(
            file: file,
            bytes: fileBytes,
            fileName: fileName,
          );
          if (mounted) setState(() => _newCoverUrl = url);
        }
        // Only show success if no error thrown
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "${isAvatar ? 'Avatar' : 'Ảnh bìa'} đã được tải lên!",
              ),
            ),
          );
        }
      } catch (e) {
        // ERROR HANDLING: Show message, do NOT set random image (state remains null/old)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Lỗi tải ảnh: ${e.toString()}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            if (isAvatar) {
              _isUploadingAvatar = false;
            } else {
              _isUploadingCover = false;
            }
          });
        }
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale(
        'vi',
        'VN',
      ), // Requires localization setup, but standard is fine
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  void _generateUsername() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập Họ tên trước")),
      );
      return;
    }
    final newUsername = ProfileService().generateUsername(
      _nameController.text.trim(),
    );
    setState(() {
      _usernameController.text = newUsername;
    });
  }

  Future<void> _saveProfile() async {
    if (!_hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không có thay đổi nào để lưu.")),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = ProfileService();

      // Format phone: Add +84 prefix
      String? finalPhone;
      String rawPhone = _phoneController.text.trim();
      if (rawPhone.isNotEmpty) {
        // Remove leading 0 if present
        if (rawPhone.startsWith('0')) rawPhone = rawPhone.substring(1);
        finalPhone = "+84$rawPhone";
      }

      await service.updateProfile(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        phoneNumber: finalPhone,
        gender: _selectedGender,
      );

      // Check Username
      if (_usernameController.text.trim() != widget.user.username) {
        if (_canEditUsername) {
          await service.updateUsername(_usernameController.text.trim());
        }
      }

      // Update DOB
      if (_selectedDob != widget.user.dateOfBirth && _selectedDob != null) {
        await service.updateDOB(_selectedDob!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã lưu thông tin thành công!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Default logic: App Logo if null.
    // Here using placeholders. Replace with 'assets/logo.png' if available.
    final displayAvatar =
        _newAvatarUrl ?? widget.user.photoUrl ?? kDefaultAvatarUrl;
    final displayCover =
        _newCoverUrl ??
        widget.user.coverUrl ??
        kDefaultCoverUrl; // Or null to show solid color

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          "Chỉnh sửa hồ sơ",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (_hasChanges) {
            final shouldPop = await showDialog<bool>(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text("Bỏ thay đổi?"),
                    content: const Text(
                      "Bạn có thay đổi chưa lưu. Bạn có chắc muốn thoát không?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Ở lại"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text("Thoát"),
                      ),
                    ],
                  ),
            );
            if (shouldPop == true && context.mounted) {
              Navigator.pop(context);
            }
          } else {
            Navigator.pop(context);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Cover & Avatar Section
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Cover Image
                    GestureDetector(
                      onTap: () => _pickImage(false),
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          image: DecorationImage(
                            image: NetworkImage(displayCover),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            if (_isUploadingCover)
                              const Center(child: CircularProgressIndicator()),
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      "Sửa ảnh bìa",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Avatar
                    Positioned(
                      bottom: -50,
                      child: GestureDetector(
                        onTap: () => _pickImage(true),
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: NetworkImage(displayAvatar),
                                child:
                                    _isUploadingAvatar
                                        ? const CircularProgressIndicator()
                                        : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF4081),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Section 1: Basic Info
                      _buildSectionContainer(
                        title: "Thông tin cơ bản",
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        text: "Username",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                        children: const [
                                          TextSpan(
                                            text: " *",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_canEditUsername)
                                      InkWell(
                                        onTap: _generateUsername,
                                        child: Text(
                                          "Tự động tạo",
                                          style: TextStyle(
                                            color:
                                                Theme.of(context).primaryColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                TextFormField(
                                  controller: _usernameController,
                                  enabled: _canEditUsername,
                                  decoration: InputDecoration(
                                    hintText: "username_unique",
                                    border: InputBorder.none,
                                    errorText: _usernameError,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return "Bắt buộc điền";
                                    }
                                    if (v.length < 3) {
                                      return "Tối thiểu 3 ký tự";
                                    }
                                    return null;
                                  },
                                ),
                                if (_canEditUsername)
                                  const Text(
                                    "Lưu ý: Chỉ có thể đổi 1 lần mỗi 30 ngày.",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          _buildTextField(
                            controller: _nameController,
                            label: "Họ tên",
                            hint: "Nhập họ tên của bạn",
                            icon: Icons.person_outline,
                            isRequired: true,
                            validator:
                                (v) =>
                                    v!.isEmpty ? "Không được để trống" : null,
                          ),
                          const Divider(height: 1),
                          _buildTextField(
                            controller: _bioController,
                            label: "Bio",
                            hint: "Giới thiệu ngắn...",
                            icon: Icons.info_outline,
                            maxLines: 3,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section 2: Account
                      _buildSectionContainer(
                        title: "Thông tin tài khoản",
                        children: [
                          _buildReadOnlyField(
                            "Email",
                            widget.user.email,
                            Icons.email_outlined,
                            isViewOnly: true,
                          ),
                          const Divider(height: 1),

                          // PHONE NUMBER FIELD (Customized)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              // onChanged removed to allow free typing
                              style: GoogleFonts.inter(fontSize: 15),
                              decoration: InputDecoration(
                                labelText: "Số điện thoại",
                                // Prefix with Flag and +84
                                prefixIcon: Container(
                                  width: 80,
                                  padding: const EdgeInsets.only(
                                    left: 10,
                                    right: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.flag,
                                        color: Colors.red,
                                      ), // Placeholder for VN flag
                                      const SizedBox(width: 4),
                                      Text(
                                        "+84",
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                border: InputBorder.none,
                                labelStyle: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section 3: Personal
                      _buildSectionContainer(
                        title: "Thông tin cá nhân",
                        children: [
                          _buildDropdownField<Gender>(
                            label: "Giới tính",
                            value: _selectedGender,
                            icon: Icons.people_outline,
                            items: [
                              const DropdownMenuItem(
                                value: Gender.male,
                                child: Text("Nam"),
                              ),
                              const DropdownMenuItem(
                                value: Gender.female,
                                child: Text("Nữ"),
                              ),
                              const DropdownMenuItem(
                                value: Gender.other,
                                child: Text("Khác"),
                              ),
                              const DropdownMenuItem(
                                value: Gender.notDisclosed,
                                child: Text("Không tiết lộ"),
                              ),
                            ],
                            onChanged:
                                (v) => setState(() => _selectedGender = v!),
                          ),
                          const Divider(height: 1),

                          // DATE OF BIRTH (Editable)
                          GestureDetector(
                            onTap: _selectDate,
                            child: Container(
                              color: Colors.transparent,
                              child: _buildReadOnlyField(
                                "Ngày sinh",
                                _selectedDob != null
                                    ? DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(_selectedDob!)
                                    : "Chạm để chọn ngày sinh",
                                Icons.cake_outlined,
                                isViewOnly: false,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      const SizedBox(height: 40),

                      // Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF4081),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : Text(
                                    "Lưu thay đổi",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: GoogleFonts.inter(fontSize: 15),
        decoration: InputDecoration(
          label: RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              children:
                  isRequired
                      ? [
                        const TextSpan(
                          text: " *",
                          style: TextStyle(color: Colors.red),
                        ),
                      ]
                      : [],
            ),
          ),
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey[400]),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(
    String label,
    String value,
    IconData icon, {
    bool isViewOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    text: label,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    children:
                        isViewOnly
                            ? [
                              const TextSpan(
                                text: " (chỉ xem)",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ]
                            : [],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isViewOnly ? Colors.grey[600] : null,
                        ),
                      ),
                    ),
                    if (isViewOnly) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.lock, size: 16, color: Colors.grey),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items: items,
        onChanged: onChanged,
        style: GoogleFonts.inter(fontSize: 15, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey[400]),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
