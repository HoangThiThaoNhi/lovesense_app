import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class AIService {
  // Singleton pattern
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  GenerativeModel? _model;
  ChatSession? _chatSession;
  SharedPreferences? _prefs;
  
  // Dependencies
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  bool get hasChatted => _prefs?.getBool('ai_has_chatted') ?? false;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Validation
    const apiKey = AppConfig.googleApiKey;
    if (apiKey.contains('YOUR_GEMINI_API_KEY')) {
       // Allow proceeding but model will error if used. 
       // Ideally we could throw, but singleton init usually void.
    }

    // Enhanced Coach Persona with Structured output
    final systemPrompt = Content.text('''
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
    '''); // Indentation adjusted

    _model = GenerativeModel(
      model: 'gemini-1.5-flash', 
      apiKey: apiKey,
      systemInstruction: systemPrompt,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ],
      generationConfig: GenerationConfig(
        temperature: 0.9, 
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1000,
      ),
    );
    
    // Note: We don't start a session with history here immediately 
    // because we want to sync with Firestore history ideally.
    // For simplicity, we start a fresh session or strict request-response for now, 
    // but keeping `_chatSession` allows multi-turn context in one run.
    _chatSession = _model!.startChat();
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

  // --- Database Logic ---

  // --- Session Management ---
  String _currentSessionId = 'main_chat';
  String get currentSessionId => _currentSessionId;

  // Start a fresh session
  void startNewChat() {
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _chatSession = _model!.startChat(); 
  }

  // Load an existing session
  void loadChat(String sessionId) {
    _currentSessionId = sessionId;
    // We reset the model context. 
    // (Ideal: Load last few messages into history, but strict context is fine for now)
    _chatSession = _model!.startChat(); 
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

  // --- Database Logic ---

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
    // We use set(merge) to create the doc if it doesn't exist
    await chatDocRef.set({
      'lastMessage': text, // Snippet
      'lastMessageTime': FieldValue.serverTimestamp(),
      'id': _currentSessionId,
    }, SetOptions(merge: true));
  }

  // --- Interaction Logic ---

  Future<void> sendMessage(String message, {Function(String)? onStream}) async {
    await _ensureAuth(); // Try to get real UID to pass Security Rules
    
    if (_model == null) throw Exception("AI chưa được khởi tạo (Thiếu API Key)");
    
    // 1. Mark interaction state
    if (!hasChatted) {
      await _prefs?.setBool('ai_has_chatted', true);
    }

    // 2. Save User Message immediately
    try {
      await _saveMessageToDB(message, true);
    } catch (e) {
      // Common error: Permission Denied (because Test Mode has no Auth)
      throw Exception("Lỗi lưu trữ: $e. (Bạn đang ở Chế độ Test, vui lòng Đăng nhập để chat)");
    }

    try {
      // 3. Ensure Chat Session exists
      _chatSession ??= _model!.startChat();

      // 4. Send to AI (Streaming)
      final contentStream = _chatSession!.sendMessageStream(Content.text(message));
      
      StringBuffer buffer = StringBuffer();
      
      await for (final chunk in contentStream) {
         final text = chunk.text;
         if (text != null && text.isNotEmpty) {
           buffer.write(text);
           // Notify UI of partial content
           onStream?.call(buffer.toString());
         }
      }
      
      final fullText = buffer.toString().isEmpty 
          ? "Xin lỗi, mình đang suy nghĩ một chút..." 
          : buffer.toString();

      // 5. Save AI Response (Final)
      await _saveMessageToDB(fullText, false);

    } catch (e) {
      String errorMsg = "Lỗi: ${e.toString()}";
      
      // Friendly Error Messages
      if (e.toString().contains("User location is not supported")) {
        errorMsg = "⚠️ Lỗi: Google Gemini chưa hỗ trợ IP Việt Nam trực tiếp. \n👉 Giải pháp: Vui lòng bật VPN hoặc đổi API Key khác.";
      } else if (e.toString().contains("API key not valid")) {
        errorMsg = "⚠️ Lỗi: API Key không đúng. Hãy kiểm tra lại trong app_config.dart";
      } else if (e.toString().contains("429") || e.toString().contains("Quota")) {
         errorMsg = "⚠️ Lỗi: Hết lượt sử dụng (Quota Exceeded). Hãy đợi một chút.";
      }

      onStream?.call(errorMsg); 
      await _saveMessageToDB(errorMsg, false);
    }
  }

  // --- Suggestions Logic ---
  List<String> getSuggestions() {
    if (!hasChatted) return [];
    
    // Mock suggestions - In advanced version, analyze `getChatStream` content
    return [
      'Viết 3 điều bạn biết ơn hôm nay',
      'Học bài "Tự yêu không ích kỷ" (5 phút)',
      'Thực hành thở bụng 3 phút'
    ];
  }
}
