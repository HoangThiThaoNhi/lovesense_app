import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/blog_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection References
  CollectionReference get _blogsCollection => _firestore.collection('blogs');
  CollectionReference get _blogLikesCollection => _firestore.collection('blog_likes');
  CollectionReference get _blogBookmarksCollection => _firestore.collection('blog_bookmarks');
  CollectionReference get _blogCommentsCollection => _firestore.collection('blog_comments');
  CollectionReference get _blogViewsCollection => _firestore.collection('blog_views');

  // --- Blog CRUD ---

  Stream<List<BlogModel>> getBlogsStream({String? category, bool isAdmin = false, String? tag}) {
    Query query = _blogsCollection;

    if (!isAdmin) {
      query = query.where('status', isEqualTo: 'published');
    }

    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }
    
    if (tag != null) {
       query = query.where('tags', arrayContains: tag);
    }

    return query.snapshots().map((snapshot) {
      final blogs = snapshot.docs.map((doc) {
        return BlogModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      
      // Client-side sort
      blogs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return blogs;
    });
  }
  
  // Real-time stream for a single blog (Fixes Like/Comment count lag)
  Stream<BlogModel?> getBlogStream(String id) {
    return _blogsCollection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return BlogModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    });
  }
  
  Future<BlogModel?> getBlog(String id) async {
    final doc = await _blogsCollection.doc(id).get();
    if (!doc.exists) return null;
    return BlogModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  Future<void> createBlog(BlogModel blog) async {
    await _blogsCollection.add(blog.toMap());
  }

  Future<void> updateBlog(BlogModel blog) async {
    await _blogsCollection.doc(blog.id).update(blog.toMap());
  }
  
  Future<void> deleteBlog(String id) async {
    await _blogsCollection.doc(id).delete();
  }
  
  // Unique View Count Logic
  Future<void> incrementViewCount(String blogId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return; // Only count logged-in users or handle anonymous ID if needed

    final viewRef = _blogViewsCollection.doc('${blogId}_$uid');
    final viewDoc = await viewRef.get();

    if (!viewDoc.exists) {
      // New unique view
      await viewRef.set({
        'blogId': blogId,
        'userId': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      await _blogsCollection.doc(blogId).update({
        'viewCount': FieldValue.increment(1),
      });
    }
  }

  // --- Blog Interactions ---

  // Transactions for atomic updates
  Future<void> toggleLike(String blogId, String userId) async {
    final likeRef = _blogLikesCollection.where('blogId', isEqualTo: blogId).where('userId', isEqualTo: userId).limit(1);
    final blogRef = _blogsCollection.doc(blogId);
    
    final snapshot = await likeRef.get();
    final isLiked = snapshot.docs.isNotEmpty;

    if (isLiked) {
      // Unlike
      await snapshot.docs.first.reference.delete();
      await blogRef.update({'likeCount': FieldValue.increment(-1)});
    } else {
      // Like
      await _blogLikesCollection.add({
        'userId': userId,
        'blogId': blogId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await blogRef.update({'likeCount': FieldValue.increment(1)});
    }
  }
  
  Future<bool> hasLiked(String blogId, String userId) async {
     final snapshot = await _blogLikesCollection
        .where('blogId', isEqualTo: blogId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
     return snapshot.docs.isNotEmpty;
  }
  
  Future<void> toggleBookmark(String blogId, String userId) async {
    final bookmarkRef = _blogBookmarksCollection.where('blogId', isEqualTo: blogId).where('userId', isEqualTo: userId).limit(1);
    
    final snapshot = await bookmarkRef.get();
    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.delete();
      // Only delete bookmark, DO NOT touch likes
    } else {
      await _blogBookmarksCollection.add({
        'userId': userId,
        'blogId': blogId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
  
  Future<bool> isBookmarked(String blogId, String userId) async {
     final snapshot = await _blogBookmarksCollection
        .where('blogId', isEqualTo: blogId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
     return snapshot.docs.isNotEmpty;
  }

  // --- Comments & Replies ---

  Stream<List<BlogComment>> getCommentsStream(String blogId) {
    return _blogCommentsCollection
        .where('blogId', isEqualTo: blogId)
        .where('parentId', isNull: true) // Only top-level comments
        .snapshots()
        .map((snapshot) {
      final comments = snapshot.docs.map((doc) {
        return BlogComment.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      comments.sort((a,b) => b.createdAt.compareTo(a.createdAt));
      return comments;
    });
  }
  
  Stream<List<BlogComment>> getRepliesStream(String commentId) {
    return _blogCommentsCollection
        .where('parentId', isEqualTo: commentId)
        .snapshots()
        .map((snapshot) {
      final replies = snapshot.docs.map((doc) {
        return BlogComment.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      replies.sort((a,b) => a.createdAt.compareTo(b.createdAt)); // Oldest first for replies usually
      return replies;
    });
  }

  Future<void> addComment(BlogComment comment) async {
    await _blogCommentsCollection.add(comment.toMap());
    
    if (comment.parentId == null) {
      // Top-level comment -> Increment Blog comment count
      await _blogsCollection.doc(comment.blogId).update({
        'commentCount': FieldValue.increment(1),
      });
    } else {
      // Reply -> Increment Parent Comment reply count (Optional: AND Blog comment count if you want total interactions)
      // Usually replies also count towards total blog comments
      await _blogsCollection.doc(comment.blogId).update({
        'commentCount': FieldValue.increment(1),
      });
      
      // Update parent comment's reply count
      await _blogCommentsCollection.doc(comment.parentId).update({
        'replyCount': FieldValue.increment(1),
      });
    }
  }
  
  // --- Saved Blogs ---
  
  Stream<List<String>> getSavedBlogIdsStream(String userId) {
      return _blogBookmarksCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc['blogId'] as String).toList());
  }
}
