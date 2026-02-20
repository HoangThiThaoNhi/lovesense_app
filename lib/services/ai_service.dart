import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class AIService {
  // Singleton pattern
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  SharedPreferences? _prefs;

  // Dependencies
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  bool get hasChatted => _prefs?.getBool('ai_has_chatted') ?? false;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Validation
    final apiKey = AppConfig.groqApiKey;
    if (apiKey.contains('YOUR_') || apiKey.isEmpty) {
      print('Warning: Groq API Key not configured');
    }
  }

  // Helper for Guest/Test Mode
  String get _currentUserId => _auth.currentUser?.uid ?? 'guest_user_demo';

  Future<void> _ensureAuth() async {
    if (_auth.currentUser == null) {
      try {
        await _auth.signInAnonymously();
      } catch (e) {
        // If Anonymous auth is disabled in Console, this fails.
        // We continue as 'guest_user_demo', hoping Rules allow public write or ignored.
      }
    }
  }

  // --- Session Management ---
  String _currentSessionId = 'main_chat';
  String get currentSessionId => _currentSessionId;

  // Start a fresh session
  void startNewChat() {
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Load an existing session
  void loadChat(String sessionId) {
    _currentSessionId = sessionId;
  }

  // List of all chat sessions
  Stream<QuerySnapshot> getSessionsStream() {
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('chats')
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Get Chat Stream for CURRENT Session
  Stream<QuerySnapshot> getChatStream() {
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('chats')
        .doc(_currentSessionId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> _saveMessageToDB(String text, bool isUser) async {
    final chatDocRef = _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('chats')
        .doc(_currentSessionId);

    // 1. Save Message
    await chatDocRef.collection('messages').add({
      'text': text,
      'isUser': isUser,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. Update Session Metadata (For History List)
    await chatDocRef.set({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'id': _currentSessionId,
    }, SetOptions(merge: true));
  }

  // --- Interaction Logic ---

  Future<void> sendMessage(String message, {Function(String)? onStream}) async {
    await _ensureAuth();

    // 1. Mark interaction state
    if (!hasChatted) {
      await _prefs?.setBool('ai_has_chatted', true);
    }

    // 2. Save User Message immediately
    try {
      await _saveMessageToDB(message, true);
    } catch (e) {
      throw Exception(
        "Lỗi lưu trữ: $e. (Bạn đang ở Chế độ Test, vui lòng Đăng nhập để chat)",
      );
    }

    try {
      // 3. Call Groq API
      final apiKey = AppConfig.groqApiKey;
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      final systemPrompt = '''
Bạn là Lovesense AI Coach - một chuyên gia khai vấn (Life Coach) và bạn tâm giao.
NHIỆM VỤ:
1.  **Khai vấn (Coaching)**: Đừng chỉ trả lời. Hãy đặt câu hỏi ngược lại để giúp người dùng tự nhận ra vấn đề (Phương pháp Socrates).
    - Ví dụ: Thay vì nói "Bạn nên ngủ sớm", hãy hỏi "Điều gì khiến bạn trằn trọc mỗi đêm?"
2.  **Đưa ra hành động cụ thể**:
    - Khi gợi ý một việc làm, HÃY BAO QUANH NÓ BẰNG THẺ <TASK>...</TASK>.
    - Ví dụ: "Để giảm căng thẳng, bạn hãy thử hít thở sâu nhé. <TASK>Tập hít thở 4-7-8</TASK>"
3.  **Luôn tích cực & Đồng cảm**: Không phán xét.

KỊCH BẢN ĐẶC BIỆT:
- Nếu người dùng nói "Bắt đầu" hoặc lần đầu gặp: Hãy chào mừng nồng nhiệt: "Chào bạn! Mình là AI Coach đây. Hôm nay thế giới bên trong bạn đang có màu sắc gì? (Vui, buồn, hay day dứt...)"
''';

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model':
              'llama-3.3-70b-versatile', // Latest Llama 3.3, excellent Vietnamese support
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': message},
          ],
          'temperature': 0.9,
          'max_tokens': 1000,
          'stream': false, // We'll implement streaming later if needed
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final aiResponse =
            data['choices']?[0]?['message']?['content'] ??
            'Xin lỗi, mình đang suy nghĩ một chút...';

        // 4. Stream the response (simulate streaming by sending full text)
        onStream?.call(aiResponse);

        // 5. Save AI Response
        await _saveMessageToDB(aiResponse, false);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      String errorMsg = "Lỗi kết nối AI: ${e.toString()}";

      // Friendly Error Messages
      if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        errorMsg = "⚠️ Lỗi: API Key không đúng hoặc đã hết hạn.";
      } else if (e.toString().contains('429') ||
          e.toString().contains('rate limit')) {
        errorMsg =
            "⚠️ Lỗi: Bạn đã gửi quá nhiều tin nhắn. Vui lòng đợi 1 phút.";
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        errorMsg = "⚠️ Lỗi: Không có kết nối Internet. Vui lòng kiểm tra mạng.";
      }

      onStream?.call(errorMsg);
      try {
        await _saveMessageToDB(errorMsg, false);
      } catch (dbError) {
        print("Lỗi lưu message báo lỗi vào DB: $dbError");
      }
    }
  }

  // --- Suggestions Logic ---
  List<String> getSuggestions() {
    if (!hasChatted) return [];

    return [
      'Viết 3 điều bạn biết ơn hôm nay',
      'Học bài "Tự yêu không ích kỷ" (5 phút)',
      'Thực hành thở bụng 3 phút',
    ];
  }
}
