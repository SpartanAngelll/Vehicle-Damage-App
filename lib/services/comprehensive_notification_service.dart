import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/notification_models.dart';
import '../models/booking_models.dart';
import '../models/user_state.dart';

// Web-specific imports - only import on web platform
import 'web_notification_interop_stub.dart'
    if (dart.library.html) 'web_notification_interop.dart';

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
  
  // Track initialization status
  bool _isInitialized = false;

  /// Initialize the comprehensive notification service
  Future<void> initialize() async {
    try {
      print('🔔 [NotificationService] Initializing comprehensive notification service...');
      
      // Initialize local notifications first (can work even without permission)
      await _initializeLocalNotifications();
      
      // Create notification channels
      await _createNotificationChannels();
      
      // Request permission for notifications (non-blocking)
      await _requestNotificationPermission();
      
      // Initialize FCM (only if permission granted, but don't fail if not)
      try {
        await _initializeFCM();
      } catch (e) {
        print('⚠️ [NotificationService] FCM initialization failed (may need permission): $e');
      }
      
      // Load notification templates
      await _loadNotificationTemplates();
      
      // Start scheduled notification processor
      _startScheduledNotificationProcessor();
      
      // Listen to UserState changes to retry saving FCM token when user becomes available
      _setupUserStateListener();
      
      // Try to save any pending token immediately
      await _retryPendingTokenSave();
      
      _isInitialized = true;
      print('✅ [NotificationService] Comprehensive notification service initialized successfully');
    } catch (e) {
      print('❌ [NotificationService] Failed to initialize: $e');
      // Don't rethrow - allow app to continue even if notifications fail
      print('⚠️ [NotificationService] App will continue without full notification support');
      _isInitialized = false;
    }
  }
  
  /// Setup listener for UserState changes to retry saving FCM token
  void _setupUserStateListener() {
    try {
      final userState = UserState();
      userState.addListener(() {
        // When UserState changes (e.g., user logs in), try to save pending token
        if (userState.userId != null && _pendingFCMToken != null) {
          _retryPendingTokenSave();
        }
      });
    } catch (e) {
      print('⚠️ [NotificationService] Failed to setup UserState listener: $e');
    }
  }
  
  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;
  
  /// Ensure FCM token is saved for the current user (call this after user logs in)
  Future<void> ensureFCMTokenSaved() async {
    try {
      // Get current FCM token
      String? token;
      try {
        if (kIsWeb) {
          // For web, get token (service worker will be auto-registered)
          token = await _messaging.getToken(
            vapidKey: null, // VAPID key is optional for web
          );
        } else {
          // For mobile, get token normally
          token = await _messaging.getToken();
        }
      } catch (e) {
        print('⚠️ [NotificationService] Could not get FCM token: $e');
        // Try fallback for web
        if (kIsWeb) {
          try {
            token = await _messaging.getToken();
          } catch (e2) {
            print('❌ [NotificationService] Fallback FCM token get also failed: $e2');
            return;
          }
        } else {
          return;
        }
      }
      
      if (token != null) {
        print('✅ [NotificationService] FCM token retrieved, saving...');
        await _saveFCMToken(token);
      } else {
        print('⚠️ [NotificationService] FCM token is null');
      }
    } catch (e) {
      print('❌ [NotificationService] Failed to ensure FCM token saved: $e');
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      if (kIsWeb) {
        // Web: Request permission using browser Notification API
        try {
          final permission = await requestNotificationPermission();
          if (permission == 'granted') {
            print('✅ [NotificationService] Web notification permission granted');
          } else {
            print('⚠️ [NotificationService] Web notification permission: $permission');
          }
        } catch (e) {
          print('⚠️ [NotificationService] Web permission request error: $e');
        }
      } else {
        // Mobile: Request FCM permission
        final settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          print('✅ [NotificationService] FCM notification permission granted');
        } else {
          print('⚠️ [NotificationService] FCM notification permission not granted: ${settings.authorizationStatus}');
        }
        
        // Also request local notification permission (Android 13+)
        try {
          final androidPermission = await _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
          if (androidPermission == true) {
            print('✅ [NotificationService] Android local notification permission granted');
          } else {
            print('⚠️ [NotificationService] Android local notification permission: $androidPermission');
          }
        } catch (e) {
          print('⚠️ [NotificationService] Android permission request error: $e');
        }
      }
    } catch (e) {
      print('❌ [NotificationService] Error requesting notification permission: $e');
      // Don't throw - continue initialization
    }
  }

  Future<void> _initializeLocalNotifications() async {
    if (kIsWeb) {
      // Web platform - use browser Notification API
      print('🌐 [NotificationService] Initializing web notifications...');
      // Check if browser supports notifications
      if (isNotificationSupported) {
        print('✅ [NotificationService] Browser supports notifications');
      } else {
        print('⚠️ [NotificationService] Browser does not support notifications');
      }
      return;
    }

    // Mobile platforms - use flutter_local_notifications
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
    if (kIsWeb) {
      // Web doesn't use notification channels
      print('🌐 [NotificationService] Skipping notification channels on web');
      return;
    }

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
    if (kIsWeb) {
      // Web platform - FCM for web doesn't need background message handler
      // Get FCM token (vapidKey is optional for web)
      try {
        // Request permission first for web
        final settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        
        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          print('✅ [NotificationService] Web notification permission granted');
          
          // Get FCM token after permission is granted
          // For web, we need to specify the service worker registration
          String? token;
          try {
            // Try to get service worker registration first
            token = await _messaging.getToken(
              vapidKey: null, // VAPID key is optional for web
            );
          } catch (e) {
            print('⚠️ [NotificationService] Error getting FCM token: $e');
            // Try again without service worker (fallback)
            try {
              token = await _messaging.getToken();
            } catch (e2) {
              print('❌ [NotificationService] Failed to get FCM token: $e2');
            }
          }
          
          if (token != null) {
            print('✅ [NotificationService] FCM token obtained for web: ${token.substring(0, 20)}...');
            await _saveFCMToken(token);
          } else {
            print('⚠️ [NotificationService] FCM token is null for web');
          }

          // Listen for token refresh
          _messaging.onTokenRefresh.listen((newToken) {
            print('🔄 [NotificationService] FCM token refreshed for web');
            _saveFCMToken(newToken);
          });

          // Handle foreground messages
          FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

          // Handle notification taps when app is in background
          FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
        } else {
          print('⚠️ [NotificationService] Web notification permission not granted: ${settings.authorizationStatus}');
        }
      } catch (e) {
        print('❌ [NotificationService] Web FCM initialization error: $e');
        print('❌ [NotificationService] Stack trace: ${StackTrace.current}');
      }
    } else {
      // Mobile platforms
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
  }

  String? _pendingFCMToken;
  
  Future<void> _saveFCMToken(String token) async {
    try {
      // Store token in case we need to retry
      _pendingFCMToken = token;
      
      // Try to get userId from Firebase Auth first (more reliable)
      String? userId;
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          userId = currentUser.uid;
        }
      } catch (e) {
        print('⚠️ [NotificationService] Could not get userId from Firebase Auth: $e');
      }
      
      // Fallback to UserState if Firebase Auth doesn't have it
      if (userId == null) {
        final userState = UserState();
        userId = userState.userId;
      }
      
      if (userId != null) {
        // Get existing tokens to support multiple devices
        final userDoc = await _usersCollection.doc(userId).get();
        final userDataRaw = userDoc.data();
        final userData = userDataRaw is Map<String, dynamic> ? userDataRaw : null;
        
        List<String> tokens = [];
        if (userData != null && userData['fcmToken'] != null) {
          if (userData['fcmToken'] is List) {
            tokens = List<String>.from(userData['fcmToken'] as List);
          } else {
            tokens = [userData['fcmToken'] as String];
          }
        }
        
        // Add new token if not already present
        if (!tokens.contains(token)) {
          tokens.add(token);
        }
        
        // Save as array if multiple tokens, single value if one token
        final updateData = tokens.length == 1 
            ? {'fcmToken': tokens[0], 'lastTokenUpdate': FieldValue.serverTimestamp()}
            : {'fcmToken': tokens, 'lastTokenUpdate': FieldValue.serverTimestamp()};
        
        await _usersCollection.doc(userId).update(updateData);
        print('✅ [NotificationService] FCM token saved for user: $userId (${tokens.length} device(s))');
        _pendingFCMToken = null; // Clear pending token on success
      } else {
        print('⚠️ [NotificationService] Cannot save FCM token: userId is null. Token will be saved when user logs in.');
        // Token will be saved when user becomes available (see _retryPendingTokenSave)
      }
    } catch (e) {
      print('❌ [NotificationService] Failed to save FCM token: $e');
    }
  }
  
  /// Retry saving pending FCM token when user becomes available
  Future<void> _retryPendingTokenSave() async {
    if (_pendingFCMToken == null) return;
    
    try {
      String? userId;
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          userId = currentUser.uid;
        }
      } catch (e) {
        // Ignore
      }
      
      if (userId == null) {
        final userState = UserState();
        userId = userState.userId;
      }
      
      if (userId != null) {
        // Get existing tokens to support multiple devices
        final userDoc = await _usersCollection.doc(userId).get();
        final userDataRaw = userDoc.data();
        final userData = userDataRaw is Map<String, dynamic> ? userDataRaw : null;
        
        List<String> tokens = [];
        if (userData != null && userData['fcmToken'] != null) {
          if (userData['fcmToken'] is List) {
            tokens = List<String>.from(userData['fcmToken'] as List);
          } else {
            tokens = [userData['fcmToken'] as String];
          }
        }
        
        // Add pending token if not already present
        if (!tokens.contains(_pendingFCMToken)) {
          tokens.add(_pendingFCMToken!);
        }
        
        // Save as array if multiple tokens, single value if one token
        final updateData = tokens.length == 1 
            ? {'fcmToken': tokens[0], 'lastTokenUpdate': FieldValue.serverTimestamp()}
            : {'fcmToken': tokens, 'lastTokenUpdate': FieldValue.serverTimestamp()};
        
        await _usersCollection.doc(userId).update(updateData);
        print('✅ [NotificationService] Pending FCM token saved for user: $userId (${tokens.length} device(s))');
        _pendingFCMToken = null;
      }
    } catch (e) {
      print('❌ [NotificationService] Failed to retry saving FCM token: $e');
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
      (_) {
        print('⏰ [NotificationService] Processing scheduled notifications...');
        _processScheduledNotifications();
      },
    );
    // Also process immediately on startup
    _processScheduledNotifications();
  }

  Future<void> _processScheduledNotifications() async {
    try {
      final now = DateTime.now();
      print('⏰ [NotificationService] Checking for scheduled notifications before ${now.toIso8601String()}');
      
      final query = _notificationsCollection
          .where('status', isEqualTo: NotificationStatus.pending.name)
          .where('scheduledFor', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('scheduledFor', descending: false)
          .limit(50);

      final snapshot = await query.get();
      print('⏰ [NotificationService] Found ${snapshot.docs.length} scheduled notifications to process');
      
      for (final doc in snapshot.docs) {
        try {
          final notification = AppNotification.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
          print('⏰ [NotificationService] Processing scheduled notification: ${notification.title}');
          await _sendNotification(notification);
        } catch (e) {
          print('❌ [NotificationService] Failed to process scheduled notification ${doc.id}: $e');
        }
      }
    } catch (e) {
      // Check if it's a missing index error (will be auto-created)
      final errorString = e.toString();
      if (errorString.contains('FAILED_PRECONDITION') && errorString.contains('index')) {
        // Index is being created - this is expected on first run
        print('ℹ️ [NotificationService] Index is being created. Scheduled notifications will work once index is ready.');
      } else if (errorString.contains('permission-denied')) {
        print('⚠️ [NotificationService] Permission denied when processing scheduled notifications. Showing notifications immediately instead.');
        // Don't block - notifications will be shown when sent
      } else {
        print('❌ [NotificationService] Error processing scheduled notifications: $e');
      }
    }
  }

  /// Ensure service is initialized (lightweight check)
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      print('⚠️ [NotificationService] Service not initialized, attempting to initialize local notifications...');
      try {
        // Just initialize local notifications if not already done
        await _initializeLocalNotifications();
        await _createNotificationChannels();
        _isInitialized = true;
        print('✅ [NotificationService] Local notifications initialized on demand');
      } catch (e) {
        print('❌ [NotificationService] Failed to initialize on demand: $e');
        // Still allow notifications to be attempted
      }
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
      // Ensure service is initialized
      await _ensureInitialized();
      
      // CRITICAL: Don't send notifications to the current user (prevent self-notifications)
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && currentUser.uid == userId) {
          print('⚠️ [NotificationService] Skipping notification - cannot send to self (currentUser: ${currentUser.uid}, targetUserId: $userId)');
          return;
        }
      } catch (e) {
        // If we can't get current user from Firebase Auth, try using UserState as fallback
        try {
          final userState = UserState();
          if (userState.userId != null && userState.userId == userId) {
            print('⚠️ [NotificationService] Skipping notification - cannot send to self (userState.userId: ${userState.userId}, targetUserId: $userId)');
            return;
          }
        } catch (e2) {
          print('⚠️ [NotificationService] Could not verify current user, proceeding with caution: $e2');
        }
      }
      
      // Check user preferences (fail gracefully if can't read)
      NotificationPreferences? preferences;
      bool preferencesReadSuccessfully = false;
      try {
        preferences = await _getUserNotificationPreferences(userId);
        preferencesReadSuccessfully = true;
      } catch (e) {
        print('⚠️ [NotificationService] Could not read preferences, using defaults: $e');
        // Don't create default preferences - we'll skip preference checks
        preferences = null;
      }
      
      // Only check preferences if we successfully read them
      if (preferencesReadSuccessfully && preferences != null) {
        if (!preferences.shouldSendNotification(type)) {
          print('📵 [NotificationService] User $userId has disabled ${type.name} notifications');
          return;
        }
      }

      // Check quiet hours (only if we successfully read preferences)
      // Chat messages and urgent notifications bypass quiet hours
      final shouldBypassQuietHours = priority == NotificationPriority.urgent || 
                                     type == NotificationType.newChatMessage;
      
      if (preferencesReadSuccessfully && preferences != null) {
        try {
          if (!shouldBypassQuietHours && preferences.isInQuietHours()) {
            print('🌙 [NotificationService] User $userId is in quiet hours, scheduling for later');
            scheduledFor = _getNextAvailableTime(preferences);
          } else if (shouldBypassQuietHours && preferences.isInQuietHours()) {
            print('🔔 [NotificationService] Bypassing quiet hours for ${type.name} notification (priority: ${priority.name})');
          }
        } catch (e) {
          print('⚠️ [NotificationService] Error checking quiet hours, showing immediately: $e');
          scheduledFor = null; // Show immediately if we can't check quiet hours
        }
      } else {
        // If we couldn't read preferences, don't apply quiet hours - show immediately
        print('ℹ️ [NotificationService] Preferences not available, showing notification immediately (bypassing quiet hours)');
        scheduledFor = null;
      }

      // Override priority if user has custom settings (only if preferences were read successfully)
      final finalPriority = preferencesReadSuccessfully && preferences != null
          ? preferences.getNotificationPriority(type)
          : priority;

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

      print('📤 [NotificationService] Preparing to send notification: ${notification.title}');

      // Save notification to Firestore (non-blocking - don't fail if this errors)
      try {
        await _notificationsCollection.doc(notification.id).set(notification.toMap());
      } catch (e) {
        print('⚠️ [NotificationService] Failed to save notification to Firestore: $e');
        print('⚠️ [NotificationService] Continuing to show notification anyway...');
      }

      // Send immediately if not scheduled
      if (scheduledFor == null) {
        await _sendNotification(notification);
      } else {
        print('⏰ [NotificationService] Notification scheduled for ${scheduledFor.toIso8601String()}');
      }

      // Log to PostgreSQL (non-blocking)
      try {
        await _logNotificationToPostgreSQL(notification);
      } catch (e) {
        print('⚠️ [NotificationService] Failed to log to PostgreSQL: $e');
      }
    } catch (e) {
      print('❌ [NotificationService] Failed to send notification: $e');
      print('❌ [NotificationService] Stack trace: ${StackTrace.current}');
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
    String? senderId, // Optional: to prevent sending to self
  }) async {
    try {
      // Double-check: don't send notification if recipient is the same as sender
      if (senderId != null && recipientId == senderId) {
        print('⚠️ [NotificationService] Skipping notification - recipient is the same as sender: $recipientId');
        return;
      }
      
      // Validate recipient ID
      if (recipientId.isEmpty) {
        print('⚠️ [NotificationService] Skipping notification - recipient ID is empty');
        return;
      }
      
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
    // Always try to show local notification first (most important for user experience)
    try {
      await _showLocalNotification(notification);
      print('✅ [NotificationService] Local notification shown: ${notification.title}');
    } catch (e) {
      print('❌ [NotificationService] Failed to show local notification: $e');
    }

    // Then try Firestore operations (these can fail without blocking the notification)
    try {
      // Update notification status to sent
      await _notificationsCollection.doc(notification.id).update({
        'status': NotificationStatus.sent.name,
        'sentAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('⚠️ [NotificationService] Failed to update notification status in Firestore: $e');
      // Continue anyway - notification was already shown
    }

    // Try FCM notification (optional)
    try {
      final userDoc = await _usersCollection.doc(notification.userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      final fcmToken = userData?['fcmToken'] as String?;

      if (fcmToken != null) {
        // Send via FCM
        await _sendFCMNotification(notification, fcmToken);
      }
    } catch (e) {
      print('⚠️ [NotificationService] Failed to send FCM notification: $e');
      // Continue anyway - local notification was already shown
    }

    // Try email fallback (optional)
    try {
      await _sendEmailFallback(notification);
    } catch (e) {
      print('⚠️ [NotificationService] Failed to send email fallback: $e');
      // Continue anyway
    }

    print('✅ [NotificationService] Notification sent: ${notification.id}');
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
    if (!_isInitialized) {
      print('⚠️ [NotificationService] Service not initialized, cannot show local notification');
      return;
    }
    
    try {
      if (kIsWeb) {
        // Web platform - use browser Notification API
        await _showWebNotification(notification);
      } else {
        // Mobile platforms - use flutter_local_notifications
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
      
      print('✅ [NotificationService] Local notification shown: ${notification.title}');
    } catch (e) {
      print('❌ [NotificationService] Failed to show local notification: $e');
    }
  }

  /// Show notification on web using browser Notification API
  Future<void> _showWebNotification(AppNotification notification) async {
    if (!kIsWeb) return;
    
    try {
      print('🌐 [NotificationService] Attempting to show web notification: ${notification.title}');
      
      // Check if browser supports notifications
      // If check fails, we'll still try to show notification (FCM might handle it)
      bool supported = false;
      try {
        supported = isNotificationSupported;
        if (supported) {
          print('✅ [NotificationService] Browser supports notifications');
        } else {
          print('⚠️ [NotificationService] Browser notification check failed, but will try anyway (FCM may handle it)');
        }
      } catch (e) {
        print('⚠️ [NotificationService] Error checking notification support: $e, but will try anyway');
        // Continue anyway - FCM service worker might handle it
      }

      // Check current permission status first
      String? permissionString;
      try {
        permissionString = getNotificationPermissionStatus();
        print('🔐 [NotificationService] Current permission status: $permissionString');
      } catch (e) {
        print('⚠️ [NotificationService] Error checking permission status: $e');
        // Continue to request permission
      }
      
      if (permissionString == null || permissionString != 'granted') {
        // Request permission if not already granted
        print('🔐 [NotificationService] Requesting notification permission...');
        try {
          final permission = await requestNotificationPermission();
          print('🔐 [NotificationService] Permission request result: $permission');
          if (permission != 'granted') {
            print('⚠️ [NotificationService] Notification permission not granted: $permission');
            print('ℹ️ [NotificationService] FCM notifications from server will still work via service worker');
            // Don't return - FCM notifications from server will still work
            // But we can't show local notifications without permission
            return;
          }
        } catch (e) {
          print('⚠️ [NotificationService] Error requesting permission: $e');
          print('ℹ️ [NotificationService] FCM notifications from server will still work via service worker');
          return;
        }
      }
      print('✅ [NotificationService] Notification permission granted');

      // Create notification options
      final options = NotificationOptions(
        body: notification.body,
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-192.png',
        tag: notification.id,
        requireInteraction: notification.priority == NotificationPriority.urgent,
        silent: false,
        data: (notification.data ?? {}).jsify(),
      );

      // Create notification using JS interop
      print('🔔 [NotificationService] Creating browser notification...');
      final browserNotification = createNotification(notification.title, options);
      print('✅ [NotificationService] Browser notification created');

      // Handle notification click
      if (kIsWeb) {
        try {
          browserNotification.setOnClick(() {
            print('🔔 [NotificationService] Web notification clicked: ${notification.title}');
            browserNotification.close();
            _onWebNotificationClick(notification);
          });
          print('✅ [NotificationService] Click handler set');
        } catch (e) {
          print('⚠️ [NotificationService] Failed to set click handler: $e');
        }
      }

      // Auto-close after 5 seconds for normal priority, 10 seconds for urgent
      final duration = notification.priority == NotificationPriority.urgent 
          ? const Duration(seconds: 10)
          : const Duration(seconds: 5);
      
      Future.delayed(duration, () {
        try {
          browserNotification.close();
          print('🔔 [NotificationService] Web notification auto-closed');
        } catch (e) {
          print('⚠️ [NotificationService] Failed to close notification: $e');
        }
      });

      print('✅ [NotificationService] Web notification shown successfully: ${notification.title}');
    } catch (e, stackTrace) {
      print('❌ [NotificationService] Failed to show web notification: $e');
      print('❌ [NotificationService] Stack trace: $stackTrace');
    }
  }

  /// Handle web notification click
  void _onWebNotificationClick(AppNotification notification) {
    // Handle navigation based on notification type
    if (notification.data != null) {
      final type = notification.data!['type'] as String?;
      if (type == 'chat_message' && notification.data!.containsKey('chatRoomId')) {
        // Navigate to chat screen
        print('🔔 [NotificationService] Navigate to chat: ${notification.data!['chatRoomId']}');
        // You can use a navigation service or router here
      } else if (type == 'booking_reminder' && notification.data!.containsKey('bookingId')) {
        // Navigate to booking details
        print('🔔 [NotificationService] Navigate to booking: ${notification.data!['bookingId']}');
      }
    }
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
    
    if (!_isInitialized) {
      print('⚠️ [NotificationService] Service not initialized, cannot show notification');
      return;
    }
    
    if (message.notification != null) {
      if (kIsWeb) {
        // Web platform - use browser Notification API
        _showWebNotificationFromMessage(message);
      } else {
        // Mobile platforms - use flutter_local_notifications
        // Determine channel based on message data or use chat channel as default
        String channelId = _chatChannel;
        if (message.data.containsKey('type')) {
          final type = message.data['type'] as String?;
          if (type == 'booking_reminder' || type == 'booking_status') {
            channelId = _bookingChannel;
          } else if (type == 'chat_message') {
            channelId = _chatChannel;
          } else if (type == 'new_estimate') {
            channelId = _estimateChannel;
          } else if (type == 'new_service_request') {
            channelId = _requestChannel;
          }
        }
        
        // Show local notification
        _localNotifications.show(
          message.hashCode,
          message.notification!.title ?? 'New Notification',
          message.notification!.body ?? '',
          NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              _getChannelName(channelId),
              channelDescription: _getChannelDescription(channelId),
              importance: Importance.high,
              priority: Priority.high,
              enableVibration: true,
              playSound: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
      
      print('✅ [NotificationService] Local notification shown: ${message.notification!.title}');
    }
  }

  /// Show web notification from FCM message
  Future<void> _showWebNotificationFromMessage(RemoteMessage message) async {
    if (!kIsWeb) return;
    
    try {
      if (!isNotificationSupported) {
        print('⚠️ [NotificationService] Browser does not support notifications');
        return;
      }

      // Check current permission status first
      String? permissionString;
      try {
        permissionString = getNotificationPermissionStatus();
      } catch (e) {
        print('⚠️ [NotificationService] Error checking permission status: $e');
      }
      
      if (permissionString == null || permissionString != 'granted') {
        // Request permission if not already granted
        try {
          final permission = await requestNotificationPermission();
          if (permission != 'granted') {
            print('⚠️ [NotificationService] Notification permission not granted: $permission');
            return;
          }
        } catch (e) {
          print('⚠️ [NotificationService] Error requesting permission: $e');
          return;
        }
      }

      final title = message.notification?.title ?? 'New Notification';
      final body = message.notification?.body ?? '';

      // Create notification options
      final options = NotificationOptions(
        body: body,
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-192.png',
        tag: message.hashCode.toString(),
        requireInteraction: false,
        silent: false,
        data: message.data.jsify(),
      );

      // Create notification using JS interop
      final browserNotification = createNotification(title, options);

      // Handle notification click
      if (kIsWeb) {
        browserNotification.setOnClick(() {
          print('🔔 [NotificationService] Web notification clicked from FCM');
          browserNotification.close();
          // Handle navigation based on message.data if needed
        });
      }

      // Auto-close after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        browserNotification.close();
      });

      print('✅ [NotificationService] Web notification shown from FCM');
    } catch (e) {
      print('❌ [NotificationService] Failed to show web notification from FCM: $e');
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

  /// Send a test notification (for debugging)
  Future<void> sendTestNotification() async {
    try {
      await _ensureInitialized();
      final userState = UserState();
      if (userState.userId == null) {
        print('❌ [NotificationService] Cannot send test notification: user not authenticated');
        return;
      }
      
      await sendNotificationToUser(
        userId: userState.userId!,
        type: NotificationType.newChatMessage,
        title: 'Test Notification',
        body: 'This is a test notification to verify the notification system is working correctly.',
        priority: NotificationPriority.normal,
      );
      
      print('✅ [NotificationService] Test notification sent');
    } catch (e) {
      print('❌ [NotificationService] Failed to send test notification: $e');
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
