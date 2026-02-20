import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_service.dart';
import '../../models/video_model.dart';
import '../../models/article_model.dart';
import 'article_detail_screen.dart';
// import 'video_detail_screen.dart'; // Future

class ContentFeedScreen extends StatefulWidget {
  const ContentFeedScreen({super.key});

  @override
  State<ContentFeedScreen> createState() => _ContentFeedScreenState();
}

class _ContentFeedScreenState extends State<ContentFeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Khám phá', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: _buildStoryRow(),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFFFF4081),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFFFF4081),
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'Dành cho bạn'),
                    Tab(text: 'Theo dõi'),
                    Tab(text: 'Chủ đề'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildForYouFeed(),
            _buildFollowingFeed(), // Placeholder
            _buildTopicsFeed(),    // Placeholder
          ],
        ),
      ),
    );
  }

  Widget _buildStoryRow() {
    // Mock Stories
    final stories = [
      {'name': 'Admin', 'img': 'https://ui-avatars.com/api/?name=Admin', 'isLive': true},
      {'name': 'Dr. Pepper', 'img': 'https://ui-avatars.com/api/?name=Pepper', 'isLive': false},
      {'name': 'Love Guru', 'img': 'https://ui-avatars.com/api/?name=Guru', 'isLive': false},
      {'name': 'Yoga Daily', 'img': 'https://ui-avatars.com/api/?name=Yoga', 'isLive': false},
      {'name': 'Health+', 'img': 'https://ui-avatars.com/api/?name=Health', 'isLive': false},
    ];

    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final s = stories[index];
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: s['isLive'] == true ? Colors.red : const Color(0xFFFF4081), 
                    width: 2.5
                  ),
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(s['img'] as String),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s['name'] as String, 
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500)
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildForYouFeed() {
    return FutureBuilder(
      future: Future.wait([
        _adminService.getVideosStream().first,
        _adminService.getArticlesStream().first,
      ]),
      builder: (context, AsyncSnapshot<List<QuerySnapshot>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final videoDocs = snapshot.data?[0].docs ?? [];
        final articleDocs = snapshot.data?[1].docs ?? [];
        
        final mixed = [...videoDocs.map((d) => VideoModel.fromFirestore(d)), 
                       ...articleDocs.map((d) => ArticleModel.fromFirestore(d))];
        
        mixed.shuffle(); // Randomize for "For You" feel

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: mixed.length,
          separatorBuilder: (_, __) => const SizedBox(height: 24),
          itemBuilder: (context, index) {
            final item = mixed[index];
            if (item is VideoModel) {
              return _buildVideoFeedItem(item);
            } else {
              return _buildArticleFeedItem(item as ArticleModel);
            }
          },
        );
      },
    );
  }

  Widget _buildVideoFeedItem(VideoModel video) {
    return InkWell(
      onTap: () {
        // Navigate to Player
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Playing ${video.title} (Comming soon)")));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Lovesense Official", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text("Video • ${video.category}", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          // Content
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.network(video.thumbnailUrl, height: 200, width: double.infinity, fit: BoxFit.cover),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                ),
                Positioned(
                  bottom: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(4)),
                    child: Text(video.duration, style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(video.title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          // Actions
          Row(
            children: [
              const Icon(Icons.favorite_border, size: 20),
              const SizedBox(width: 4),
              const Text("1.2k"),
              const SizedBox(width: 20),
              const Icon(Icons.mode_comment_outlined, size: 20),
              const SizedBox(width: 4),
              const Text("45"),
              const Spacer(),
              const Icon(Icons.share_outlined, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArticleFeedItem(ArticleModel article) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: article)));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 16, backgroundImage: NetworkImage(article.authorAvatar)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.authorName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text("Article • ${article.category}", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(article.title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      article.description, 
                      maxLines: 3, 
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(color: Colors.grey[700], height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(article.imageUrl, width: 80, height: 80, fit: BoxFit.cover),
              ),
            ],
          ),
          const SizedBox(height: 12),
           Row(
            children: [
              Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text("${article.views} views", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text("5 min read", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFollowingFeed() => const Center(child: Text("Coming Soon: Following"));
  Widget _buildTopicsFeed() => const Center(child: Text("Coming Soon: Topics"));
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);
  @override
  double get minExtent => _tabBar.preferredSize.height + 1; // +1 for border
  @override
  double get maxExtent => _tabBar.preferredSize.height + 1;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _tabBar,
          const Divider(height: 1),
        ],
      ),
    );
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
