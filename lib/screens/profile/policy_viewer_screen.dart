import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/profile_service.dart';

class PolicyViewerScreen extends StatefulWidget {
  final String title;
  final String policyId; // Changed from content to policyId

  const PolicyViewerScreen({
    super.key,
    required this.title,
    required this.policyId,
  });

  @override
  State<PolicyViewerScreen> createState() => _PolicyViewerScreenState();
}

class _PolicyViewerScreenState extends State<PolicyViewerScreen> {
  late Future<String?> _policyFuture;

  @override
  void initState() {
    super.initState();
    _policyFuture = ProfileService().getPolicyContent(widget.policyId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
      ),
      body: FutureBuilder<String?>(
        future: _policyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }

          final content = snapshot.data;

          if (content == null || content.isEmpty) {
            return const Center(child: Text("Nội dung đang được cập nhật..."));
          }

          return Markdown(
            data: content,
            styleSheet: MarkdownStyleSheet(
              h1: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold),
              h2: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
              p: GoogleFonts.inter(
                fontSize: 15,
                height: 1.5,
                color: Colors.black87,
              ),
              listBullet: const TextStyle(color: Colors.black87),
            ),
            padding: const EdgeInsets.all(16),
          );
        },
      ),
    );
  }
}
