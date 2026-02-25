import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CURRENT USER
// This is the single source of truth for who is logged in.
// Screens read this to show personalised content.
// ─────────────────────────────────────────────────────────────────────────────

/// Holds the currently authenticated user (null = logged out).
final currentUserProvider = StateProvider<UserModel?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// DERIVED PROVIDERS
// These compute values from currentUserProvider so we don't repeat ourselves.
// ─────────────────────────────────────────────────────────────────────────────

/// Convenience: the user's role string ('student', 'admin', etc.)
final userRoleProvider = Provider<String>((ref) {
  return ref.watch(currentUserProvider)?.role ?? 'student';
});

/// Convenience: true if the logged-in user is an admin.
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(userRoleProvider) == 'admin';
});

// ─────────────────────────────────────────────────────────────────────────────
// DEMO USERS
// These are pre-built fake users so you can explore every screen
// without needing a real Firebase connection.
// ─────────────────────────────────────────────────────────────────────────────

class DemoUsers {
  /// A student resident in Unity Hall.
  static UserModel get student => UserModel(
    uid: 'demo_student_001',
    name: 'Kofi Mensah',
    email: 'kofi.mensah@ashesi.edu.gh',
    role: 'student',
    hostel: 'Unity Hall',
    roomNumber: 'U-204',
    profileImageUrl: '',
    fcmToken: '',
    createdAt: DateTime.now(),
  );

  /// An SLE administrator.
  static UserModel get admin => UserModel(
    uid: 'demo_admin_001',
    name: 'Ama Boateng',
    email: 'ama.boateng@ashesi.edu.gh',
    role: 'admin',
    hostel: '',
    roomNumber: '',
    profileImageUrl: '',
    fcmToken: '',
    createdAt: DateTime.now(),
  );
}
