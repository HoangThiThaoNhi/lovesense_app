import 'dart:typed_data';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import '../models/video_model.dart';
import '../models/quiz_model.dart';
import '../models/article_model.dart';
import '../models/course_model.dart';
import '../models/policy_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- Policy Management ---

  Stream<List<PolicyModel>> getPoliciesStream() {
    return _firestore
        .collection('system')
        .doc('policies')
        .collection('items')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PolicyModel.fromDocument(doc))
              .toList();
        });
  }

  Future<void> updatePolicy(PolicyModel policy) async {
    await _firestore
        .collection('system')
        .doc('policies')
        .collection('items')
        .doc(policy.id)
        .set(policy.toMap());
  }

  // --- Users Management ---

  Stream<List<UserModel>> getUsersStream() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserModel.fromJson(doc.data()))
              .toList();
        });
  }

  Stream<List<UserModel>> getCreatorRequestsStream() {
    return _firestore
        .collection('users')
        .where('isCreatorRequestPending', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserModel.fromJson(doc.data()))
              .toList();
        });
  }

  // Create User (Auth + Firestore) using secondary app to preserve Admin session
  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      // Initialize a secondary app instance
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // Create user in Auth
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Write to Firestore immediately
      if (cred.user != null) {
        final newUser = UserModel(
          uid: cred.user!.uid,
          email: email,
          name: name,
          role: role,
          createdAt: DateTime.now(),
          status: UserStatus.active,
        );

        await _firestore
            .collection('users')
            .doc(newUser.uid)
            .set(newUser.toJson());
      }

      // Logout from secondary to be safe (though we delete app)
      await secondaryAuth.signOut();
    } catch (e) {
      throw Exception('Failed to create user: $e');
    } finally {
      // Clean up
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }
  }

  Future<void> updateUserRole(String uid, String newRole) async {
    await _firestore.collection('users').doc(uid).update({
      'role': newRole,
      'isCreatorRequestPending': false,
    });
  }

  Future<void> updateUserDetails({
    required String uid,
    String? name,
    String? role,
    String? status,
  }) async {
    final Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (role != null) updates['role'] = role;
    if (status != null) updates['status'] = status;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(updates);
    }
  }

  Future<void> deleteUser(String uid) async {
    // Hard delete from Firestore.
    // Note: This does NOT delete from Firebase Auth (requires Admin SDK / Cloud Functions)
    // We will mark generic status as 'deleted' or just remove doc.
    // User requested "Delete", let's hard delete doc.
    await _firestore.collection('users').doc(uid).delete();
  }

  // --- Content Management (Videos) ---

  Stream<QuerySnapshot> getVideosStream() {
    return _firestore
        .collection('content')
        .doc('videos')
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addVideo(VideoModel video) async {
    await _firestore
        .collection('content')
        .doc('videos')
        .collection('items')
        .doc() // Auto-id
        .set(video.toMap());
  }

  Future<void> deleteVideo(String id) async {
    await _firestore
        .collection('content')
        .doc('videos')
        .collection('items')
        .doc(id)
        .delete();
  }

  // --- Content Management (Articles) ---

  Stream<QuerySnapshot> getArticlesStream() {
    return _firestore
        .collection('content')
        .doc('papers') // FIXED: Use 'papers' instead of 'articles'
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addArticle(ArticleModel article) async {
    await _firestore
        .collection('content')
        .doc('papers') // FIXED
        .collection('items')
        .add(article.toMap());
  }

  Future<void> deleteArticle(String id) async {
    await _firestore
        .collection('content')
        .doc('papers') // FIXED
        .collection('items')
        .doc(id)
        .delete();
  }

  // --- Content Management (Courses) ---

  Stream<QuerySnapshot> getCoursesStream() {
    return _firestore
        .collection('content')
        .doc('courses')
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addCourse(CourseModel course) async {
    await _firestore
        .collection('content')
        .doc('courses')
        .collection('items')
        .add(course.toMap());
  }

  Future<void> deleteCourse(String id) async {
    await _firestore
        .collection('content')
        .doc('courses')
        .collection('items')
        .doc(id)
        .delete();
  }

  // --- Content Management (Quizzes) ---

  Stream<QuerySnapshot> getQuizzesStream() {
    return _firestore
        .collection('content')
        .doc('quizzes')
        .collection('items')
        .orderBy('startTime', descending: true)
        .snapshots();
  }

  Future<void> addQuiz(QuizModel quiz) async {
    await _firestore
        .collection('content')
        .doc('quizzes')
        .collection('items')
        .add(quiz.toMap());
  }

  Future<void> deleteQuiz(String id) async {
    await _firestore
        .collection('content')
        .doc('quizzes')
        .collection('items')
        .doc(id)
        .delete();
  }

  Future<void> deleteContent(String collection, String id) async {
    await _firestore
        .collection('content')
        .doc(collection)
        .collection('items')
        .doc(id)
        .delete();
  }

  Future<void> updateContentStatus(
    String type,
    String id,
    String status,
    bool isActive,
  ) async {
    final collection = type == 'video' ? 'videos' : 'quizzes';
    await _firestore
        .collection('content')
        .doc(collection)
        .collection('items')
        .doc(id)
        .update({'status': status, 'isActive': isActive});
  }

  Stream<QuerySnapshot> getContentStream() {
    // Main generic stream if needed, mostly specific ones used now
    return _firestore.collection('contents').snapshots();
  }

  Future<void> addContent(Map<String, dynamic> data) async {
    await _firestore.collection('contents').add(data);
  }

  // --- Storage ---

  Future<String> uploadFile(
    Uint8List fileBytes,
    String folder,
    String fileName,
  ) async {
    try {
      print("AdminService: Starting upload for $fileName to $folder");
      final ref = _storage.ref().child('$folder/$fileName');

      final metadata = SettableMetadata(
        contentType: fileName.endsWith('.mp4') ? 'video/mp4' : 'image/jpeg',
      );

      print("AdminService: Putting data...");
      final snapshot = await ref
          .putData(fileBytes, metadata)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('Upload timed out'),
          );
      print("AdminService: Data put. Getting URL...");
      final url = await snapshot.ref.getDownloadURL();
      print("AdminService: Got URL: $url");
      return url;
    } catch (e) {
      print("Upload Error: $e");
      rethrow;
    }
  }
}
