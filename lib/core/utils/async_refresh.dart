import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

extension WidgetRefAsyncRefresh on WidgetRef {
  /// Invalidates a Riverpod async provider and waits for the next value.
  ///
  /// Use with [StreamProvider] / [FutureProvider] (including `.family`).
  Future<void> refreshProvider(Object provider) async {
    invalidate(provider as ProviderOrFamily);
    try {
      // `.future` exists on generated provider types but not on [Object].
      // ignore: avoid_dynamic_calls
      await read((provider as dynamic).future);
    } catch (_) {}
  }

  /// Reloads the signed-in user document from Firestore into [currentUserProvider].
  Future<void> reloadCurrentUserFromFirestore() async {
    final user = read(currentUserProvider);
    if (user == null) return;
    try {
      final fresh = await read(firestoreServiceProvider).getUser(user.uid);
      if (fresh != null) {
        read(currentUserProvider.notifier).state = fresh;
      }
    } catch (_) {}
  }
}
