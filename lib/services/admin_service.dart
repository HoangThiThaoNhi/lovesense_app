import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Users Management ---
  
  Stream<List<UserModel>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromJson(doc.data())).toList();
    });
  }
  
  Future<void> updateUserRole(String uid, String newRole) async {
    await _firestore.collection('users').doc(uid).update({'role': newRole});
  }

  Future<void> deleteUser(String uid) async {
    // Soft delete or hard delete depending on policy. 
    // For now, we update status to 'banned'
    await _firestore.collection('users').doc(uid).update({'status': 'banned'});
  }

  // --- Content Management ---

  Stream<QuerySnapshot> getContentStream() {
    return _firestore.collection('contents').orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> addContent({
    required String title,
    required String description,
    required String imageUrl,
    required String category,
  }) async {
    await _firestore.collection('contents').add({
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'createdAt': DateTime.now().toIso8601String(),
      'status': 'published',
      'views': 0,
    });
  }

  Future<void> deleteContent(String id) async {
    await _firestore.collection('contents').doc(id).delete();
  }
}
