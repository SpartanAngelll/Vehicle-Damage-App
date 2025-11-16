import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/notification_models.dart';
import '../models/booking_models.dart';
import '../models/user_state.dart';

class ComprehensiveNotificationService {
  static final ComprehensiveNotificationService _instance = ComprehensiveNotificationService._internal();
  factory ComprehensiveNotificationService() => _instance;
  ComprehensiveNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  CollectionReference get _notificationsCollection => _firestore.collection('notifications');
  CollectionReference get _templatesCollection => _firestore.collection('notification_templates');
  CollectionReference get _preferencesCollection => _firestore.collection('notification_preferences');
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Notification channels
  static const String _bookingChannel = 'booking_notifications';
  static const String _chatChannel = 'chat_notifications';
  static const String _estimateChannel = 'estimate_notifications';
  static const String _requestChannel = 'request_notifications';
  static const String _systemChannel = 'system_notifications';

  // Timer for scheduled notifications
  Timer? _scheduledNotificationTimer;

  /// Initialize the comprehensive notification service
  Future<void> initialize() async {
    try {
      print('🔔 [NotificationService] Initializing comprehensive notification service...');
      
      // Request permission for notifications
      await _requestNotificationPermission();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Create notification channels
      await _createNotificationChannels();
      
      // Initialize FCM
      await _initializeFCM();
      
      // Load notification templates
      await _loadNotificationTemplates();
      
      // Start scheduled notification processor
      _startScheduledNotificationProcessor();
      
      print('✅ [NotificationService] Comprehensive notification service initialized successfully');
    } catch (e) {
      print('❌ [NotificationService] Failed to initialize: $e');
      rethrow;
    }
  }

