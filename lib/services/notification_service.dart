import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/damage_report.dart';
import '../models/user_state.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Notification channels
  static const String _damageReportChannel = 'damage_reports';
  static const String _estimateRequestChannel = 'estimate_requests';
  static const String _estimateUpdateChannel = 'estimate_updates';

  Future<void> initialize() async {
    // Request permission for notifications
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Get FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        await _saveFCMToken(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_saveFCMToken);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(initializationSettings);

    // Create notification channels
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel damageReportChannel = AndroidNotificationChannel(
      _damageReportChannel,
      'Damage Reports',
      description: 'Notifications for new damage reports',
      importance: Importance.high,
    );

    const AndroidNotificationChannel estimateRequestChannel = AndroidNotificationChannel(
      _estimateRequestChannel,
      'Estimate Requests',
      description: 'Requests to submit estimates',
      importance: Importance.high,
    );

    const AndroidNotificationChannel estimateUpdateChannel = AndroidNotificationChannel(
      _estimateUpdateChannel,
      'Estimate Updates',
      description: 'Updates on estimate status',
      importance: Importance.defaultImportance,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(damageReportChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(estimateRequestChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(estimateUpdateChannel);
  }

  Future<void> _saveFCMToken(String token) async {
    // Save token to user's profile in Firestore
    final user = _firestore.collection('users').doc(UserState().userId);
    await user.update({
      'fcmToken': token,
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    });
  }

  // Send notification to specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String channelId,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken != null) {
        // Send via FCM (you'll need to implement a Cloud Function for this)
        await _sendFCMNotification(
          token: fcmToken,
          title: title,
          body: body,
          data: data,
        );
      }

      // Also send local notification
      await _showLocalNotification(
        title: title,
        body: body,
        channelId: channelId,
        payload: data?.toString(),
      );
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }

  // Send notification to multiple users
  Future<void> sendNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    required String channelId,
    Map<String, dynamic>? data,
  }) async {
    for (final userId in userIds) {
      await sendNotificationToUser(
        userId: userId,
        title: title,
        body: body,
        channelId: channelId,
        data: data,
      );
    }
  }

  Future<void> _sendFCMNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // This would typically be done via a Cloud Function
    // For now, we'll just log it
    print('FCM Notification to $token: $title - $body');
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String channelId,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'vehicle_damage_app',
      'Vehicle Damage App',
      channelDescription: 'Notifications from Vehicle Damage App',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message received: ${message.notification?.title}');
    
    // Show local notification
    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? 'New Notification',
        body: message.notification!.body ?? '',
        channelId: _damageReportChannel,
        payload: message.data.toString(),
      );
    }
  }

  // Subscribe to topics for damage reports
  Future<void> subscribeToDamageReports() async {
    await _messaging.subscribeToTopic('damage_reports');
  }

  // Subscribe to topics for estimate requests
  Future<void> subscribeToEstimateRequests() async {
    await _messaging.subscribeToTopic('estimate_requests');
  }

  // Unsubscribe from topics
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.notification?.title}');
}
