import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Streams ──────────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ── Register ─────────────────────────────────────────────
  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = UserModel(
        uid:       credential.user!.uid,
        name:      name,
        email:     email,
        role:      role,
        createdAt: DateTime.now(),
      );

      await _db.collection('users').doc(user.uid).set(user.toMap());
      await credential.user!.sendEmailVerification();
      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Login ────────────────────────────────────────────────
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc = await _db
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (doc.exists) return UserModel.fromMap(doc.data()!);
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Logout ───────────────────────────────────────────────
  Future<void> logout() async => _auth.signOut();

  // ── Get current user profile ─────────────────────────────
  Future<UserModel?> getCurrentUserProfile() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) return UserModel.fromMap(doc.data()!);
    return null;
  }

  // ── Google Sign-In ───────────────────────────────────────
  Future<UserModel?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // user cancelled

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;

      // Existing user — load their profile
      final doc = await _db.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists) return UserModel.fromMap(doc.data()!);

      // First-time Google sign-in — create a student profile automatically
      final user = UserModel(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'Student',
        email: firebaseUser.email ?? googleUser.email,
        role: AppConstants.roleStudent,
        createdAt: DateTime.now(),
      );
      await _db.collection('users').doc(user.uid).set(user.toMap());
      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Email verification ───────────────────────────────────
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<bool> reloadAndCheckVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // ── Password reset ───────────────────────────────────────
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ── Error handler ────────────────────────────────────────
  String _handleError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}