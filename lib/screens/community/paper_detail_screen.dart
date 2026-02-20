import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/blog_model.dart';
import '../../services/content_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BlogDetailScreen extends StatefulWidget {
  final BlogModel blog;

  const BlogDetailScreen({super.key, required this.blog});

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  final ContentService _contentService = ContentService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _commentFocusNode = FocusNode();
  
  bool _isLiked = false;
  bool _isBookmarked = false;
  String? _replyToCommentId; // If set, we are replying to this comment
  String? _replyToUserName;
  
  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Unique view count logic is now handled in ContentService, just call it once
    _contentService.incrementViewCount(widget.blog.id);
    _checkInteractions();
  }
  
  void _checkInteractions() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final liked = await _contentService.hasLiked(widget.blog.id, uid);
      final bookmarked = await _contentService.isBookmarked(widget.blog.id, uid);
      if(mounted) {
         setState(() {
           _isLiked = liked;
           _isBookmarked = bookmarked;
         });
      }
    }
  }

  void _toggleLike() async {
     final uid = FirebaseAuth.instance.currentUser?.uid;
     if (uid == null) {
        _showAuthAlert();
        return;
     }
     
     // Optimistic UI update is risky with live streams, but we can toggle the local state
     // The count will update via stream
     setState(() => _isLiked = !_isLiked); 
     await _contentService.toggleLike(widget.blog.id, uid);
  }
  
  void _toggleBookmark() async {
     final uid = FirebaseAuth.instance.currentUser?.uid;
     if (uid == null) {
        _showAuthAlert();
        return;
     }

     setState(() => _isBookmarked = !_isBookmarked);
     await _contentService.toggleBookmark(widget.blog.id, uid);
     if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isBookmarked ? "Đã lưu bài viết" : "Đã bỏ lưu"),
          duration: const Duration(seconds: 1),
        ));
     }
  }
  
  void _prepareReply(String commentId, String userName) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToUserName = userName;
    });
    FocusScope.of(context).requestFocus(_commentFocusNode);
  }
  
  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToUserName = null;
    });
    _commentFocusNode.unfocus();
  }

  void _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
       _showAuthAlert();
       return;
    }

    final comment = BlogComment(
      id: '', 
      blogId: widget.blog.id,
      userId: user.uid,
      userName: user.displayName ?? 'Người dùng',
      userAvatar: user.photoURL ?? '',
      content: text,
      createdAt: Timestamp.now(),
      parentId: _replyToCommentId,
    );

    await _contentService.addComment(comment);
    _commentController.clear();
    _cancelReply(); // Reset reply state
  }
  
  void _showAuthAlert() {
     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập')));
  }

  @override
  Widget build(BuildContext context) {
    // Wrap entire body in StreamBuilder to get live updates for Like/View/Comment counts
    return StreamBuilder<BlogModel?>(
      stream: _contentService.getBlogStream(widget.blog.id),
      initialData: widget.blog, // Show initial data while loading
      builder: (context, snapshot) {
        final blog = snapshot.data ?? widget.blog; // Fallback to widget.blog if null
        
        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // App Bar with Image
                    SliverAppBar(
                      expandedHeight: 280.0,
                      floating: false,
                      pinned: true,
                      actions: [
                         IconButton(
                           icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                           onPressed: _toggleBookmark,
                         ),
                         IconButton(
                           icon: const Icon(Icons.share),
                           onPressed: () {},
                         ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          children: [
                            Positioned.fill(
                              child: blog.coverImage.isNotEmpty
                                  ? Image.network(blog.coverImage, fit: BoxFit.cover)
                                  : Container(color: Colors.grey),
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                                    stops: const [0.6, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Content
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Categories & Tags
                            Wrap(
                              spacing: 8,
                              children: [
                                 Chip(
                                   label: Text(blog.category.toUpperCase()),
                                   backgroundColor: const Color(0xFF6200EA),
                                   labelStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                   padding: EdgeInsets.zero,
                                 ),
                                 ...blog.tags.map((t) => Chip(
                                   label: Text("#$t"),
                                   backgroundColor: Colors.grey[200],
                                   labelStyle: TextStyle(color: Colors.blue[800], fontSize: 10),
                                 )),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Title
                            Text(
                              blog.title,
                              style: GoogleFonts.montserrat(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Meta Info (Date, Time, Views)
                            Row(
                               children: [
                                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${DateFormat('dd/MM/yyyy').format(blog.createdAt.toDate())} • ${blog.readingTime} min read",
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text("${blog.viewCount}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                               ],
                            ),
                            const SizedBox(height: 24),

                            // Description
                            if(blog.description.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.only(left: 12),
                                decoration: BoxDecoration(
                                  border: Border(left: BorderSide(color: const Color(0xFF6200EA).withOpacity(0.5), width: 3)),
                                ),
                                child: Text(
                                  blog.description,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            if(blog.description.isNotEmpty) const SizedBox(height: 24),

                            // Markdown Content
                            MarkdownBody(
                              data: blog.content,
                              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                                p: GoogleFonts.inter(fontSize: 16, height: 1.7, color: Colors.black87),
                                h1: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold),
                                h2: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold),
                                blockquote: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic),
                                listBullet: const TextStyle(fontSize: 16),
                              ),
                            ),
                            
                            const SizedBox(height: 40),
                            const Divider(),
                            
                            // Interaction Buttons
                            // Use server count directly. 
                            // If _isLiked is true but count hasn't updated yet, we could conditionally +1, 
                            // but simpler to trust stream or just highlight the button.
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildInteractionBtn(
                                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: _isLiked ? Colors.red : Colors.grey,
                                  label: "${blog.likeCount} Likes", 
                                  onTap: _toggleLike,
                                ),
                                _buildInteractionBtn(
                                  icon: Icons.comment_outlined,
                                  color: Colors.grey,
                                  label: "${blog.commentCount} Comments",
                                  onTap: () {
                                     // Scroll to comments?
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),
                            const Divider(),

                            // Comments Section Header
                            Text("Bình luận", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    
                    // Comments List (Root Comments Only)
                    SliverStreamBuilder<List<BlogComment>>(
                       stream: _contentService.getCommentsStream(blog.id),
                       builder: (context, snapshot) {
                          if (snapshot.hasError) return SliverToBoxAdapter(child: Text("Load error: ${snapshot.error}"));
                          if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                          
                          final comments = snapshot.data!;
                          if (comments.isEmpty) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(16), child: Text("Chưa có bình luận nào."))));

                          return SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return _buildCommentItem(comments[index]);
                              },
                              childCount: comments.length,
                            ),
                          );
                       },
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 80)), // Space for bottom input
                  ],
                ),
              ),
              
              // Bottom Input Area
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_replyToCommentId != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          color: Colors.grey[100],
                          child: Row(
                            children: [
                              Text("Replying to ${_replyToUserName ?? 'User'}", style: const TextStyle(fontSize: 12, color: Colors.blue)),
                              const Spacer(),
                              IconButton(icon: const Icon(Icons.close, size: 16), onPressed: _cancelReply),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                           Expanded(
                             child: TextField(
                               controller: _commentController,
                               focusNode: _commentFocusNode,
                               decoration: InputDecoration(
                                 hintText: _replyToCommentId != null ? "Viết câu trả lời..." : "Viết bình luận...",
                                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                                 contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                               ),
                             ),
                           ),
                           const SizedBox(width: 8),
                           IconButton(
                             icon: const Icon(Icons.send, color: Color(0xFF6200EA)),
                             onPressed: _postComment,
                           ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildCommentItem(BlogComment comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundImage: (comment.userAvatar != null && comment.userAvatar!.isNotEmpty) 
                ? NetworkImage(comment.userAvatar!) 
                : null,
            child: (comment.userAvatar == null || comment.userAvatar!.isEmpty) ? const Icon(Icons.person) : null,
          ),
          title: Text(comment.userName ?? 'Người dùng', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(comment.content),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    DateFormat('dd/MM HH:mm').format(comment.createdAt.toDate()),
                    style: TextStyle(color: Colors.grey[500], fontSize: 10),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => _prepareReply(comment.id, comment.userName ?? 'User'),
                    child: const Text("Reply", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Fetched Replies (Expansion Tile or always visible?)
        // Let's use a nested StreamBuilder but only if replyCount > 0
        if (comment.replyCount > 0)
          Padding(
            padding: const EdgeInsets.only(left: 64.0), // Indent replies
            child: StreamBuilder<List<BlogComment>>(
              stream: _contentService.getRepliesStream(comment.id),
              builder: (context, snapshot) {
                 if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                 return Column(
                   children: snapshot.data!.map((reply) => _buildReplyItem(reply)).toList(),
                 );
              },
            ),
          ),
       const Divider(height: 1),
      ],
    );
  }
  
  Widget _buildReplyItem(BlogComment reply) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 12,
        backgroundImage: (reply.userAvatar != null && reply.userAvatar!.isNotEmpty) 
            ? NetworkImage(reply.userAvatar!) 
            : null,
        child: (reply.userAvatar == null || reply.userAvatar!.isEmpty) ? const Icon(Icons.person, size: 12) : null,
      ),
      title: Text(reply.userName ?? 'Người dùng', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      subtitle: Text(reply.content, style: const TextStyle(fontSize: 13)),
      dense: true,
    );
  }
  
  Widget _buildInteractionBtn({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          children: [
             Icon(icon, color: color, size: 28),
             const SizedBox(height: 4),
             Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class SliverStreamBuilder<T> extends StreamBuilder<T> {
  const SliverStreamBuilder({super.key, required super.stream, required super.builder});
}
