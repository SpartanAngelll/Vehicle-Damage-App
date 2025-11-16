import 'package:flutter/material.dart';
import 'lib/services/comprehensive_notification_service.dart';
import 'lib/services/booking_reminder_scheduler.dart';
import 'lib/services/email_notification_service.dart';
import 'lib/models/notification_models.dart';
import 'lib/models/booking_models.dart';

/// Test file for the comprehensive notification system
/// This file demonstrates how to test all notification types and features

void main() {
  runApp(NotificationTestApp());
}

class NotificationTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification System Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: NotificationTestScreen(),
    );
  }
}

class NotificationTestScreen extends StatefulWidget {
  @override
  _NotificationTestScreenState createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final ComprehensiveNotificationService _notificationService = ComprehensiveNotificationService();
  final BookingReminderScheduler _reminderScheduler = BookingReminderScheduler();
  final EmailNotificationService _emailService = EmailNotificationService();
  
  bool _isInitialized = false;
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      setState(() {
        _status = 'Initializing notification services...';
      });

      // Initialize notification service
      await _notificationService.initialize();
      
      // Initialize reminder scheduler
      await _reminderScheduler.initialize();

      setState(() {
        _isInitialized = true;
        _status = 'Services initialized successfully!';
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to initialize: $e';
      });
    }
  }

  Future<void> _testBookingReminder() async {
    try {
      setState(() {
        _status = 'Testing booking reminder...';
      });

      // Create a test booking
      final testBooking = Booking(
        id: 'test_booking_${DateTime.now().millisecondsSinceEpoch}',
        estimateId: 'test_estimate',
        chatRoomId: 'test_chat',
        customerId: 'test_customer',
        professionalId: 'test_professional',
        customerName: 'Test Customer',
        professionalName: 'Test Professional',
        serviceTitle: 'Test Service',
        serviceDescription: 'Test service description',
        agreedPrice: 100.0,
        scheduledStartTime: DateTime.now().add(Duration(hours: 25)), // 25 hours from now
        scheduledEndTime: DateTime.now().add(Duration(hours: 27)),
        location: 'Test Location',
        deliverables: ['Test deliverable'],
        importantPoints: ['Test point'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Schedule reminders
      await _reminderScheduler.scheduleBookingReminders(testBooking);

      setState(() {
        _status = 'Booking reminder test completed!';
      });
    } catch (e) {
      setState(() {
        _status = 'Booking reminder test failed: $e';
      });
    }
  }

  Future<void> _testChatMessageNotification() async {
    try {
      setState(() {
        _status = 'Testing chat message notification...';
      });

      await _notificationService.sendNewChatMessageNotification(
        recipientId: 'test_recipient',
        senderName: 'Test Sender',
        messagePreview: 'This is a test message preview...',
        chatRoomId: 'test_chat_room',
      );

      setState(() {
        _status = 'Chat message notification test completed!';
      });
    } catch (e) {
      setState(() {
        _status = 'Chat message notification test failed: $e';
      });
    }
  }

  Future<void> _testEstimateNotification() async {
    try {
      setState(() {
        _status = 'Testing estimate notification...';
      });

      await _notificationService.sendNewEstimateNotification(
        customerId: 'test_customer',
        professionalName: 'Test Professional',
        serviceTitle: 'Test Service',
        price: 150.0,
        estimateId: 'test_estimate_${DateTime.now().millisecondsSinceEpoch}',
      );

      setState(() {
        _status = 'Estimate notification test completed!';
      });
    } catch (e) {
      setState(() {
        _status = 'Estimate notification test failed: $e';
      });
    }
  }

  Future<void> _testServiceRequestNotification() async {
    try {
      setState(() {
        _status = 'Testing service request notification...';
      });

      await _notificationService.sendNewServiceRequestNotification(
        professionalIds: ['test_professional_1', 'test_professional_2'],
        serviceCategory: 'Test Category',
        location: 'Test Location',
        requestId: 'test_request_${DateTime.now().millisecondsSinceEpoch}',
      );

      setState(() {
        _status = 'Service request notification test completed!';
      });
    } catch (e) {
      setState(() {
        _status = 'Service request notification test failed: $e';
      });
    }
  }

  Future<void> _testEmailNotification() async {
    try {
      setState(() {
        _status = 'Testing email notification...';
      });

      final testNotification = AppNotification(
        userId: 'test_user',
        type: NotificationType.systemAlert,
        title: 'Test Email Notification',
        body: 'This is a test email notification body.',
        priority: NotificationPriority.normal,
      );

      final success = await _emailService.sendEmailNotification(
        toEmail: 'test@example.com',
        toName: 'Test User',
        notification: testNotification,
      );

      setState(() {
        _status = success 
            ? 'Email notification test completed successfully!'
            : 'Email notification test failed!';
      });
    } catch (e) {
      setState(() {
        _status = 'Email notification test failed: $e';
      });
    }
  }

  Future<void> _testAllNotifications() async {
    try {
      setState(() {
        _status = 'Running all notification tests...';
      });

      // Test all notification types
      await _testChatMessageNotification();
      await Future.delayed(Duration(seconds: 1));
      
      await _testEstimateNotification();
      await Future.delayed(Duration(seconds: 1));
      
      await _testServiceRequestNotification();
      await Future.delayed(Duration(seconds: 1));
      
      await _testBookingReminder();
      await Future.delayed(Duration(seconds: 1));
      
      await _testEmailNotification();

      setState(() {
        _status = 'All notification tests completed!';
      });
    } catch (e) {
      setState(() {
        _status = 'All notification tests failed: $e';
      });
    }
  }

  Future<void> _testNotificationPreferences() async {
    try {
      setState(() {
        _status = 'Testing notification preferences...';
      });

      final preferences = NotificationPreferences(
        userId: 'test_user',
        enablePushNotifications: true,
        enableEmailNotifications: true,
        enableSmsNotifications: false,
        typePreferences: {
          NotificationType.bookingReminder24h: true,
          NotificationType.bookingReminder1h: true,
          NotificationType.newChatMessage: true,
          NotificationType.newEstimate: false, // Disabled for testing
          NotificationType.newServiceRequest: true,
          NotificationType.bookingStatusUpdate: true,
          NotificationType.paymentUpdate: false,
          NotificationType.systemAlert: true,
        },
      );

      await _notificationService.updateUserNotificationPreferences(preferences);

      setState(() {
        _status = 'Notification preferences test completed!';
      });
    } catch (e) {
      setState(() {
        _status = 'Notification preferences test failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification System Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _status,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    SizedBox(height: 8),
                    if (_isInitialized)
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          SizedBox(width: 8),
                          Text('Services Ready', style: TextStyle(color: Colors.green)),
                        ],
                      )
                    else
                      Row(
                        children: [
                          CircularProgressIndicator(size: 16),
                          SizedBox(width: 8),
                          Text('Initializing...'),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            if (_isInitialized) ...[
              Text(
                'Test Individual Features',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _testChatMessageNotification,
                child: Text('Test Chat Message Notification'),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _testEstimateNotification,
                child: Text('Test Estimate Notification'),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _testServiceRequestNotification,
                child: Text('Test Service Request Notification'),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _testBookingReminder,
                child: Text('Test Booking Reminder'),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _testEmailNotification,
                child: Text('Test Email Notification'),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _testNotificationPreferences,
                child: Text('Test Notification Preferences'),
              ),
              SizedBox(height: 16),
              Text(
                'Test All Features',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _testAllNotifications,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text('Run All Tests'),
              ),
            ] else ...[
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Initializing notification services...'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
