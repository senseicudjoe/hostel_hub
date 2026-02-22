import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

// ── Background handler (top-level required by FCM) ────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised by the time this runs
  print('📩 Background message: ${message.notification?.title}');
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
  FlutterLocalNotificationsPlugin();

  static const _channelId   = 'hostelhub_channel';
  static const _channelName = 'HostelHub Notifications';

  // ── Initialise ────────────────────────────────────────────
  Future<void> initialize() async {
    // 1. Request permission
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // 2. Android notification channel
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

    // 3. Local notifications init
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _local.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );

    // 4. Foreground message listener
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // 5. Background handler already registered in main.dart
  }

  void _showLocalNotification(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;

    _local.show(
      n.hashCode,
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
    );
  }

  // ── Save / refresh FCM token ──────────────────────────────
  Future<void> saveFcmToken(String uid) async {
    final token = await _fcm.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({'fcmToken': token});
    }

    _fcm.onTokenRefresh.listen((newToken) {
      FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({'fcmToken': newToken});
    });
  }

  // ── Topic subscriptions ───────────────────────────────────
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
}