  Future<void> _requestNotificationPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      throw Exception('Notification permission denied: ${settings.authorizationStatus}');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _createNotificationChannels() async {
    final channels = [
      const AndroidNotificationChannel(
        _bookingChannel,
        'Booking Notifications',
        description: 'Notifications for booking reminders and updates',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
      const AndroidNotificationChannel(
        _chatChannel,
        'Chat Notifications',
        description: 'Notifications for new chat messages',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
      const AndroidNotificationChannel(
        _estimateChannel,
        'Estimate Notifications',
        description: 'Notifications for new estimates and pricing updates',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
      const AndroidNotificationChannel(
        _requestChannel,
        'Request Notifications',
        description: 'Notifications for new service requests',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
      const AndroidNotificationChannel(
        _systemChannel,
        'System Notifications',
        description: 'System alerts and important updates',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
      ),
    ];

    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _initializeFCM() async {
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

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  Future<void> _saveFCMToken(String token) async {
    try {
      final userState = UserState();
      if (userState.userId != null) {
        await _usersCollection.doc(userState.userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        print('✅ [NotificationService] FCM token saved for user: ${userState.userId}');
      }
    } catch (e) {
      print('❌ [NotificationService] Failed to save FCM token: $e');
    }
  }

  Future<void> _loadNotificationTemplates() async {
    // Create default notification templates if they don't exist
    await _createDefaultTemplates();
  }

  Future<void> _createDefaultTemplates() async {
    final templates = [
      NotificationTemplate(
        type: NotificationType.bookingReminder24h,
        titleTemplate: 'Booking Reminder - {{serviceTitle}}',
        bodyTemplate: 'Your {{serviceTitle}} appointment is scheduled for tomorrow at {{scheduledTime}}. Location: {{location}}',
        defaultActionButtons: {
          'view_booking': 'View Booking',
          'reschedule': 'Reschedule',
        },
        defaultPriority: NotificationPriority.high,
      ),
      NotificationTemplate(
        type: NotificationType.bookingReminder1h,
        titleTemplate: 'Booking Starting Soon - {{serviceTitle}}',
        bodyTemplate: 'Your {{serviceTitle}} appointment starts in 1 hour at {{location}}',
        defaultActionButtons: {
          'view_booking': 'View Booking',
          'contact_professional': 'Contact Professional',
        },
        defaultPriority: NotificationPriority.urgent,
      ),
      NotificationTemplate(
        type: NotificationType.newChatMessage,
        titleTemplate: 'New Message from {{senderName}}',
        bodyTemplate: '{{messagePreview}}',
        defaultActionButtons: {
          'reply': 'Reply',
          'view_chat': 'View Chat',
        },
        defaultPriority: NotificationPriority.high,
      ),
      NotificationTemplate(
        type: NotificationType.newEstimate,
        titleTemplate: 'New Estimate Received',
        bodyTemplate: '{{professionalName}} has submitted an estimate for {{serviceTitle}} - {{price}}',
        defaultActionButtons: {
          'view_estimate': 'View Estimate',
          'accept': 'Accept',
        },
        defaultPriority: NotificationPriority.high,
      ),
      NotificationTemplate(
        type: NotificationType.newServiceRequest,
        titleTemplate: 'New Service Request Available',
        bodyTemplate: 'A new {{serviceCategory}} request is available in your area',
        defaultActionButtons: {
          'view_request': 'View Request',
          'submit_estimate': 'Submit Estimate',
        },
        defaultPriority: NotificationPriority.high,
      ),
    ];

    for (final template in templates) {
      try {
        final docRef = _templatesCollection.doc(template.id);
        final doc = await docRef.get();
        if (!doc.exists) {
          await docRef.set(template.toMap());
          print('✅ [NotificationService] Created template: ${template.type.name}');
        }
      } catch (e) {
        print('❌ [NotificationService] Failed to create template ${template.type.name}: $e');
      }
    }
  }

  void _startScheduledNotificationProcessor() {
    // Check for scheduled notifications every minute
    _scheduledNotificationTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _processScheduledNotifications(),
    );
  }

  Future<void> _processScheduledNotifications() async {
    try {
      final now = DateTime.now();
      final query = _notificationsCollection
          .where('status', isEqualTo: NotificationStatus.pending.name)
          .where('scheduledFor', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .limit(50);

      final snapshot = await query.get();
      
      for (final doc in snapshot.docs) {
        final notification = AppNotification.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        await _sendNotification(notification);
      }
    } catch (e) {
      print('❌ [NotificationService] Error processing scheduled notifications: $e');
    }
  }

  /// Send a notification to a specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    Map<String, dynamic>? actionButtons,
    NotificationPriority priority = NotificationPriority.normal,
    DateTime? scheduledFor,
  }) async {
    try {
      // Check user preferences
      final preferences = await _getUserNotificationPreferences(userId);
      if (!preferences.shouldSendNotification(type)) {
        print('📵 [NotificationService] User $userId has disabled ${type.name} notifications');
        return;
      }

      // Check quiet hours
      if (preferences.isInQuietHours() && priority != NotificationPriority.urgent) {
        print('🌙 [NotificationService] User $userId is in quiet hours, scheduling for later');
        scheduledFor = _getNextAvailableTime(preferences);
      }

      // Override priority if user has custom settings
      final finalPriority = preferences.getNotificationPriority(type);

      final notification = AppNotification(
        userId: userId,
        type: type,
        title: title,
        body: body,
        priority: finalPriority,
        data: data,
        actionButtons: actionButtons,
        scheduledFor: scheduledFor,
      );

      // Save notification to Firestore
      await _notificationsCollection.doc(notification.id).set(notification.toMap());

      // Send immediately if not scheduled
      if (scheduledFor == null) {
        await _sendNotification(notification);
      } else {
        print('⏰ [NotificationService] Notification scheduled for ${scheduledFor.toIso8601String()}');
      }

      // Log to PostgreSQL
      await _logNotificationToPostgreSQL(notification);
    } catch (e) {
      print('❌ [NotificationService] Failed to send notification: $e');
    }
  }

  /// Send booking reminder notifications
  Future<void> sendBookingReminder({
    required Booking booking,
    required int hoursBefore,
  }) async {
    try {
      final notificationType = hoursBefore == 24 
          ? NotificationType.bookingReminder24h 
          : NotificationType.bookingReminder1h;

      final scheduledTime = booking.scheduledStartTime.subtract(Duration(hours: hoursBefore));
      
      // Send to customer
      await sendNotificationToUser(
        userId: booking.customerId,
        type: notificationType,
        title: hoursBefore == 24 
            ? 'Booking Reminder - ${booking.serviceTitle}'
            : 'Booking Starting Soon - ${booking.serviceTitle}',
        body: hoursBefore == 24
            ? 'Your ${booking.serviceTitle} appointment is scheduled for tomorrow at ${_formatTime(booking.scheduledStartTime)}. Location: ${booking.location}'
            : 'Your ${booking.serviceTitle} appointment starts in 1 hour at ${booking.location}',
        data: {
          'bookingId': booking.id,
          'type': 'booking_reminder',
          'hoursBefore': hoursBefore,
        },
        actionButtons: {
          'view_booking': 'View Booking',
          'reschedule': 'Reschedule',
        },
        priority: hoursBefore == 1 ? NotificationPriority.urgent : NotificationPriority.high,
        scheduledFor: scheduledTime,
      );

      // Send to professional
      await sendNotificationToUser(
        userId: booking.professionalId,
        type: notificationType,
        title: hoursBefore == 24 
            ? 'Upcoming Booking - ${booking.serviceTitle}'
            : 'Booking Starting Soon - ${booking.serviceTitle}',
        body: hoursBefore == 24
            ? 'You have a ${booking.serviceTitle} appointment tomorrow at ${_formatTime(booking.scheduledStartTime)} with ${booking.customerName}'
            : 'Your ${booking.serviceTitle} appointment with ${booking.customerName} starts in 1 hour',
        data: {
          'bookingId': booking.id,
          'type': 'booking_reminder',
          'hoursBefore': hoursBefore,
        },
        actionButtons: {
          'view_booking': 'View Booking',
          'contact_customer': 'Contact Customer',
        },
        priority: hoursBefore == 1 ? NotificationPriority.urgent : NotificationPriority.high,
        scheduledFor: scheduledTime,
      );

      print('✅ [NotificationService] Booking reminder scheduled for ${hoursBefore}h before booking ${booking.id}');
    } catch (e) {
      print('❌ [NotificationService] Failed to send booking reminder: $e');
    }
  }

  /// Send new chat message notification
  Future<void> sendNewChatMessageNotification({
    required String recipientId,
    required String senderName,
    required String messagePreview,
    required String chatRoomId,
  }) async {
    try {
      await sendNotificationToUser(
        userId: recipientId,
        type: NotificationType.newChatMessage,
        title: 'New Message from $senderName',
        body: messagePreview,
        data: {
          'chatRoomId': chatRoomId,
          'type': 'chat_message',
        },
        actionButtons: {
          'reply': 'Reply',
          'view_chat': 'View Chat',
        },
        priority: NotificationPriority.high,
      );

      print('✅ [NotificationService] Chat message notification sent to $recipientId');
    } catch (e) {
      print('❌ [NotificationService] Failed to send chat message notification: $e');
    }
  }

  /// Send new estimate notification
  Future<void> sendNewEstimateNotification({
    required String customerId,
    required String professionalName,
    required String serviceTitle,
    required double price,
    required String estimateId,
  }) async {
    try {
      await sendNotificationToUser(
        userId: customerId,
        type: NotificationType.newEstimate,
        title: 'New Estimate Received',
        body: '$professionalName has submitted an estimate for $serviceTitle - \$${price.toStringAsFixed(2)}',
        data: {
          'estimateId': estimateId,
          'type': 'new_estimate',
        },
        actionButtons: {
          'view_estimate': 'View Estimate',
          'accept': 'Accept',
        },
        priority: NotificationPriority.high,
      );

      print('✅ [NotificationService] New estimate notification sent to $customerId');
    } catch (e) {
      print('❌ [NotificationService] Failed to send estimate notification: $e');
    }
  }

  /// Send new service request notification
  Future<void> sendNewServiceRequestNotification({
    required List<String> professionalIds,
    required String serviceCategory,
    required String location,
    required String requestId,
  }) async {
    try {
      for (final professionalId in professionalIds) {
        await sendNotificationToUser(
          userId: professionalId,
          type: NotificationType.newServiceRequest,
          title: 'New Service Request Available',
          body: 'A new $serviceCategory request is available in $location',
          data: {
            'requestId': requestId,
            'type': 'new_service_request',
            'serviceCategory': serviceCategory,
            'location': location,
          },
          actionButtons: {
            'view_request': 'View Request',
            'submit_estimate': 'Submit Estimate',
          },
          priority: NotificationPriority.high,
        );
      }

      print('✅ [NotificationService] Service request notifications sent to ${professionalIds.length} professionals');
    } catch (e) {
      print('❌ [NotificationService] Failed to send service request notifications: $e');
    }
  }

  Future<void> _sendNotification(AppNotification notification) async {
    try {
      // Update notification status to sent
      await _notificationsCollection.doc(notification.id).update({
        'status': NotificationStatus.sent.name,
        'sentAt': FieldValue.serverTimestamp(),
      });

      // Get user's FCM token
      final userDoc = await _usersCollection.doc(notification.userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      final fcmToken = userData?['fcmToken'] as String?;

      if (fcmToken != null) {
        // Send via FCM
        await _sendFCMNotification(notification, fcmToken);
      }

      // Send local notification
      await _showLocalNotification(notification);

      // Send email fallback if enabled
      await _sendEmailFallback(notification);

      print('✅ [NotificationService] Notification sent: ${notification.id}');
    } catch (e) {
      // Update notification status to failed
      await _notificationsCollection.doc(notification.id).update({
        'status': NotificationStatus.failed.name,
        'errorMessage': e.toString(),
      });
      print('❌ [NotificationService] Failed to send notification ${notification.id}: $e');
    }
  }

  Future<void> _sendFCMNotification(AppNotification notification, String fcmToken) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendNotification');
      
      await callable.call({
        'userId': notification.userId,
        'title': notification.title,
        'body': notification.body,
        'data': notification.data,
        'priority': notification.priority.name,
      });
      
      print('📱 [NotificationService] FCM Notification sent: ${notification.title}');
    } catch (e) {
      print('❌ [NotificationService] FCM notification failed: $e');
      rethrow;
    }
  }

  Future<void> _showLocalNotification(AppNotification notification) async {
    final channelId = _getChannelIdForType(notification.type);
    
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance: _getImportanceForPriority(notification.priority),
      priority: _getPriorityForPriority(notification.priority),
      enableVibration: true,
      playSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: jsonEncode(notification.data),
    );
  }

  Future<void> _sendEmailFallback(AppNotification notification) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendNotificationWithFallback');
      
      await callable.call({
        'userId': notification.userId,
        'title': notification.title,
        'body': notification.body,
        'data': notification.data,
        'priority': notification.priority.name,
        'enableEmailFallback': true,
      });
      
      print('📧 [NotificationService] Email fallback sent for notification: ${notification.title}');
    } catch (e) {
      print('❌ [NotificationService] Email fallback failed: $e');
    }
  }

  Future<NotificationPreferences> _getUserNotificationPreferences(String userId) async {
    try {
      final doc = await _preferencesCollection.doc(userId).get();
      if (doc.exists) {
        return NotificationPreferences.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('❌ [NotificationService] Failed to get user preferences: $e');
    }
    
    // Return default preferences
    return NotificationPreferences(userId: userId);
  }

  DateTime _getNextAvailableTime(NotificationPreferences preferences) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    
    // Simple implementation - schedule for next day at 9 AM
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
  }

  String _getChannelIdForType(NotificationType type) {
    switch (type) {
      case NotificationType.bookingReminder24h:
      case NotificationType.bookingReminder1h:
      case NotificationType.bookingStatusUpdate:
        return _bookingChannel;
      case NotificationType.newChatMessage:
        return _chatChannel;
      case NotificationType.newEstimate:
      case NotificationType.paymentUpdate:
        return _estimateChannel;
      case NotificationType.newServiceRequest:
        return _requestChannel;
      case NotificationType.systemAlert:
        return _systemChannel;
    }
  }

  String _getChannelName(String channelId) {
    switch (channelId) {
      case _bookingChannel:
        return 'Booking Notifications';
      case _chatChannel:
        return 'Chat Notifications';
      case _estimateChannel:
        return 'Estimate Notifications';
      case _requestChannel:
        return 'Request Notifications';
      case _systemChannel:
        return 'System Notifications';
      default:
        return 'General Notifications';
    }
  }

  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case _bookingChannel:
        return 'Notifications for booking reminders and updates';
      case _chatChannel:
        return 'Notifications for new chat messages';
      case _estimateChannel:
        return 'Notifications for new estimates and pricing updates';
      case _requestChannel:
        return 'Notifications for new service requests';
      case _systemChannel:
        return 'System alerts and important updates';
      default:
        return 'General app notifications';
    }
  }

  Importance _getImportanceForPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.urgent:
        return Importance.max;
    }
  }

  Priority _getPriorityForPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.urgent:
        return Priority.max;
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  Future<void> _logNotificationToPostgreSQL(AppNotification notification) async {
    try {
      // This would log the notification to PostgreSQL for audit/history
      print('📊 [NotificationService] Logging notification to PostgreSQL: ${notification.id}');
    } catch (e) {
      print('❌ [NotificationService] Failed to log notification to PostgreSQL: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 [NotificationService] Notification tapped: ${response.payload}');
    // Handle notification tap - navigate to appropriate screen
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('📱 [NotificationService] Foreground message received: ${message.notification?.title}');
    
    if (message.notification != null) {
      // Show local notification
      _localNotifications.show(
        message.hashCode,
        message.notification!.title ?? 'New Notification',
        message.notification!.body ?? '',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'default',
            'Default Channel',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    print('🔔 [NotificationService] Notification tapped from background: ${message.data}');
    // Handle notification tap when app was in background
  }

  /// Schedule booking reminders for a booking
  Future<void> scheduleBookingReminders(Booking booking) async {
    try {
      // Schedule 24-hour reminder
      await sendBookingReminder(booking: booking, hoursBefore: 24);
      
      // Schedule 1-hour reminder
      await sendBookingReminder(booking: booking, hoursBefore: 1);
      
      print('✅ [NotificationService] Booking reminders scheduled for booking ${booking.id}');
    } catch (e) {
      print('❌ [NotificationService] Failed to schedule booking reminders: $e');
    }
  }

  /// Update user notification preferences
  Future<void> updateUserNotificationPreferences(NotificationPreferences preferences) async {
    try {
      await _preferencesCollection.doc(preferences.userId).set(preferences.toMap());
      print('✅ [NotificationService] Notification preferences updated for user ${preferences.userId}');
    } catch (e) {
      print('❌ [NotificationService] Failed to update notification preferences: $e');
    }
  }

  /// Get user's notification history
  Future<List<AppNotification>> getUserNotificationHistory(String userId, {int limit = 50}) async {
    try {
      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => AppNotification.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      print('❌ [NotificationService] Failed to get notification history: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'status': NotificationStatus.read.name,
        'readAt': FieldValue.serverTimestamp(),
      });
      print('✅ [NotificationService] Notification marked as read: $notificationId');
    } catch (e) {
      print('❌ [NotificationService] Failed to mark notification as read: $e');
    }
  }

  /// Clean up old notifications
  Future<void> cleanupOldNotifications({int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final query = _notificationsCollection
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .where('status', whereIn: [
            NotificationStatus.delivered.name,
            NotificationStatus.read.name,
            NotificationStatus.failed.name,
          ]);

      final snapshot = await query.get();
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ [NotificationService] Cleaned up ${snapshot.docs.length} old notifications');
    } catch (e) {
      print('❌ [NotificationService] Failed to cleanup old notifications: $e');
    }
  }

  void dispose() {
    _scheduledNotificationTimer?.cancel();
  }
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 [NotificationService] Background message received: ${message.notification?.title}');
  print('📱 [NotificationService] Message data: ${message.data}');
}
