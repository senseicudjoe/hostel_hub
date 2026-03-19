import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FCM Background handler
//
// Must be a top-level function (not inside a class).
// Called when a push notification arrives while the app is in the background.
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 BG message: ${message.notification?.title}');
}

// ─────────────────────────────────────────────────────────────────────────────
// main()
//
// Flutter apps always start here.
// Three things happen before the UI appears:
//   1. WidgetsFlutterBinding.ensureInitialized() — needed before async calls
//   2. Hive opens its boxes for offline caching
//   3. Firebase initialises (try-catch so demo mode works without Firebase)
// ─────────────────────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Hive offline storage ────────────────────────────────
  await Hive.initFlutter();
  await Hive.openBox('pending_requests');
  await Hive.openBox('cache');

  // ── Firebase ─────────────────────────────────────────────
  // If Firebase isn't set up for the current platform this throws —
  // we catch it and let the app continue in demo mode.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('⚠️  Firebase init skipped (demo mode active): $e');
  }

  // ── Run the app inside ProviderScope ─────────────────────
  // ProviderScope is the root of the Riverpod state tree.
  // Every ConsumerWidget can now call ref.watch() / ref.read().
  runApp(
    const ProviderScope(
      child: HostelHubApp(),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HostelHubApp — Root Widget
//
// ConsumerWidget means it can read Riverpod providers.
// It reads routerProvider (go_router) and uses AppTheme.light.
// ─────────────────────────────────────────────────────────────────────────────
class HostelHubApp extends ConsumerWidget {
  const HostelHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'HostelHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
