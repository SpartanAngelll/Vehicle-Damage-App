# Comprehensive Notification System

This document describes the comprehensive notification system implemented for the Vehicle Damage App, including Firebase Cloud Messaging (FCM), email fallback, and real-time notification management.

## 🚀 Features

### Core Notification Types
- **Booking Reminders**: 24-hour and 1-hour advance notifications
- **Chat Messages**: Real-time notifications for new messages
- **New Estimates**: Notifications when professionals submit estimates
- **Service Requests**: Notifications for new requests in professional categories
- **Booking Status Updates**: Notifications for status changes
- **Payment Updates**: Notifications for payment status changes
- **System Alerts**: Important system-wide notifications

### Advanced Features
- **Multi-channel Delivery**: Push notifications, email, and SMS support
- **User Preferences**: Granular control over notification types and timing
- **Quiet Hours**: Configurable do-not-disturb periods
- **Priority System**: Urgent, high, normal, and low priority levels
- **Scheduled Notifications**: Time-based notification delivery
- **Template System**: Consistent notification formatting
- **Audit Trail**: Complete notification history and delivery tracking

## 📁 File Structure

```
lib/
├── models/
│   └── notification_models.dart          # Notification data models
├── services/
│   ├── comprehensive_notification_service.dart  # Main notification service
│   ├── booking_reminder_scheduler.dart   # Booking reminder scheduling
│   └── email_notification_service.dart   # Email notification service
├── screens/
│   └── notification_settings_screen.dart # User notification preferences
└── widgets/
    └── (notification-related widgets)

backend/
└── functions/
    ├── index.js                          # Cloud Functions for FCM
    └── package.json                      # Cloud Functions dependencies

database/
└── notification_schema.sql              # PostgreSQL notification schema
```

## 🛠️ Setup Instructions

### 1. Firebase Configuration

#### Enable Firebase Cloud Messaging
1. Go to Firebase Console → Project Settings → Cloud Messaging
2. Enable FCM for your project
3. Download and configure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

#### Configure Cloud Functions
```bash
cd backend/functions
npm install
firebase deploy --only functions
```

### 2. Database Setup

#### PostgreSQL Schema
```sql
-- Run the notification schema
\i database/notification_schema.sql
```

#### Firestore Rules
The Firestore rules have been updated to include notification collections:
- `notifications/{notificationId}` - User notifications
- `notification_templates/{templateId}` - Notification templates
- `notification_channels/{channelId}` - Notification channels
- `notification_preferences/{userId}` - User preferences

### 3. Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  firebase_messaging: ^15.1.3
  flutter_local_notifications: ^18.0.0
  http: ^1.1.2  # For email service
```

### 4. Platform Configuration

#### Android
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />

<service
    android:name="io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

#### iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

## 🔧 Usage

### Initialize the Notification System

```dart
import 'package:your_app/services/comprehensive_notification_service.dart';
import 'package:your_app/services/booking_reminder_scheduler.dart';

// Initialize services
final notificationService = ComprehensiveNotificationService();
final reminderScheduler = BookingReminderScheduler();

await notificationService.initialize();
await reminderScheduler.initialize();
```

### Send Notifications

#### Basic Notification
```dart
await notificationService.sendNotificationToUser(
  userId: 'user123',
  type: NotificationType.newChatMessage,
  title: 'New Message',
  body: 'You have received a new message',
  data: {'chatRoomId': 'room123'},
  actionButtons: {
    'reply': 'Reply',
    'view_chat': 'View Chat',
  },
);
```

#### Booking Reminder
```dart
// Automatically scheduled when booking is created
await reminderScheduler.scheduleBookingReminders(booking);
```

#### Chat Message Notification
```dart
await notificationService.sendNewChatMessageNotification(
  recipientId: 'user123',
  senderName: 'John Doe',
  messagePreview: 'Hello, how can I help you?',
  chatRoomId: 'room123',
);
```

#### Estimate Notification
```dart
await notificationService.sendNewEstimateNotification(
  customerId: 'customer123',
  professionalName: 'ABC Auto Repair',
  serviceTitle: 'Brake Pad Replacement',
  price: 150.0,
  estimateId: 'estimate123',
);
```

#### Service Request Notification
```dart
await notificationService.sendNewServiceRequestNotification(
  professionalIds: ['prof1', 'prof2', 'prof3'],
  serviceCategory: 'Auto Repair',
  location: 'Downtown',
  requestId: 'request123',
);
```

### User Preferences

#### Update Notification Preferences
```dart
final preferences = NotificationPreferences(
  userId: 'user123',
  enablePushNotifications: true,
  enableEmailNotifications: true,
  enableSmsNotifications: false,
  typePreferences: {
    NotificationType.bookingReminder24h: true,
    NotificationType.bookingReminder1h: true,
    NotificationType.newChatMessage: true,
    NotificationType.newEstimate: false, // Disabled
    // ... other types
  },
  quietHoursStart: ['22:00'],
  quietHoursEnd: ['08:00'],
  quietDays: [0, 6], // Sunday and Saturday
);

await notificationService.updateUserNotificationPreferences(preferences);
```

#### Get User Preferences
```dart
final preferences = await notificationService.getUserNotificationPreferences('user123');
```

### Notification History

```dart
// Get user's notification history
final history = await notificationService.getUserNotificationHistory(
  'user123',
  limit: 50,
);

