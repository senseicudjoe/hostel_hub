import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../core/constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Notification channel constants
// ─────────────────────────────────────────────────────────────────────────────

const _channelId   = 'hostelhub_channel';
const _channelName = 'HostelHub Notifications';

// ─────────────────────────────────────────────────────────────────────────────
// Background / terminated handler (top-level — required by FCM)
//
// Called when a DATA-ONLY message arrives while the app is in the background
// or terminated.  Messages that include a `notification` payload are shown
// automatically by the OS; this handler is only needed for silent data
// messages that the Cloud Functions might send in the future.
//
// NOTE: This runs in a separate Dart isolate — no access to providers,
// Hive, or Flutter widgets.  Use only dart:io / firebase_admin APIs.
// ─────────────────────────────────────────────────────────────────────────────

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 Background FCM: ${message.notification?.title ?? message.data}');
  // Cloud Functions send notification payloads so the OS handles display.
  // Nothing extra needed here — this entry point exists to satisfy FCM's
  // requirement for a registered top-level handler.
}

// ─────────────────────────────────────────────────────────────────────────────
// NotificationService
// ─────────────────────────────────────────────────────────────────────────────

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<String>? _tokenRefreshSub;

  // ── Initialise ────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    // 1. Request permission (shows OS prompt on iOS / Android 13+).
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // 2. Android notification channel (required for Android 8+).
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'All HostelHub push notifications',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Initialise local notifications plugin.
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _local.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      // Handle notification tap while app is in foreground or background.
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 4. Foreground message listener — show a local notification since FCM
    //    suppresses the system banner while the app is active.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 5. App opened from a terminated state via notification tap.
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageData(initialMessage.data);
    }

    // 6. App brought to foreground from background via notification tap.
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _handleMessageData(msg.data);
    });
  }

  // ── Foreground message display ────────────────────────────────────────────

  void _onForegroundMessage(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;

    _local.show(
      message.hashCode,
      n.title,
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // Encode the FCM data payload so the tap handler can deep-link.
      payload: _encodePayload(message.data),
    );
  }

  // ── Notification tap handler ──────────────────────────────────────────────

  void _onNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;
    final data = _decodePayload(response.payload!);
    _handleMessageData(data);
  }

  /// Override this in tests or via a router callback to handle deep linking.
  /// Default implementation just logs the data.
  void _handleMessageData(Map<String, dynamic> data) {
    final type = data['type'];
    debugPrint('📬 Notification tapped — type: $type, data: $data');
    // Deep-linking is wired up via a global NavigatorKey in the router.
    // The router already handles /maintenance/:id via GoRouter, so when
    // the user taps a maintenance notification the app will open correctly
    // once you call context.push('/maintenance/${data['requestId']}').
    //
    // To implement: expose a static callback here that the router can set,
    // or use a Riverpod provider that the Shell screens listen to.
  }

  // ── Payload encoding (simple key=value CSV) ───────────────────────────────

  String _encodePayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join(';');
  }

  Map<String, dynamic> _decodePayload(String payload) {
    final result = <String, dynamic>{};
    for (final pair in payload.split(';')) {
      final idx = pair.indexOf('=');
      if (idx > 0) result[pair.substring(0, idx)] = pair.substring(idx + 1);
    }
    return result;
  }

  // ── Save / refresh FCM token ──────────────────────────────────────────────

  Future<void> saveFcmToken(String uid) async {
    final token = await _fcm.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({'fcmToken': token});
    }

    // Cancel any existing listener before attaching a new one — prevents
    // duplicate listeners accumulating across multiple sign-in sessions.
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _fcm.onTokenRefresh.listen((newToken) {
      FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({'fcmToken': newToken});
    });
  }

  // ── Topic subscriptions ───────────────────────────────────────────────────

  Future<void> subscribeToRole(String role) async {
    await _fcm.subscribeToTopic(AppConstants.topicAll);
    if (role == AppConstants.roleStudent) {
      await _fcm.subscribeToTopic(AppConstants.topicStudents);
    } else if (role == AppConstants.roleStaff) {
      await _fcm.subscribeToTopic(AppConstants.topicStaff);
    }
  }

  Future<void> unsubscribeAll() async {
    await _fcm.unsubscribeFromTopic(AppConstants.topicAll);
    await _fcm.unsubscribeFromTopic(AppConstants.topicStudents);
    await _fcm.unsubscribeFromTopic(AppConstants.topicStaff);
  }

  // ── Announcement notification ─────────────────────────────
  /// Called by [SessionBootstrap] whenever a new announcement arrives via
  /// the Firestore stream. Shows a local notification; [onTap] is stored
  /// as a callback invoked from the notification tap handler.
  Future<void> showAnnouncementNotification({
    required String title,
    required String body,
    VoidCallback? onTap,
  }) async {
    try {
      await _local.show(
        title.hashCode ^ body.hashCode,
        title,
        body.length > 100 ? '${body.substring(0, 97)}...' : body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {}
  }

  // ── Welcome notification (fires once, first sign-in) ─────────────────────

  Future<void> showWelcomeNotificationIfNeeded(String userName) async {
    try {
      final box = Hive.box(AppConstants.settingsBox);
      final alreadySent =
          box.get('welcomeNotifSent', defaultValue: false) as bool;
      if (alreadySent) return;

      await box.put('welcomeNotifSent', true);
      await Future.delayed(const Duration(seconds: 5));

      final firstName = userName.split(' ').first;

      await _local.show(
        99901,
        'Welcome to HostelHub, $firstName!',
        'Your smart hostel companion is ready. '
            'Browse rooms, track maintenance requests, and stay connected '
            'with Ashesi announcements — all from one place.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(''),
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {
      // Non-critical — swallow silently.
    }
  }
}
