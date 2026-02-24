import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/offline_service.dart';
import '../models/user_model.dart';

// Services
final authServiceProvider = Provider((_) => AuthService());
final firestoreServiceProvider = Provider((_) => FirestoreService());
final storageServiceProvider = Provider((_) => StorageService());
final notificationServiceProvider = Provider((_) => NotificationService());
final offlineServiceProvider = Provider((_) => OfflineService());

// Auth state stream
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Current user profile from Firestore
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return null;
  return ref.read(firestoreServiceProvider).getUser(authState.uid);
});

// Maintenance requests for current student
final studentRequestsProvider = StreamProvider<List<dynamic>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return const Stream.empty();
  return ref
      .read(firestoreServiceProvider)
      .getStudentMaintenanceRequests(user.uid);
});

// All maintenance requests (staff/admin)
final allRequestsProvider = StreamProvider((ref) {
  return ref.read(firestoreServiceProvider).getAllMaintenanceRequests();
});

// Announcements
final announcementsProvider = StreamProvider.family<List<dynamic>, String>(
  (ref, role) =>
      ref.read(firestoreServiceProvider).getAnnouncements(role),
);

// Shuttle schedules
final shuttleSchedulesProvider = StreamProvider((ref) {
  return ref.read(firestoreServiceProvider).getShuttleSchedules();
});

// Rooms
final roomsProvider = StreamProvider((ref) {
  return ref.read(firestoreServiceProvider).getRooms();
});