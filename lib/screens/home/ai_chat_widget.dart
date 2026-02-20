import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/ai_service.dart';

class AiChatWidget extends StatefulWidget {
  const AiChatWidget({super.key});

  @override
  State<AiChatWidget> createState() => _AiChatWidgetState();
}

class _AiChatWidgetState extends State<AiChatWidget> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  String _streamingText = ''; // Buffer for real-time response

  @override
  void initState() {
    super.initState();
    AIService().init();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Color(0xFFE1BEE7), shape: BoxShape.circle),
                      child: const Icon(Icons.smart_toy, color: Colors.purple, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lovesense AI', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          'Đang trực tuyến', 
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.green),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    // History Button
                    IconButton(
                      onPressed: _showHistory,
                      icon: const Icon(Icons.history, color: Colors.purple),
                      tooltip: "Lịch sử tư vấn",
                    ),
                    // New Chat Button (Quick Access)
                    IconButton(
                      onPressed: () {
                         AIService().startNewChat();
                         setState(() {}); // Rebuild stream
                      },
                      icon: const Icon(Icons.add_comment_outlined, color: Colors.purple),
                      tooltip: "Cuộc trò chuyện mới",
                    ),
                    const SizedBox(width: 8),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),

          // Body
          Expanded(
            child: _buildChatArea(),
          ),
        ],
      ),
    );
  }



  // ... (Key methods unchanged)

  // --- Chat Logic ---

  Future<void> _sendMessage({String? customText}) async {
    final text = customText ?? _inputController.text.trim();
    if (text.isEmpty) return;

    if (customText == null) _inputController.clear();
    setState(() {
      _isLoading = true;
      _streamingText = ''; // Reset buffer
    });
    _scrollToBottom();

    try {
      await AIService().sendMessage(
        text, 
        onStream: (partialText) {
          if (mounted) {
            setState(() {
              _streamingText = partialText;
            });
            _scrollToBottom();
          }
        }
      );
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _streamingText = ''; // Clear buffer once committed to DB (StreamBuilder takes over)
        });
      }
    }
  }

  // ... (Scroll method)

  // ... (Build method)
  
  // ... (ApiKey method)

  Widget _buildChatArea() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: AIService().getChatStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text("Đã có lỗi xảy ra: ${snapshot.error}"));
              }

              final docs = snapshot.data?.docs ?? [];
              
              // Auto-scroll logic (Simplified)
              if (docs.isNotEmpty && !_isLoading) {
                 // Only auto-scroll on load if not typing (to avoid fighting user scroll)
                 // But here we want to follow new messages.
                 // WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
              }

              if (docs.isEmpty && !_isLoading) {
                 return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.psychology_alt, size: 80, color: Colors.purple),
                      const SizedBox(height: 24),
                      Text(
                        "AI Coach sẵn sàng lắng nghe!",
                        style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Bắt đầu cuộc trò chuyện để thấu hiểu\nbản thân và tìm giải pháp.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () => _sendMessage(customText: "Bắt đầu"),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text("Bắt đầu phiên tư vấn"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6200EA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: docs.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  // The "Ghost" Item (Loading or Streaming)
                  if (index == docs.length) {
                    if (_streamingText.isNotEmpty) {
                      return _buildChatMessage(
                        isUser: false, 
                        message: _streamingText
                      );
                    }
                    return _buildLoadingBubble();
                  }

                  final data = docs[index].data() as Map<String, dynamic>;
                  final isUser = data['isUser'] ?? false;
                  final text = data['text'] ?? '';

                  return _buildChatMessage(
                    isUser: isUser,
                    message: text,
                  );
                },
              );
            },
          ),
        ),
        // Input Area...
        // Input Area
        Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Nhập tâm sự của bạn...',
                    hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: const Color(0xFF6200EA),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatMessage({required bool isUser, required String message}) {
    // 1. Parse Tasks (Only if from AI)
    List<String> tasks = [];
    String cleanMessage = message;
    
    if (!isUser) {
       final taskRegExp = RegExp(r'<TASK>(.*?)</TASK>');
       tasks = taskRegExp.allMatches(message).map((m) => m.group(1)!).toList();
       cleanMessage = message.replaceAll(taskRegExp, '').trim();
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF6200EA) : Colors.grey[100],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
                bottomRight: isUser ? Radius.zero : const Radius.circular(20),
              ),
            ),
            child: Text(
              cleanMessage,
              style: GoogleFonts.inter(
                color: isUser ? Colors.white : Colors.black87,
                height: 1.5,
              ),
            ),
          ),
          
          // Task Suggestions
          if (tasks.isNotEmpty)
            ...tasks.map((task) => _buildTaskSuggestionCard(task)),
            
          const SizedBox(height: 8),
        ],
      ),
    ).animate().fadeIn().moveY(begin: 10, end: 0);
  }

  Widget _buildTaskSuggestionCard(String task) {
     // Helper to get UID from Service or Auth
     // Since we don't have Auth imported easily, let's use AIService's internal helper or just import it.
     // Better to import FirebaseAuth at top of file.
     
     return Container(
       margin: const EdgeInsets.only(bottom: 12, left: 4),
       width: MediaQuery.of(context).size.width * 0.75,
       padding: const EdgeInsets.all(12),
       decoration: BoxDecoration(
         color: Colors.purple.withOpacity(0.05),
         border: Border.all(color: Colors.purple.shade100),
         borderRadius: BorderRadius.circular(16),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Row(
             children: [
               const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20), 
               const SizedBox(width: 8), 
               Text("Gợi ý hành động", style: GoogleFonts.inter(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.w600))
             ],
           ),
           const SizedBox(height: 8),
           Text(task, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
           const SizedBox(height: 12),
           SizedBox(
             width: double.infinity,
             height: 40,
             child: ElevatedButton.icon(
               icon: const Icon(Icons.add_task, size: 18),
               label: const Text("Thêm vào To-Do List"),
               style: ElevatedButton.styleFrom(
                 backgroundColor: Colors.white,
                 foregroundColor: Colors.purple,
                 elevation: 0,
                 side: BorderSide(color: Colors.purple.shade200),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
               ),
               onPressed: () {
                  // Access Firestore via AIService helper or direct instance if imported
                  // We will use direct instance since we need to add to 'todos' collection, not 'chats'
                  // Assuming FirebaseAuth is imported
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid != null) {
                    FirebaseFirestore.instance.collection('users').doc(uid).collection('todos').add({
                      'task': task, 
                      'done': false, 
                      'deletedAt': null,
                      'isArchived': false,
                      'priority': 1,
                      'timestamp': FieldValue.serverTimestamp()
                    });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Đã thêm '$task' vào danh sách!"),
                      backgroundColor: Colors.green,
                    ));
                  }
               },
             ),
           )
         ],
       ),
     );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
         margin: const EdgeInsets.only(bottom: 16),
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
           color: Colors.grey[100],
           borderRadius: const BorderRadius.only(
             topLeft: Radius.circular(20),
             topRight: Radius.circular(20),
             bottomRight: Radius.circular(20),
           ),
         ),
         child: Row(
           mainAxisSize: MainAxisSize.min,
           children: [
             const SizedBox(
               width: 16, height: 16, 
               child: CircularProgressIndicator(strokeWidth: 2)
             ),
             const SizedBox(width: 8),
             Text("AI đang suy nghĩ...", style: GoogleFonts.inter(color: Colors.grey)),
           ],
         ),
      ),
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Lịch sử tư vấn", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () {
                        AIService().startNewChat();
                        setState(() {});
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("Tạo mới"),
                    )
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: AIService().getSessionsStream(),
                  builder: (context, snapshot) {
                     if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                     final docs = snapshot.data!.docs;
                     if (docs.isEmpty) return const Center(child: Text("Chưa có lịch sử nào"));
                     
                     return ListView.builder(
                       itemCount: docs.length,
                       itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final id = docs[index].id;
                          final lastMsg = data['lastMessage'] ?? 'Cuộc trò chuyện';
                          final isSelected = id == AIService().currentSessionId;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            leading: CircleAvatar(
                              backgroundColor: isSelected ? Colors.purple : Colors.grey[200],
                              child: Icon(Icons.chat_bubble_outline, color: isSelected ? Colors.white : Colors.grey, size: 18),
                            ),
                            title: Text(
                                lastMsg, 
                                maxLines: 1, 
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)
                            ),
                            trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.purple, size: 16) : null,
                            tileColor: isSelected ? Colors.purple.withOpacity(0.05) : null,
                            onTap: () {
                               AIService().loadChat(id);
                               setState(() {}); // Refresh parent stream
                               Navigator.pop(context);
                            },
                          );
                       },
                     );
                  },
                ),
              )
            ],
          ),
        );
      }
    );
  }
}
