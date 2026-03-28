import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/offline_service.dart';

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

  // ── Hive offline storage (boxes from AppConstants) ──────
  await Hive.initFlutter();
  await OfflineService.init();

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
