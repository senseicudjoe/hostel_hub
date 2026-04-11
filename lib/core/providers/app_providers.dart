import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/announcement.dart';
import '../../models/maintenance_request.dart';
import '../../models/room_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../services/offline_service.dart';
import '../../services/storage_service.dart';
import '../constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SERVICES
// ─────────────────────────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((_) => AuthService());
final biometricAuthServiceProvider = Provider<BiometricAuthService>(
  (_) => BiometricAuthService(),
);
final firestoreServiceProvider = Provider<FirestoreService>(
  (_) => FirestoreService(),
);
final storageServiceProvider = Provider<StorageService>(
  (_) => StorageService(),
);
final notificationServiceProvider = Provider<NotificationService>(
  (_) => NotificationService(),
);
final offlineServiceProvider = Provider<OfflineService>(
  (_) => OfflineService(),
);

// ─────────────────────────────────────────────────────────────────────────────
// SESSION USER
// ─────────────────────────────────────────────────────────────────────────────

final currentUserProvider = StateProvider<UserModel?>((ref) => null);

/// Flips to true once SessionBootstrap finishes — whether it found a session,
/// completed biometrics, or determined no user is signed in.
/// The splash screen waits for this before navigating so it never races
/// against an in-progress biometric prompt or Firestore fetch.
final sessionBootstrapDoneProvider = StateProvider<bool>((ref) => false);

final userRoleProvider = Provider<String>((ref) {
  return ref.watch(currentUserProvider)?.role ?? AppConstants.roleStudent;
});

final isAdminProvider = Provider<bool>((ref) {
  final r = ref.watch(userRoleProvider);
  return r == AppConstants.roleAdmin;
});

// ─────────────────────────────────────────────────────────────────────────────
// FIREBASE AUTH STREAM
// ─────────────────────────────────────────────────────────────────────────────

final firebaseAuthUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ─────────────────────────────────────────────────────────────────────────────
// THEME MODE — persisted in Hive settingsBox
// ─────────────────────────────────────────────────────────────────────────────

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_loadFromHive());

  static ThemeMode _loadFromHive() {
    try {
      final box = Hive.box(AppConstants.settingsBox);
      final isDark = box.get('darkMode', defaultValue: false) as bool;
      return isDark ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {
      return ThemeMode.light;
    }
  }

  void setDarkMode(bool isDark) {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    try {
      Hive.box(AppConstants.settingsBox).put('darkMode', isDark);
    } catch (_) {}
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (_) => ThemeModeNotifier(),
);

// ─────────────────────────────────────────────────────────────────────────────
// BIOMETRIC PREFERENCE — persisted in Hive settingsBox
// ─────────────────────────────────────────────────────────────────────────────

class BiometricNotifier extends StateNotifier<bool> {
  BiometricNotifier() : super(_load());

  static bool _load() {
    try {
      return Hive.box(
            AppConstants.settingsBox,
          ).get('biometricEnabled', defaultValue: false)
          as bool;
    } catch (_) {
      return false;
    }
  }

  void setEnabled(bool enabled) {
    state = enabled;
    try {
      Hive.box(AppConstants.settingsBox).put('biometricEnabled', enabled);
    } catch (_) {}
  }
}

final biometricEnabledProvider = StateNotifierProvider<BiometricNotifier, bool>(
  (_) => BiometricNotifier(),
);

// ─────────────────────────────────────────────────────────────────────────────
// DATA STREAMS
// ─────────────────────────────────────────────────────────────────────────────

final studentMaintenanceRequestsProvider =
    StreamProvider<List<MaintenanceRequest>>((ref) {
      final user = ref.watch(currentUserProvider);
      if (user == null) return const Stream.empty();
      return ref
          .read(firestoreServiceProvider)
          .getStudentMaintenanceRequests(user.uid);
    });

final allMaintenanceRequestsProvider = StreamProvider<List<MaintenanceRequest>>(
  (ref) {
    return ref.read(firestoreServiceProvider).getAllMaintenanceRequests();
  },
);

final maintenanceRequestProvider =
    StreamProvider.family<MaintenanceRequest?, String>((ref, requestId) {
      return ref
          .read(firestoreServiceProvider)
          .watchMaintenanceRequest(requestId);
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

final myRoomProvider = StreamProvider<RoomModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  if (user.roomNumber.trim().isEmpty || user.hostel.trim().isEmpty) {
    return Stream.value(null);
  }
  return ref.read(firestoreServiceProvider).watchStudentRoom(user.uid);
});

/// Other students sharing the same room as the current user.
final roommatesProvider = StreamProvider<List<UserModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null ||
      user.hostel.trim().isEmpty ||
      user.roomNumber.trim().isEmpty) {
    return Stream.value([]);
  }
  return ref
      .read(firestoreServiceProvider)
      .getRoommates(user.hostel, user.roomNumber, user.uid);
});
