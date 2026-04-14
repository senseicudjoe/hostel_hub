import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:light/light.dart';

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
// AMBIENT DARK MODE — three strategies persisted in Hive settingsBox
// ─────────────────────────────────────────────────────────────────────────────

/// Which strategy drives dark-mode switching.
enum DarkModeStrategy { manual, scheduled, sensor }

/// Full configuration for the ambient dark mode feature.
class DarkModeConfig {
  final DarkModeStrategy strategy;

  /// Used only in [DarkModeStrategy.manual].
  final bool manualDark;

  /// Used only in [DarkModeStrategy.scheduled].
  /// Dark mode activates from [scheduleStartHour]:[scheduleStartMinute]
  /// until [scheduleEndHour]:[scheduleEndMinute] (supports overnight ranges).
  final int scheduleStartHour;
  final int scheduleStartMinute;
  final int scheduleEndHour;
  final int scheduleEndMinute;

  /// Used only in [DarkModeStrategy.sensor].
  /// When ambient lux drops below this value the app switches to dark mode.
  final double luxThreshold;

  const DarkModeConfig({
    this.strategy = DarkModeStrategy.manual,
    this.manualDark = false,
    this.scheduleStartHour = 19,
    this.scheduleStartMinute = 0,
    this.scheduleEndHour = 7,
    this.scheduleEndMinute = 0,
    this.luxThreshold = 50.0,
  });

  DarkModeConfig copyWith({
    DarkModeStrategy? strategy,
    bool? manualDark,
    int? scheduleStartHour,
    int? scheduleStartMinute,
    int? scheduleEndHour,
    int? scheduleEndMinute,
    double? luxThreshold,
  }) {
    return DarkModeConfig(
      strategy: strategy ?? this.strategy,
      manualDark: manualDark ?? this.manualDark,
      scheduleStartHour: scheduleStartHour ?? this.scheduleStartHour,
      scheduleStartMinute: scheduleStartMinute ?? this.scheduleStartMinute,
      scheduleEndHour: scheduleEndHour ?? this.scheduleEndHour,
      scheduleEndMinute: scheduleEndMinute ?? this.scheduleEndMinute,
      luxThreshold: luxThreshold ?? this.luxThreshold,
    );
  }

  /// Read from an open Hive box; falls back to defaults if keys are absent.
  static DarkModeConfig fromHive(Box box) {
    final stratStr =
        box.get('darkModeStrategy', defaultValue: 'manual') as String;
    return DarkModeConfig(
      strategy: DarkModeStrategy.values.firstWhere(
        (s) => s.name == stratStr,
        orElse: () => DarkModeStrategy.manual,
      ),
      manualDark: box.get('manualDark', defaultValue: false) as bool,
      scheduleStartHour:
          box.get('scheduleStartHour', defaultValue: 19) as int,
      scheduleStartMinute:
          box.get('scheduleStartMinute', defaultValue: 0) as int,
      scheduleEndHour: box.get('scheduleEndHour', defaultValue: 7) as int,
      scheduleEndMinute:
          box.get('scheduleEndMinute', defaultValue: 0) as int,
      luxThreshold:
          (box.get('luxThreshold', defaultValue: 50.0) as num).toDouble(),
    );
  }

  void save(Box box) {
    box.put('darkModeStrategy', strategy.name);
    box.put('manualDark', manualDark);
    box.put('scheduleStartHour', scheduleStartHour);
    box.put('scheduleStartMinute', scheduleStartMinute);
    box.put('scheduleEndHour', scheduleEndHour);
    box.put('scheduleEndMinute', scheduleEndMinute);
    box.put('luxThreshold', luxThreshold);
  }
}

/// Reactive mirror of [DarkModeConfig] — watched by the settings and profile
/// screens so they rebuild whenever the strategy or config changes, even when
/// the effective [ThemeMode] stays the same (e.g. switching from Sensor to
/// Manual when both currently resolve to light mode).
final darkModeConfigProvider = StateProvider<DarkModeConfig>((ref) {
  try {
    return DarkModeConfig.fromHive(Hive.box(AppConstants.settingsBox));
  } catch (_) {
    return const DarkModeConfig();
  }
});

/// Manages the effective [ThemeMode] based on the user's chosen strategy.
/// Handles side-effects (timers, sensor streams) internally and cleans up
/// when strategies change or the notifier is disposed.
class AmbientThemeNotifier extends StateNotifier<ThemeMode> {
  AmbientThemeNotifier(this._ref) : super(ThemeMode.light) {
    _init();
  }

  final Ref _ref;

  DarkModeConfig _config = const DarkModeConfig();
  Timer? _scheduleTimer;
  StreamSubscription<int>? _lightSub;

  /// The most recent raw lux value from the ambient light sensor.
  /// Only populated when [DarkModeStrategy.sensor] is active.
  int? lastLux;

  DarkModeConfig get config => _config;

  void _init() {
    try {
      final box = Hive.box(AppConstants.settingsBox);
      // Migration: honour the old single 'darkMode' bool if present.
      final legacyDark = box.get('darkMode') as bool?;
      if (legacyDark != null && !box.containsKey('darkModeStrategy')) {
        _config = DarkModeConfig(
          strategy: DarkModeStrategy.manual,
          manualDark: legacyDark,
        );
        _config.save(box);
        // Sync the reactive config provider after legacy migration so the
        // settings screen sees the migrated value immediately.
        try {
          _ref.read(darkModeConfigProvider.notifier).state = _config;
        } catch (_) {}
      } else {
        _config = DarkModeConfig.fromHive(box);
      }
    } catch (_) {}
    _applyStrategy();
  }

