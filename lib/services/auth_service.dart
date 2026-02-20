import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';

class AuthService {
  // Use getters to avoid immediate instantiation crash if Firebase isn't initialized
  FirebaseAuth get _auth {
    if (Firebase.apps.isEmpty) {
      throw Exception(
        'Firebase chưa được cấu hình (Thiếu google-services.json)',
      );
    }
    return FirebaseAuth.instance;
  }

  FirebaseFirestore get _firestore {
    if (Firebase.apps.isEmpty) {
      throw Exception(
        'Firebase chưa được cấu hình (Thiếu google-services.json)',
      );
    }
    return FirebaseFirestore.instance;
  }

  // Stream of auth changes
  Stream<User?> get authStateChanges {
    if (Firebase.apps.isEmpty) return Stream.value(null);
    return _auth.authStateChanges();
  }

  // Current User
  User? get currentUser {
    if (Firebase.apps.isEmpty) return null;
    return _auth.currentUser;
  }

  // Sign In
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Sign Up
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    String role = 'single',
  }) async {
    // 1. Create User (with timeout to avoid indefinite waiting)
    try {
      final UserCredential cred = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));

      // 2. Update Display Name & Send Verification
      if (cred.user != null) {
        await cred.user!
            .updateDisplayName(name)
            .timeout(const Duration(seconds: 8));

        if (!cred.user!.emailVerified) {
          await cred.user!.sendEmailVerification();
        }
      }

      // 3. Save extra info to Firestore
      if (cred.user != null) {
        final userModel = UserModel(
          uid: cred.user!.uid,
          email: email,
          name: name,
          role: role,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(cred.user!.uid)
            .set(userModel.toJson())
            .timeout(const Duration(seconds: 10));
      }
    } on TimeoutException catch (_) {
      throw Exception(
        'Kết nối tới Firebase quá lâu — vui lòng kiểm tra mạng hoặc thử lại.',
      );
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset Password (Link based)
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Get User Stream using user_model
  Stream<UserModel?> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserModel.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  // Get single User
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
    } catch (e) {
      print("Error fetching user: $e");
    }
    return null;
  }

  // Ensure Firestore Doc Exists (Self-Healing)
  Future<void> ensureUserExists(User user) async {
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set(
          UserModel(
            uid: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? 'Người dùng',
            role: 'single',
            createdAt: DateTime.now(),
          ).toJson(),
        );
      }
    } catch (e) {
      print("Error ensuring user exists: $e");
    }
  }
}