// Mark notification as read
await notificationService.markNotificationAsRead('notification123');
```

## 📊 Database Schema

### Firestore Collections

#### notifications
```javascript
{
  userId: string,
  type: 'booking_reminder_24h' | 'booking_reminder_1h' | 'new_chat_message' | ...,
  title: string,
  body: string,
  priority: 'low' | 'normal' | 'high' | 'urgent',
  status: 'pending' | 'sent' | 'delivered' | 'failed' | 'read',
  data: object,
  actionButtons: object,
  createdAt: timestamp,
  scheduledFor: timestamp,
  sentAt: timestamp,
  deliveredAt: timestamp,
  readAt: timestamp,
  errorMessage: string,
  metadata: object
}
```

#### notification_preferences
```javascript
{
  userId: string,
  enablePushNotifications: boolean,
  enableEmailNotifications: boolean,
  enableSmsNotifications: boolean,
  typePreferences: object, // Map<NotificationType, boolean>
  priorityOverrides: object, // Map<NotificationType, NotificationPriority>
  quietHoursStart: string[], // ['22:00', '23:00']
  quietHoursEnd: string[],   // ['08:00', '09:00']
  quietDays: number[],       // [0, 6] (Sunday, Saturday)
  updatedAt: timestamp
}
```

### PostgreSQL Tables

- `notifications` - Notification history and tracking
- `notification_templates` - Reusable notification templates
- `notification_channels` - Notification channel configuration
- `notification_preferences` - User notification preferences
- `notification_delivery_logs` - Delivery audit trail
- `booking_reminder_schedules` - Scheduled booking reminders
- `email_notification_queue` - Email notification queue

## 🔔 Cloud Functions

### Available Functions

#### sendNotification
Sends a single FCM notification to a user.

**Parameters:**
- `userId`: Target user ID
- `title`: Notification title
- `body`: Notification body
- `data`: Additional data payload
- `priority`: Notification priority

#### sendBulkNotifications
Sends notifications to multiple users.

**Parameters:**
- `userIds`: Array of user IDs
- `title`: Notification title
- `body`: Notification body
- `data`: Additional data payload
- `priority`: Notification priority

#### sendBookingReminders
Scheduled function that runs every hour to send booking reminders.

#### cleanupOldNotifications
Scheduled function that runs daily to clean up old notifications.

## 🧪 Testing

### Test File
Run the comprehensive test suite:
```bash
flutter run test_notification_system.dart
```

### Test Features
- Service initialization
- Individual notification types
- Booking reminder scheduling
- Email notifications
- User preferences
- All-in-one test suite

## 📱 User Interface

### Notification Settings Screen
Access via: `NotificationSettingsScreen()`

Features:
- Toggle notification types on/off
- Configure quiet hours
- Set priority overrides
- General notification settings

### Integration Points
The notification system integrates with:
- Chat system (new message notifications)
- Booking system (reminder notifications)
- Estimate system (new estimate notifications)
- Service request system (new request notifications)

## 🔒 Security

### Firestore Rules
- Users can only read/write their own notifications
- Notification templates and channels are read-only for users
- Admin-only write access to templates and channels

### Data Privacy
- FCM tokens are stored securely in user profiles
- Notification data is encrypted in transit
- User preferences are private to each user

## 🚨 Troubleshooting

### Common Issues

#### Notifications Not Received
1. Check FCM token is valid and saved
2. Verify notification permissions are granted
3. Check user notification preferences
4. Verify quiet hours settings

#### Email Notifications Not Working
1. Configure SendGrid API key in `email_notification_service.dart`
2. Verify email templates are properly formatted
3. Check email service configuration

#### Booking Reminders Not Scheduled
1. Ensure `BookingReminderScheduler` is initialized
2. Check booking creation triggers
3. Verify scheduled notification processor is running

### Debug Mode
Enable debug logging by setting:
```dart
// In comprehensive_notification_service.dart
static const bool _debugMode = true;
```

## 📈 Performance

### Optimization Features
- Batch notification processing
- Efficient database queries with proper indexing
- Background processing for scheduled notifications
- Automatic cleanup of old notifications
- Rate limiting for notification delivery

### Monitoring
- Notification delivery success rates
- User engagement metrics
- Performance monitoring via Cloud Functions logs
- Database query performance tracking

## 🔄 Maintenance

### Regular Tasks
1. **Daily**: Clean up old notifications (automated)
2. **Weekly**: Review notification delivery metrics
3. **Monthly**: Update notification templates
4. **Quarterly**: Review and optimize notification preferences

### Database Maintenance
```sql
-- Clean up old notifications
SELECT cleanup_old_notifications(30);

-- Get notification statistics
SELECT * FROM get_notification_stats('user_id');
```

## 🚀 Future Enhancements

### Planned Features
- Rich push notifications with images
- In-app notification center
- Notification analytics dashboard
- A/B testing for notification content
- Smart notification timing based on user behavior
- Multi-language notification support
- Voice notifications
- Notification scheduling UI

### Integration Opportunities
- Slack/Teams notifications for admins
- Webhook support for external systems
- Advanced analytics and reporting
- Machine learning for optimal notification timing

---

## 📞 Support

For issues or questions about the notification system:
1. Check the troubleshooting section above
2. Review the test file for usage examples
3. Check Cloud Functions logs for server-side issues
4. Verify database connectivity and permissions

The notification system is designed to be robust, scalable, and user-friendly while providing comprehensive coverage for all app events and user interactions.
