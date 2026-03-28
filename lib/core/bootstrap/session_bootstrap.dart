import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../providers/app_providers.dart';

/// Hydrates [currentUserProvider] from Firestore when Firebase Auth already
/// has a session, and wires FCM when the user becomes non-null.
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

    final profile =
        await ref.read(firestoreServiceProvider).getUser(authUser.uid);
    if (!mounted || profile == null) return;
    ref.read(currentUserProvider.notifier).state = profile;
    await _syncNotifications(profile);
  }

  Future<void> _syncNotifications(UserModel user) async {
    if (_notificationsStarted) return;
    _notificationsStarted = true;
    try {
      final n = ref.read(notificationServiceProvider);
      await n.initialize();
      await n.saveFcmToken(user.uid);
      await n.subscribeToRole(user.role);
    } catch (_) {
      // FCM / local notifications optional when Firebase isn't fully configured.
    }
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
