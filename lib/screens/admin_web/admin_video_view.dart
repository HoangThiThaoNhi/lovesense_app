import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/video_model.dart';
import '../../services/admin_service.dart';

class AdminVideoView extends StatelessWidget {
  const AdminVideoView({super.key});

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
               Text('Quản lý Video', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
               ElevatedButton.icon(
                 onPressed: () => _showAddVideoDialog(context),
                 icon: const Icon(Icons.upload),
                 label: const Text('Tải Video lên'),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: const Color(0xFFFF4081),
                   foregroundColor: Colors.white,
                 ),
               )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: AdminService().getVideosStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) return const Center(child: Text("Chưa có video nào."));

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (c, i) => const Divider(),
                  itemBuilder: (context, index) {
                    final video = VideoModel.fromFirestore(docs[index]);
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: video.thumbnailUrl.isNotEmpty
                          ? Image.network(video.thumbnailUrl, width: 80, height: 45, fit: BoxFit.cover)
                          : Container(width: 80, height: 45, color: Colors.grey),
                      ),
                      title: Text(video.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${video.category} • ${video.duration}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => AdminService().deleteVideo(video.id),
                          ),
                        ],
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

  void _showAddVideoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddVideoDialog(),
    );
  }
}

class _AddVideoDialog extends StatefulWidget {
  const _AddVideoDialog();

  @override
  State<_AddVideoDialog> createState() => _AddVideoDialogState();
}

class _AddVideoDialogState extends State<_AddVideoDialog> {
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  String _category = 'Mental Health';
  
  Uint8List? _videoBytes;
  String? _videoName;
  Uint8List? _thumbBytes;
  String? _thumbName;
  
  bool _isUploading = false;

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      setState(() {
        _videoBytes = result.files.first.bytes;
        _videoName = result.files.first.name;
      });
    }
  }

  Future<void> _pickThumb() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _thumbBytes = result.files.first.bytes;
        _thumbName = result.files.first.name;
      });
    }
  }

  Future<void> _upload() async {
    if (_titleController.text.isEmpty || _videoBytes == null || _thumbBytes == null) {
      // Show error
      return;
    }

    setState(() => _isUploading = true);

    try {
      final adminService = AdminService();
      
      // Upload Video
      final videoUrl = await adminService.uploadFile(_videoBytes!, 'videos', '${DateTime.now().millisecondsSinceEpoch}_$_videoName');
      
      // Upload Thumb
      final thumbUrl = await adminService.uploadFile(_thumbBytes!, 'thumbnails', '${DateTime.now().millisecondsSinceEpoch}_$_thumbName');

      final newVideo = VideoModel(
        id: '', // Firestore will gen, or we gen here
        title: _titleController.text,
        thumbnailUrl: thumbUrl,
        videoUrl: videoUrl,
        duration: _durationController.text,
        category: _category,
        createdAt: DateTime.now(),
      );

      await adminService.addVideo(newVideo); // Method needs to handle empty ID or we set docRef

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Upload process failed: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tải Video Mới'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Tiêu đề Video')),
            TextField(controller: _durationController, decoration: const InputDecoration(labelText: 'Thời lượng (ví dụ 10:00)')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: ['Mental Health', 'Yoga', 'Meditation', 'Sleep'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _category = v!),
              decoration: const InputDecoration(labelText: 'Danh mục'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickVideo,
              icon: Icon(_videoBytes != null ? Icons.check : Icons.movie),
              label: Text(_videoName ?? 'Chọn File Video'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickThumb,
              icon: Icon(_thumbBytes != null ? Icons.check : Icons.image),
              label: Text(_thumbName ?? 'Chọn Ảnh Bìa'),
            ),
            if (_isUploading)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(
          onPressed: _isUploading ? null : _upload,
          child: const Text('Tải lên'),
        ),
      ],
    );
  }
}
