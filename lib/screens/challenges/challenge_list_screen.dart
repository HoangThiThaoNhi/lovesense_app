import 'package:flutter/material.dart';
import '../../models/challenge_model.dart';
import '../../services/challenge_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'quiz_screen.dart';

class ChallengeListScreen extends StatefulWidget {
  const ChallengeListScreen({super.key});

  @override
  State<ChallengeListScreen> createState() => _ChallengeListScreenState();
}

class _ChallengeListScreenState extends State<ChallengeListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChallengeService _challengeService = ChallengeService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF8E2DE2),
                      Color(0xFF4A00E0),
                    ], // Purple Gradient
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Xin chào, Alex!",
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Sẵn sàng cho thử thách hôm nay?",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.flash_on,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "5 Ngày Stream",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Stats Row
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStat('Cấp độ', '5', Icons.star),
                            _buildVerticalDivider(),
                            _buildStat('XP', '1,250', Icons.auto_awesome),
                            _buildVerticalDivider(),
                            _buildStat('Huy hiệu', '12', Icons.emoji_events),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              title: const Text(
                'Thử thách',
                style: TextStyle(color: Colors.white),
              ),
              centerTitle: true,
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.amber,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: "Hằng Ngày"),
                Tab(text: "Hằng Tuần"),
                Tab(text: "Chủ Đề"),
              ],
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChallengeList(ChallengeType.daily),
                _buildChallengeList(ChallengeType.weekly),
                _buildChallengeList(ChallengeType.topic),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() =>
      Container(height: 30, width: 1, color: Colors.white24);

  Widget _buildChallengeList(ChallengeType type) {
    return StreamBuilder<List<ChallengeModel>>(
      stream: _challengeService.getChallengesStream(
        type: type.name,
      ), // Filter logic needs fixing in service to accept string or enum, using string in prev service code
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final challenges = snapshot.data ?? [];
        if (challenges.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  "Không có thử thách nào.",
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: challenges.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder:
              (context, index) => _ChallengeCard(challenge: challenges[index]),
        );
      },
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;
  const _ChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Start Quiz
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuizScreen(quizId: challenge.quizId),
          ),
        );
      },
      child:
          Container(
            height: 140,
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
                // Image / Icon Section
                Container(
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(challenge.coverUrl),
                      fit: BoxFit.cover,
                      onError: (_, __) => {}, // Placeholder handled by color
                    ),
                    color: Colors.grey[200],
                  ),
                  child:
                      challenge.coverUrl.isEmpty
                          ? const Center(
                            child: Icon(
                              Icons.gamepad,
                              size: 40,
                              color: Colors.grey,
                            ),
                          )
                          : null,
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getDiffColor(
                                  challenge.difficulty,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                challenge.difficulty.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getDiffColor(challenge.difficulty),
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.timer,
                              size: 14,
                              color: Colors.grey,
                            ),
                            Text(
                              " ${challenge.timeLeft}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          challenge.title,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "+ ${challenge.xpReward} XP",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Action Icon
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    backgroundColor: Colors.purple[50],
                    child: const Icon(Icons.play_arrow, color: Colors.purple),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideX(),
    );
  }

  Color _getDiffColor(String diff) {
    switch (diff) {
      case 'Easy':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'Hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