  /// Apply a new configuration and persist it.
  void updateConfig(DarkModeConfig newConfig) {
    _config = newConfig;
    try {
      newConfig.save(Hive.box(AppConstants.settingsBox));
    } catch (_) {}
    // Sync the reactive config provider so the settings and profile screens
    // rebuild even when ThemeMode doesn't change (e.g. switching strategy
    // between two modes that both currently resolve to the same ThemeMode).
    try {
      _ref.read(darkModeConfigProvider.notifier).state = newConfig;
    } catch (_) {}
    _applyStrategy();
  }

  // ── Convenience helpers used by profile screen ─────────────────────────────

  /// Quick toggle for manual mode (matches old setDarkMode API).
  void setDarkMode(bool isDark) {
    updateConfig(_config.copyWith(
      strategy: DarkModeStrategy.manual,
      manualDark: isDark,
    ));
  }

  // ── Strategy dispatcher ───────────────────────────────────────────────────

  void _applyStrategy() {
    _cancelSideEffects();
    switch (_config.strategy) {
      case DarkModeStrategy.manual:
        state = _config.manualDark ? ThemeMode.dark : ThemeMode.light;

      case DarkModeStrategy.scheduled:
        state = _withinSchedule() ? ThemeMode.dark : ThemeMode.light;
        // Re-evaluate every minute so transitions happen on time.
        _scheduleTimer = Timer.periodic(const Duration(minutes: 1), (_) {
          final next = _withinSchedule() ? ThemeMode.dark : ThemeMode.light;
          if (next != state) state = next;
        });

      case DarkModeStrategy.sensor:
        _startSensorMode();
    }
  }

  bool _withinSchedule() {
    final now = DateTime.now();
    final cur = now.hour * 60 + now.minute;
    final start =
        _config.scheduleStartHour * 60 + _config.scheduleStartMinute;
    final end = _config.scheduleEndHour * 60 + _config.scheduleEndMinute;

    // Overnight range (e.g., 19:00 → 07:00): cur >= start OR cur < end
    // Same-day range (e.g., 08:00 → 18:00): cur >= start AND cur < end
    return start > end
        ? (cur >= start || cur < end)
        : (cur >= start && cur < end);
  }

  void _startSensorMode() {
    // light v5 supports Android and iOS (SensorKit) — returns an empty stream
    // on unsupported platforms, so no explicit platform guard is needed.
    DateTime? lastSwitch;

    _lightSub = Light().lightSensorStream.listen(
      (lux) {
        if (lux < 0) return; // -1 is the sentinel for a parse error
        lastLux = lux;

        // Debounce: wait 2 s between theme switches to avoid flicker.
        final now = DateTime.now();
        final stable = lastSwitch == null ||
            now.difference(lastSwitch!) >= const Duration(seconds: 2);
        if (!stable) return;

        final shouldBeDark = lux < _config.luxThreshold;
        final next = shouldBeDark ? ThemeMode.dark : ThemeMode.light;
        if (next != state) {
          state = next;
          lastSwitch = now;
        }
      },
      onError: (_) {
        // Sensor unavailable on this device — fall back to system theme.
        state = ThemeMode.system;
      },
    );
  }

  void _cancelSideEffects() {
    _scheduleTimer?.cancel();
    _scheduleTimer = null;
    _lightSub?.cancel();
    _lightSub = null;
  }

  @override
  void dispose() {
    _cancelSideEffects();
    super.dispose();
  }
}

final themeModeProvider = StateNotifierProvider<AmbientThemeNotifier, ThemeMode>(
  (ref) => AmbientThemeNotifier(ref),
);

/// Live lux stream — only active while the ambient-dark-mode settings screen
/// is open (autoDispose). Returns an empty stream on unsupported platforms.
final luxReadingProvider = StreamProvider.autoDispose<int>((ref) {
  try {
    return Light().lightSensorStream.where((lux) => lux >= 0);
  } catch (_) {
    return const Stream.empty();
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATION PREFERENCES — persisted in Hive settingsBox
// ─────────────────────────────────────────────────────────────────────────────

class NotificationPrefs {
  final bool maintenanceNotifs;
  final bool announcementNotifs;

  const NotificationPrefs({
    this.maintenanceNotifs = true,
    this.announcementNotifs = true,
  });

  NotificationPrefs copyWith({bool? maintenanceNotifs, bool? announcementNotifs}) {
    return NotificationPrefs(
      maintenanceNotifs: maintenanceNotifs ?? this.maintenanceNotifs,
      announcementNotifs: announcementNotifs ?? this.announcementNotifs,
    );
  }

  static NotificationPrefs fromHive(Box box) {
    return NotificationPrefs(
      maintenanceNotifs:
          box.get('notifMaintenance', defaultValue: true) as bool,
      announcementNotifs:
          box.get('notifAnnouncements', defaultValue: true) as bool,
    );
  }

  void save(Box box) {
    box.put('notifMaintenance', maintenanceNotifs);
    box.put('notifAnnouncements', announcementNotifs);
  }
}

class NotificationPrefsNotifier extends StateNotifier<NotificationPrefs> {
  NotificationPrefsNotifier() : super(_load());

  static NotificationPrefs _load() {
    try {
      return NotificationPrefs.fromHive(Hive.box(AppConstants.settingsBox));
    } catch (_) {
      return const NotificationPrefs();
    }
  }

  void _persist() {
    try {
      state.save(Hive.box(AppConstants.settingsBox));
    } catch (_) {}
  }

  void setMaintenanceNotifs(bool v) {
    state = state.copyWith(maintenanceNotifs: v);
    _persist();
  }

  void setAnnouncementNotifs(bool v) {
    state = state.copyWith(announcementNotifs: v);
    _persist();
  }
}

final notificationPrefsProvider =
    StateNotifierProvider<NotificationPrefsNotifier, NotificationPrefs>(
  (_) => NotificationPrefsNotifier(),
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
