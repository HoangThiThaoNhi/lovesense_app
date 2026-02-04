import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // Mock Data
  int? _selectedMoodIndex;
  final List<Map<String, dynamic>> _moods = [
    {'icon': Icons.sentiment_very_dissatisfied, 'label': 'Tệ', 'color': Colors.grey},
    {'icon': Icons.sentiment_dissatisfied, 'label': 'Buồn', 'color': Colors.blueGrey},
    {'icon': Icons.sentiment_neutral, 'label': 'Bình thường', 'color': Colors.amber},
    {'icon': Icons.sentiment_satisfied, 'label': 'Vui', 'color': Colors.lightGreen},
    {'icon': Icons.favorite, 'label': 'Hạnh phúc', 'color': Colors.pink},
  ];

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context) {
    // Get name or default to 'bạn'
    final String name = _currentUser?.displayName?.split(' ').last ?? 'bạn';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              _buildHeader(name),

              const SizedBox(height: 32),

              // 2. Mood Check-in
              _buildMoodCheckIn(),

              const SizedBox(height: 32),

              // 3. AI Coach Suggestion
              _buildAiSuggestion(),

              const SizedBox(height: 32),

              // 4. Daily To-Do List
              _buildToDoSection(),

              const SizedBox(height: 32),

              // 5. Recommended Courses (Dành cho bạn)
              _buildCoursesSection(),

              const SizedBox(height: 32),

              // 6. Community Highlights (Cộng đồng)
              _buildCommunitySection(),
              
              const SizedBox(height: 80), // Bottom padding for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAiChatbot,
        backgroundColor: const Color(0xFF6200EA),
        icon: const Icon(Icons.smart_toy, color: Colors.white),
        label: Text('AI Chat', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
      ).animate().scale(delay: 1.seconds),
    );
  }

  Widget _buildHeader(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_greeting, $name 🌱',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hôm nay bạn cảm thấy thế nào?',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            // Avatar Placeholder
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFF4081), width: 2),
              ),
              child: const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=32'), // Mock image
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn().moveY(begin: -20, end: 0);
  }

  Widget _buildMoodCheckIn() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cảm xúc của bạn',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_moods.length, (index) {
              final mood = _moods[index];
              final isSelected = _selectedMoodIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMoodIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? mood['color'].withOpacity(0.1) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: mood['color'], width: 2) : Border.all(color: Colors.transparent, width: 2),
                  ),
                  child: Icon(
                    mood['icon'],
                    size: 32,
                    color: isSelected ? mood['color'] : Colors.grey[400],
                  ),
                ).animate(target: isSelected ? 1 : 0).scale(begin: const Offset(1,1), end: const Offset(1.2, 1.2)),
              );
            }),
          ),
          if (_selectedMoodIndex == null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {}, // Scroll to mood or trigger selection focus
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFCE4EC),
                    elevation: 0,
                    foregroundColor: const Color(0xFFFF4081),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Check-in ngay"),
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0);
  }

  Widget _buildAiSuggestion() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Gợi ý từ AI Coach',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
              IconButton( // Quick Chat Trigger
                onPressed: _showAiChatbot,
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.blueAccent, size: 20),
                tooltip: 'Hỏi AI ngay',
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hôm nay bạn có thể thử:',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          _buildAiActionItem('Viết 3 điều bạn biết ơn'),
          _buildAiActionItem('Học bài "Tự yêu không ích kỷ" (5 phút)'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showAiChatbot,
              icon: const Icon(Icons.question_answer_rounded, size: 16),
              label: const Text("Tâm sự cùng AI"),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.5),
                foregroundColor: Colors.blue[800],
                side: BorderSide(color: Colors.blue.withOpacity(0.3)),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).scale();
  }

  Widget _buildAiActionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.arrow_right_alt, size: 18, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // --- New Features ---

  // Mock To-Do Data
  final List<Map<String, dynamic>> _todoList = [
    {'task': 'Uống đủ 2 lít nước', 'done': false},
    {'task': 'Đọc 5 trang sách', 'done': true},
    {'task': 'Viết nhật ký cảm xúc', 'done': false},
  ];

  Widget _buildToDoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Danh sách việc cần làm',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: () {
                // Mock Add Task
                setState(() {
                  _todoList.add({'task': 'Nhiệm vụ mới', 'done': false});
                });
              },
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFF4081)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._todoList.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> item = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: item['done'] ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
              ),
              boxShadow: [
                 BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      item['done'] = !item['done'];
                      _todoList[index] = item;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item['done'] ? Colors.green : Colors.transparent,
                      border: Border.all(
                        color: item['done'] ? Colors.green : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: item['done']
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['task'],
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      decoration: item['done'] ? TextDecoration.lineThrough : null,
                      color: item['done'] ? Colors.grey : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildCommunitySection() {
    // Mock Community Posts
    final List<Map<String, String>> posts = [
      {
        'user': 'An Nhiên',
        'title': 'Cách mình vượt qua áp lực đồng trang lứa',
        'likes': '124',
        'image': 'https://picsum.photos/id/1/200/200'
      },
      {
        'user': 'Minh Nhật',
        'title': 'Góc làm việc chill chill cuối tuần 🌿',
        'likes': '89',
        'image': 'https://picsum.photos/id/2/200/200'
      },
      {
        'user': 'Thảo Chi',
        'title': 'Hành trình chữa lành sau chia tay',
        'likes': '256',
        'image': 'https://picsum.photos/id/3/200/200'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cộng đồng Lovesense',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text('Xem tất cả >', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: posts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final post = posts[index];
              return Container(
                width: 260,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        post['image']!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(width: 100, height: 100, color: Colors.grey[200]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            post['title']!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const CircleAvatar(radius: 8, backgroundColor: Colors.pink, child: Icon(Icons.person, size: 10, color: Colors.white)),
                              const SizedBox(width: 4),
                              Text(post['user']!, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600])),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.favorite, size: 12, color: Colors.redAccent),
                              const SizedBox(width: 4),
                              Text('${post['likes']} chanh sả', style: GoogleFonts.inter(fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms).moveX(begin: 30, end: 0);
  }

  void _showAiChatbot() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildChatbotSheet(),
    );
  }

  Widget _buildChatbotSheet() {
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
          // Chat Header
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
                        Text('Luôn lắng nghe bạn', style: GoogleFonts.inter(fontSize: 12, color: Colors.green)),
                      ],
                    ),
                  ],
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
          ),
          const Divider(),
          // Chat Area (Mock)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildChatMessage(
                  isUser: false,
                  message: 'Chào bạn! Mình là AI Coach của Lovesense. Hôm nay mình có thể giúp gì cho bạn? \n\n• Gợi ý bài tập thư giãn?\n• Lời khuyên về tình cảm?\n• Hay chỉ đơn giản là tâm sự?',
                ),
                _buildChatMessage(
                  isUser: true,
                  message: 'Mình cảm thấy hơi mệt mỏi với công việc...',
                ),
                 _buildChatMessage(
                  isUser: false,
                  message: 'Mình hiểu cảm giác đó. Áp lực công việc đôi khi khiến ta kiệt sức. Bạn có muốn thử bài "Thiền buông thư" 5 phút không? Hoặc mình có thể kể một câu chuyện vui nhé?',
                ),
              ],
            ),
          ),
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
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
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
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage({required bool isUser, required String message}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
          message,
          style: GoogleFonts.inter(
            color: isUser ? Colors.white : Colors.black87,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCoursesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dành cho bạn',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _buildCourseCard('Chữa lành đứa trẻ bên trong', '15 phút', Colors.pink[100]!),
              const SizedBox(width: 16),
              _buildCourseCard('Quản lý cảm xúc tiêu cực', '10 phút', Colors.green[100]!),
              const SizedBox(width: 16),
              _buildCourseCard('Xây dựng sự tự tin', '20 phút', Colors.blue[100]!),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms).moveX(begin: 50, end: 0);
  }

  Widget _buildCourseCard(String title, String duration, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow_rounded, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                duration,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
