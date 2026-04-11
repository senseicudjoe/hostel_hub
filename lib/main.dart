import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/offline_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// main()
//
// Flutter apps always start here.
// Three things happen before the UI appears:
//   1. WidgetsFlutterBinding.ensureInitialized() — needed before async calls
//   2. Hive opens its boxes for offline caching
//   3. Firebase initialises before the UI appears
// ─────────────────────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Hive offline storage (boxes from AppConstants) ──────
  await Hive.initFlutter();
  await OfflineService.init();

  // ── Firebase ─────────────────────────────────────────────
  // If Firebase isn't set up for the current platform this throws.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('⚠️  Firebase init failed: $e');
  }

  // ── Run the app inside ProviderScope ─────────────────────
  // ProviderScope is the root of the Riverpod state tree.
  // Every ConsumerWidget can now call ref.watch() / ref.read().
  runApp(const ProviderScope(child: HostelHubApp()));
}
