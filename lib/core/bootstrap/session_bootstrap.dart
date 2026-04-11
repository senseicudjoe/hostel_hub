import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/announcement.dart';
import '../../models/user_model.dart';
import '../constants/app_constants.dart';
import '../providers/app_providers.dart';
import '../router/app_router.dart';

/// Hydrates [currentUserProvider] from Firestore when Firebase Auth has a
/// session. If the user has enabled biometric login, they are prompted to
/// authenticate before the session is restored — acting as an app lock.
///
/// Always sets [sessionBootstrapDoneProvider] to true when finished,
/// regardless of outcome, so the splash screen can stop waiting.
class SessionBootstrap extends ConsumerStatefulWidget {
  const SessionBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SessionBootstrap> createState() => _SessionBootstrapState();
}

class _SessionBootstrapState extends ConsumerState<SessionBootstrap> {
  bool _notificationsStarted = false;

  /// IDs of announcements seen so far — used to detect newly arrived ones.
  final Set<String> _seenAnnouncementIds = {};
  bool _firstAnnouncementLoad = true;
  StreamSubscription<List<Announcement>>? _announcementSub;

  @override
  void dispose() {
    _announcementSub?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateFromFirebase());
  }

  Future<void> _hydrateFromFirebase() async {
    try {
      final authUser = FirebaseAuth.instance.currentUser;

      // No Firebase session at all — signal done immediately so the splash
      // screen doesn't wait indefinitely.
      if (authUser == null) return;
      if (ref.read(currentUserProvider) != null) return;

      // ── Biometric gate ──────────────────────────────────────────
      final biometricEnabled = ref.read(biometricEnabledProvider);
      if (biometricEnabled) {
        final passed = await _promptBiometric();
        if (!passed) {
          // Biometric failed or cancelled — sign out so the router sends
          // the user to login.
          await FirebaseAuth.instance.signOut();
          return;
        }
      }

      // ── Hydrate session ─────────────────────────────────────────
      final profile = await ref
          .read(firestoreServiceProvider)
          .getUser(authUser.uid);
      if (!mounted || profile == null) return;

      ref.read(currentUserProvider.notifier).state = profile;
      await _syncNotifications(profile);
    } finally {
      // Always signal done — the splash screen is watching this flag.
      // We use a post-frame callback so the state write happens outside any
      // ongoing build phase.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(sessionBootstrapDoneProvider.notifier).state = true;
        }
      });
    }
  }

  Future<bool> _promptBiometric() async {
    final status = await ref.read(biometricAuthServiceProvider).getStatus();
    if (!status.isSupported) return true;

    return ref
        .read(biometricAuthServiceProvider)
        .authenticate(
          localizedReason: 'Verify your identity to access HostelHub',
        );
  }

  Future<void> _syncNotifications(UserModel user) async {
    if (_notificationsStarted) return;
    _notificationsStarted = true;
    try {
      final n = ref.read(notificationServiceProvider);
      await n.initialize();
      await n.saveFcmToken(user.uid);
      await n.subscribeToRole(user.role);

      // Fire the one-time welcome notification 5 s after the very first sign-in.
      await n.showWelcomeNotificationIfNeeded(user.name);

      // ── Real-time announcement notifications ──────────────────────────────
      // Students get a local notification whenever a new announcement is posted,
      // as long as the app is running (foreground or background).
      // Admins don't get notified for their own posts.
      if (user.role != AppConstants.roleAdmin) {
        _startAnnouncementListener(user.role);
      }
    } catch (_) {}
  }

  void _startAnnouncementListener(String role) {
    _announcementSub?.cancel();
    _announcementSub = ref
        .read(firestoreServiceProvider)
        .getAnnouncements(role)
        .listen((announcements) {
      if (!mounted) return;

      if (_firstAnnouncementLoad) {
        // Seed seen IDs on first load — don't notify for existing announcements.
        _seenAnnouncementIds.addAll(
          announcements.map((a) => a.announcementId),
        );
        _firstAnnouncementLoad = false;
        return;
      }

      for (final a in announcements) {
        if (_seenAnnouncementIds.contains(a.announcementId)) continue;
        _seenAnnouncementIds.add(a.announcementId);
        _showAnnouncementNotification(a);
      }
    });
  }

  void _showAnnouncementNotification(Announcement a) {
    ref.read(notificationServiceProvider).showAnnouncementNotification(
      title: a.title,
      body: a.body,
      onTap: () {
        if (mounted) {
          ref.read(routerProvider).go('/home/announcements');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UserModel?>(currentUserProvider, (prev, next) {
      if (next != null && prev == null) {
        _syncNotifications(next);
      }
    });

    return widget.child;
  }
}
