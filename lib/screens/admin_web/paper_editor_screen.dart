import 'package:flutter/material.dart';
import '../../models/blog_model.dart';
import '../../services/content_service.dart';
import '../../services/admin_service.dart'; // For upload
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart'; // For image picking
import 'package:flutter_markdown/flutter_markdown.dart'; // For preview
import 'dart:typed_data';

class BlogEditorScreen extends StatefulWidget {
  final BlogModel? blog; // Null = Create New

  const BlogEditorScreen({super.key, this.blog});

  @override
  State<BlogEditorScreen> createState() => _BlogEditorScreenState();
}

class _BlogEditorScreenState extends State<BlogEditorScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagsController = TextEditingController();
  
  String _status = 'draft';
  String _currentCoverImage = '';
  bool _isFeatured = false;
  
  final ContentService _contentService = ContentService();
  final AdminService _adminService = AdminService();
  
  bool _isLoading = false;
  Uint8List? _webImageBytes; // For Web/Desktop local preview before upload
  String? _imageFileName;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    if (widget.blog != null) {
      _titleController.text = widget.blog!.title;
      _descriptionController.text = widget.blog!.description;
      _contentController.text = widget.blog!.content;
      _currentCoverImage = widget.blog!.coverImage;
      _categoryController.text = widget.blog!.category;
      _tagsController.text = widget.blog!.tags.join(', ');
      _status = widget.blog!.status;
      _isFeatured = widget.blog!.isFeatured;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  // --- Image Handling ---
  
  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _webImageBytes = result.files.first.bytes;
          _imageFileName = result.files.first.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi chọn ảnh: $e')));
    }
  }

  Future<String> _uploadImageIfSelected() async {
    if (_webImageBytes == null) return _currentCoverImage; // No new image, keep old
    
    // Upload
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$_imageFileName';
    return await _adminService.uploadFile(_webImageBytes!, 'blog_images', fileName);
  }
  
  int _calculateReadingTime(String content) {
    final wordCount = content.trim().split(RegExp(r'\s+')).length;
    final readingTime = (wordCount / 200).ceil(); // Avg 200 words per minute
    return readingTime > 0 ? readingTime : 1;
  }

  // --- Saving ---

  Future<void> _saveBlog() async {
    if (!_formKey.currentState!.validate()) return;
    
    // 1. Upload Image
    String imageUrl = _currentCoverImage;
    if (_webImageBytes != null) {
      try {
        print("Uploading image...");
        imageUrl = await _uploadImageIfSelected();
        print("Image uploaded: $imageUrl");
      } catch (e) {
        print("Upload failed: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi upload ảnh (đã dùng ảnh mặc định). Vui lòng kiểm tra Storage sau.')),
        );
        // Use a nice placeholder if upload fails
        imageUrl = "https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?q=80&w=1000&auto=format&fit=crop"; 
      }
    } else if (imageUrl.isEmpty) {
       // If no image selected and no current image, use default
       imageUrl = "https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?q=80&w=1000&auto=format&fit=crop";
    }

    try {
      // 2. Parse Tags
      final tagsList = _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      // 3. Create Model
      final newBlog = BlogModel(
        id: widget.blog?.id ?? '', 
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        content: _contentController.text, 
        coverImage: imageUrl,
        category: _categoryController.text.trim().isEmpty ? 'General' : _categoryController.text.trim(),
        tags: tagsList,
        status: _status,
        authorId: 'admin',
        isFeatured: _isFeatured,
        readingTime: _calculateReadingTime(_contentController.text),
        createdAt: widget.blog?.createdAt ?? Timestamp.now(),
        updatedAt: Timestamp.now(),
        // Keep stats
        viewCount: widget.blog?.viewCount ?? 0,
        likeCount: widget.blog?.likeCount ?? 0,
        commentCount: widget.blog?.commentCount ?? 0,
      );

      // 4. Save to Firestore
      print("Saving to Firestore...");
      if (widget.blog == null) {
        await _contentService.createBlog(newBlog);
      } else {
        await _contentService.updateBlog(newBlog);
      }
      print("Saved to Firestore.");
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  // --- Text Formatting Helpers ---
  
  void _addMarkdown(String syntax) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    
    if (selection.start == -1) { // No selection, append
       _contentController.text = '$text$syntax';
    } else {
       final newText = text.replaceRange(selection.start, selection.end, '$syntax${text.substring(selection.start, selection.end)}$syntax');
       _contentController.value = TextEditingValue(
         text: newText,
         selection: TextSelection.collapsed(offset: selection.start + syntax.length),
       );
    }
  }
  
    void _addHeader() {
    final text = _contentController.text;
    final selection = _contentController.selection;
    if (selection.start == -1) return;
    
    final newText = text.replaceRange(selection.start, selection.start, '# ');
     _contentController.value = TextEditingValue(
         text: newText,
         selection: TextSelection.collapsed(offset: selection.start + 2),
       );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.blog == null ? "Tạo Blog" : "Chỉnh sửa Blog"),
        actions: [
          IconButton(
            onPressed: _saveBlog,
            icon: const Icon(Icons.save),
            tooltip: 'Lưu bài viết',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
             Tab(icon: Icon(Icons.edit), text: "Soạn thảo"),
             Tab(icon: Icon(Icons.visibility), text: "Xem trước"),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : TabBarView(
          controller: _tabController,
          children: [
            // Editor Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status & Featured Row
                    Row(
                       children: [
                         Expanded(
                           child: DropdownButtonFormField<String>(
                             decoration: const InputDecoration(labelText: 'Trạng thái', border: OutlineInputBorder()),
                             initialValue: _status,
                             items: const [
                               DropdownMenuItem(value: 'draft', child: Text("Nháp (Draft)")),
                               DropdownMenuItem(value: 'published', child: Text("Xuất bản (Published)")),
                             ],
                             onChanged: (val) {
                               if(val!=null) setState(() => _status = val);
                             },
                           ),
                         ),
                         const SizedBox(width: 16),
                         Expanded(
                           child: SwitchListTile(
                             title: const Text("Featured?"),
                             value: _isFeatured,
                             onChanged: (val) => setState(() => _isFeatured = val),
                             contentPadding: EdgeInsets.zero,
                           ),
                         ),
                       ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Category & Tags
                    Row(
                       children: [
                         Expanded(
                           child: TextFormField(
                             controller: _categoryController,
                             decoration: const InputDecoration(
                               labelText: 'Chuyên mục',
                               border: OutlineInputBorder(),
                               hintText: 'Love, Psychology...'
                             ),
                           ),
                         ),
                         const SizedBox(width: 16),
                         Expanded(
                           child: TextFormField(
                             controller: _tagsController,
                             decoration: const InputDecoration(
                               labelText: 'Tags (cách nhau bởi dấu phẩy)',
                               border: OutlineInputBorder(),
                               hintText: 'tag1, tag2'
                             ),
                           ),
                         ),
                       ],
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề bài viết',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Nhập tiêu đề' : null,
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    
                    // Image Picker
                    Text("Ảnh bìa & Thumbnail", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        alignment: Alignment.center,
                        child: _webImageBytes != null
                            ? Image.memory(_webImageBytes!, fit: BoxFit.cover, width: double.infinity)
                            : (_currentCoverImage.isNotEmpty
                                ? Image.network(_currentCoverImage, fit: BoxFit.cover, width: double.infinity)
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                                      const SizedBox(height: 8),
                                      Text("Nhấn để tải ảnh lên", style: GoogleFonts.inter(color: Colors.grey)),
                                    ],
                                  )
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả ngắn (Description)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Nhập mô tả' : null,
                    ),
                    const SizedBox(height: 24),
                    
                    // Toolbar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
                      child: Row(
                        children: [
                          IconButton(icon: const Icon(Icons.format_bold), onPressed: () => _addMarkdown('**'), tooltip: 'Bold'),
                          IconButton(icon: const Icon(Icons.format_italic), onPressed: () => _addMarkdown('*'), tooltip: 'Italic'),
                          IconButton(icon: const Icon(Icons.title), onPressed: _addHeader, tooltip: 'Header'),
                          IconButton(icon: const Icon(Icons.list), onPressed: () => _addMarkdown('\n- '), tooltip: 'List'),
                          const Spacer(),
                          const Text("Markdown Supported", style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),

                    // Content (Body)
                    TextFormField(
                      controller: _contentController,
                      maxLines: 20,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(8))),
                        hintText: '# Viết nội dung bài viết ở đây (Markdown)...',
                        contentPadding: EdgeInsets.all(16),
                      ),
                      validator: (v) => v!.isEmpty ? 'Nhập nội dung' : null,
                      style: GoogleFonts.inter(),
                    ),
                  ],
                ),
              ),
            ),
            
            // Preview Tab
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_webImageBytes != null)
                       Image.memory(_webImageBytes!, height: 200, width: double.infinity, fit: BoxFit.cover)
                    else if (_currentCoverImage.isNotEmpty)
                       Image.network(_currentCoverImage, height: 200, width: double.infinity, fit: BoxFit.cover),
                    const SizedBox(height: 16),
                    Text(
                      _titleController.text,
                      style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Chuyên mục: ${_categoryController.text} • Tags: ${_tagsController.text}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                     const SizedBox(height: 8),
                    if(_descriptionController.text.isNotEmpty)
                       Text("Mô tả: ${_descriptionController.text}", style: const TextStyle(fontStyle: FontStyle.italic)),
                    
                    const Divider(height: 32),
                     MarkdownBody(
                      data: _contentController.text,
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        p: GoogleFonts.inter(fontSize: 16, height: 1.6),
                        h1: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}

