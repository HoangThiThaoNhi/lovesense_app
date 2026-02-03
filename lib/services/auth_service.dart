import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

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
  }) async {
    // 1. Create User
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 2. Update Display Name
    await cred.user?.updateDisplayName(name);

    // 3. Save extra info to Firestore (Optional but good practice)
    if (cred.user != null) {
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'email': email,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset Password
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
