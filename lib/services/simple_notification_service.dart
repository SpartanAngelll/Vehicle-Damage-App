import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_state.dart';

class SimpleNotificationService {
  static final SimpleNotificationService _instance = SimpleNotificationService._internal();
  factory SimpleNotificationService() => _instance;
  SimpleNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Notification channels
  static const String damageReportChannel = 'damage_reports';
  static const String estimateRequestChannel = 'estimate_requests';
  static const String estimateUpdateChannel = 'estimate_updates';

  /// Initialize the notification service
  Future<void> initialize() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
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
        
        print('Notification service initialized successfully');
      } else {
        print('Notification permission denied: ${settings.authorizationStatus}');
      }
    } catch (e) {
      print('Failed to initialize notification service: $e');
      rethrow;
    }
  }

  /// Save FCM token to user's profile
  Future<void> _saveFCMToken(String token) async {
    try {
      // Save token to user's profile in Firestore
      final userState = UserState();
      if (userState.userId != null) {
        final user = _firestore.collection('users').doc(userState.userId);
        await user.update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        print('FCM token saved successfully for user: ${userState.userId}');
      } else {
        print('Cannot save FCM token: userState.userId is null');
      }
    } catch (e) {
      print('Failed to save FCM token: $e');
    }
  }

  /// Save FCM token for a specific user ID (useful for when userState might not be ready)
  Future<void> saveFCMTokenForUser(String userId, String token) async {
    try {
      final user = _firestore.collection('users').doc(userId);
      await user.update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      print('FCM token saved successfully for user: $userId');
    } catch (e) {
      print('Failed to save FCM token for user $userId: $e');
    }
  }

  /// Send notification to specific user
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
        // For now, just log the notification
        // In production, you'd send this via a Cloud Function
        print('FCM Notification to $userId: $title - $body');
        print('Token: $fcmToken');
        print('Data: $data');
      } else {
        print('No FCM token found for user: $userId');
      }
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }

  /// Send notification to multiple users
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

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message received: ${message.notification?.title}');
    print('Message data: ${message.data}');
    
    // In a real app, you might want to show a custom in-app notification
    // For now, we'll just log it
  }

  /// Subscribe to topics for damage reports
  Future<void> subscribeToDamageReports() async {
    try {
      await _messaging.subscribeToTopic('damage_reports');
      print('Subscribed to damage_reports topic');
    } catch (e) {
      print('Failed to subscribe to damage_reports topic: $e');
    }
  }

  /// Subscribe to topics for estimate requests
  Future<void> subscribeToEstimateRequests() async {
    try {
      await _messaging.subscribeToTopic('estimate_requests');
      print('Subscribed to estimate_requests topic');
    } catch (e) {
      print('Failed to subscribe to estimate_requests topic: $e');
    }
  }

  /// Unsubscribe from topics
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from $topic topic');
    } catch (e) {
      print('Failed to unsubscribe from $topic topic: $e');
    }
  }

  /// Get current FCM token
  Future<String?> getCurrentToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('Failed to get FCM token: $e');
      return null;
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('Failed to check notification settings: $e');
      return false;
    }
  }

  /// Ensure FCM token is refreshed and saved for current user
  Future<void> ensureFCMTokenSaved() async {
    try {
      final userState = UserState();
      if (userState.userId != null) {
        // Get current token
        final token = await _messaging.getToken();
        if (token != null) {
          await saveFCMTokenForUser(userState.userId!, token);
        } else {
          print('Failed to get FCM token for user: ${userState.userId}');
        }
      } else {
        print('Cannot ensure FCM token: userState.userId is null');
      }
    } catch (e) {
      print('Failed to ensure FCM token saved: $e');
    }
  }

  /// Refresh and save FCM token (useful for manual refresh)
  Future<void> refreshAndSaveFCMToken() async {
    try {
      final userState = UserState();
      if (userState.userId != null) {
        // Delete old token first
        final oldToken = await _messaging.getToken();
        if (oldToken != null) {
          await _messaging.deleteToken();
        }
        
        // Get new token
        final newToken = await _messaging.getToken();
        if (newToken != null) {
          await saveFCMTokenForUser(userState.userId!, newToken);
          print('FCM token refreshed and saved for user: ${userState.userId}');
        } else {
          print('Failed to get new FCM token for user: ${userState.userId}');
        }
      } else {
        print('Cannot refresh FCM token: userState.userId is null');
      }
    } catch (e) {
      print('Failed to refresh FCM token: $e');
    }
  }

  /// Check and fix missing FCM tokens for all users
  Future<void> checkAndFixMissingFCMTokens() async {
    try {
      print('Checking for users with missing FCM tokens...');
      
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      int fixedCount = 0;
      
      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final fcmToken = userData['fcmToken'];
        
        if (fcmToken == null || fcmToken.toString().isEmpty) {
          print('User ${userDoc.id} is missing FCM token');
          
          // For now, we can't generate tokens for other users
          // But we can log them for manual review
          print('User ${userDoc.id} (${userData['email'] ?? 'No email'}) needs FCM token');
        } else {
          print('User ${userDoc.id} has FCM token: ${fcmToken.toString().substring(0, 20)}...');
        }
      }
      
      print('FCM token check completed. Users with missing tokens need to sign in to generate tokens.');
    } catch (e) {
      print('Failed to check FCM tokens: $e');
    }
  }
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.notification?.title}');
  print('Message data: ${message.data}');
}
