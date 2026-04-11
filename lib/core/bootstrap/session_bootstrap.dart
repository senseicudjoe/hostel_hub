import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../providers/app_providers.dart';

/// Hydrates [currentUserProvider] from Firestore when Firebase Auth has a
/// session. If the user has enabled biometric login, they are prompted to
/// authenticate before the session is restored — acting as an app lock.
class SessionBootstrap extends ConsumerStatefulWidget {
  const SessionBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SessionBootstrap> createState() => _SessionBootstrapState();
}

class _SessionBootstrapState extends ConsumerState<SessionBootstrap> {
  bool _notificationsStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateFromFirebase());
  }

  Future<void> _hydrateFromFirebase() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;
    if (ref.read(currentUserProvider) != null) return;

    // ── Biometric gate ──────────────────────────────────────────
    final biometricEnabled = ref.read(biometricEnabledProvider);
    if (biometricEnabled) {
      final passed = await _promptBiometric();
      if (!passed) {
        // Biometric failed or was cancelled — sign the user out so they
        // reach the normal login screen instead of the dashboard.
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
    } catch (_) {}
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
