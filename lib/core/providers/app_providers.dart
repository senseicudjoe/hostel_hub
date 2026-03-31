import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/announcement.dart';
import '../../models/maintenance_request.dart';
import '../../models/room_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../services/offline_service.dart';
import '../../services/storage_service.dart';
import '../constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SERVICES
// ─────────────────────────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((_) => AuthService());
final firestoreServiceProvider =
    Provider<FirestoreService>((_) => FirestoreService());
final storageServiceProvider = Provider<StorageService>((_) => StorageService());
final notificationServiceProvider =
    Provider<NotificationService>((_) => NotificationService());
final offlineServiceProvider =
    Provider<OfflineService>((_) => OfflineService());

// ─────────────────────────────────────────────────────────────────────────────
// SESSION USER (single source of truth for UI + navigation)
// Set by login / demo; hydrated on cold start if Firebase has a session.
// ─────────────────────────────────────────────────────────────────────────────

final currentUserProvider = StateProvider<UserModel?>((ref) => null);

final userRoleProvider = Provider<String>((ref) {
  return ref.watch(currentUserProvider)?.role ?? AppConstants.roleStudent;
});

final isAdminProvider = Provider<bool>((ref) {
  final r = ref.watch(userRoleProvider);
  return r == AppConstants.roleAdmin;
});

// ─────────────────────────────────────────────────────────────────────────────
// FIREBASE AUTH (for session hydration; demo users do not use Firebase Auth)
// ─────────────────────────────────────────────────────────────────────────────

final firebaseAuthUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ─────────────────────────────────────────────────────────────────────────────
// DATA — all streams respect logged-in user where applicable
// ─────────────────────────────────────────────────────────────────────────────

final studentMaintenanceRequestsProvider =
    StreamProvider<List<MaintenanceRequest>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref
      .read(firestoreServiceProvider)
      .getStudentMaintenanceRequests(user.uid);
});

final allMaintenanceRequestsProvider =
    StreamProvider<List<MaintenanceRequest>>((ref) {
  return ref.read(firestoreServiceProvider).getAllMaintenanceRequests();
});

/// Single maintenance request by id (detail screen).
final maintenanceRequestProvider =
    StreamProvider.family<MaintenanceRequest?, String>((ref, requestId) {
  return ref.read(firestoreServiceProvider).watchMaintenanceRequest(requestId);
});

final announcementsForRoleProvider =
    StreamProvider.family<List<Announcement>, String>((ref, role) {
  return ref.read(firestoreServiceProvider).getAnnouncements(role);
});

final roomsProvider = StreamProvider<List<RoomModel>>((ref) {
  return ref.read(firestoreServiceProvider).getRooms();
});

final availableRoomsProvider = StreamProvider<List<RoomModel>>((ref) {
  return ref.read(firestoreServiceProvider).getAvailableRooms();
});

/// Current student's allocated room (from active allocation → `rooms/{roomId}`).
/// Null if unassigned or no matching Firestore data (e.g. demo user without DB).
final myRoomProvider = StreamProvider<RoomModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  if (user.roomNumber.trim().isEmpty || user.hostel.trim().isEmpty) {
    return Stream.value(null);
  }
  return ref.read(firestoreServiceProvider).watchStudentRoom(user.uid);
});

// ─────────────────────────────────────────────────────────────────────────────
// DEMO USERS (explore UI without Firebase credentials)
// ─────────────────────────────────────────────────────────────────────────────

class DemoUsers {
  static UserModel get student => UserModel(
        uid: 'demo_student_001',
        name: 'Kofi Mensah',
        email: 'kofi.mensah@ashesi.edu.gh',
        role: AppConstants.roleStudent,
        hostel: 'Unity Hall',
        roomNumber: 'U-204',
        profileImageUrl: '',
        fcmToken: '',
        createdAt: DateTime.now(),
      );

  static UserModel get admin => UserModel(
        uid: 'demo_admin_001',
        name: 'Ama Boateng',
        email: 'ama.boateng@ashesi.edu.gh',
        role: AppConstants.roleAdmin,
        hostel: '',
        roomNumber: '',
        profileImageUrl: '',
        fcmToken: '',
        createdAt: DateTime.now(),
      );
}
