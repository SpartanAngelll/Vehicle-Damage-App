# Vehicle Damage App - Complete Deployment Guide

This guide will help you deploy the Cloud Functions for FCM support, set up database schemas, and configure email service for your Vehicle Damage App.

## 🚀 Prerequisites

Before starting, ensure you have:

1. **Firebase CLI** installed: `npm install -g firebase-tools`
2. **Node.js** (version 18 or higher)
3. **PostgreSQL** database running
4. **SendGrid account** for email services
5. **Firebase project** created and configured

## 📋 Step-by-Step Deployment

### 1. Deploy Cloud Functions

#### Option A: Using the deployment script (Windows)
```bash
deploy_functions.bat
```

#### Option B: Manual deployment
```bash
# Navigate to functions directory
cd backend/functions

# Install dependencies
npm install

# Deploy functions
firebase deploy --only functions
```

### 2. Configure SendGrid API Key

After deploying the functions, configure your SendGrid API key:

```bash
firebase functions:config:set sendgrid.api_key="YOUR_SENDGRID_API_KEY"
```

### 3. Set Up Database Schema

Run the complete database schema to set up all required tables:

```bash
# Connect to your PostgreSQL database
psql -d vehicle_damage_payments -f database/complete_schema.sql
```

### 4. Update Flutter Dependencies

Install the new dependencies:

```bash
flutter pub get
```

### 5. Configure Firebase in Flutter

Ensure your `lib/firebase_options.dart` is properly configured with your Firebase project settings.

## 🔧 Available Cloud Functions

The deployment includes the following Cloud Functions:

### Core Notification Functions
- **`sendNotification`** - Send FCM notification to a single user
- **`sendBulkNotifications`** - Send FCM notifications to multiple users
- **`sendEmailNotification`** - Send email notification via SendGrid
- **`sendNotificationWithFallback`** - Send notification with FCM and email fallback

### Scheduled Functions
- **`sendBookingReminders`** - Runs every hour to send booking reminders
- **`cleanupOldNotifications`** - Runs daily to clean up old notifications

## 📊 Database Schema Overview

The complete schema includes:

### Core Tables
- `users` - User profiles and authentication
- `service_professionals` - Extended professional profiles
- `service_categories` - Available service categories
- `job_requests` - Service requests (replaces damage reports)
- `estimates` - Professional estimates
- `bookings` - Confirmed appointments

### Communication Tables
- `chat_rooms` - Chat room management
- `chat_messages` - Individual messages

### Payment Tables
- `invoices` - Invoice management
- `payment_records` - Payment tracking
- `professional_balances` - Professional earnings
- `payouts` - Cash-out requests

### Notification Tables
- `notifications` - Notification history
- `notification_templates` - Email/push templates
- `notification_channels` - Notification channels
- `notification_preferences` - User preferences
- `email_notifications` - Email delivery logs

### System Tables
- `reviews` - User reviews and ratings
- `system_settings` - Application settings
- `audit_logs` - System audit trail

## 🔐 Security Configuration

### Firestore Rules
Ensure your `firestore.rules` includes permissions for the new collections:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Notifications
    match /notifications/{notificationId} {
      allow read, write: if request.auth != null;
    }
    
    // Email notifications (admin only)
    match /email_notifications/{emailId} {
      allow read, write: if request.auth != null;
    }
    
    // Add other collection rules as needed
  }
}
```

### Cloud Functions Security
All functions require authentication and include proper error handling.

## 📧 Email Service Configuration

### SendGrid Setup
1. Create a SendGrid account
2. Generate an API key
3. Configure the API key in Firebase Functions config
4. Verify your sender email address

### Email Templates
The system includes pre-configured email templates for:
- New job requests
- Estimate submissions
- Booking confirmations
- Payment notifications
- System alerts

## 🧪 Testing the Deployment

### Test FCM Notifications
```dart
// In your Flutter app
final functions = FirebaseFunctions.instance;
final callable = functions.httpsCallable('sendNotification');

await callable.call({
  'userId': 'test_user_id',
  'title': 'Test Notification',
  'body': 'This is a test notification',
  'priority': 'normal'
});
```

### Test Email Notifications
```dart
// In your Flutter app
final functions = FirebaseFunctions.instance;
final callable = functions.httpsCallable('sendEmailNotification');

await callable.call({
  'toEmail': 'test@example.com',
  'toName': 'Test User',
  'subject': 'Test Email',
  'htmlContent': '<h1>Test Email</h1><p>This is a test email.</p>',
  'textContent': 'Test Email\n\nThis is a test email.'
});
```

## 🔍 Monitoring and Logs

### View Function Logs
```bash
firebase functions:log
```

### Monitor Function Performance
- Go to Firebase Console → Functions
- View metrics and error rates
- Set up alerts for failures

### Database Monitoring
- Monitor PostgreSQL performance
- Check notification delivery rates
- Review email bounce rates

## 🚨 Troubleshooting

### Common Issues

1. **Functions deployment fails**
   - Check Firebase CLI version
   - Verify project permissions
   - Check Node.js version compatibility

2. **Email notifications not working**
   - Verify SendGrid API key configuration
   - Check email template formatting
   - Review SendGrid account limits

3. **FCM notifications not received**
   - Verify FCM token generation
   - Check device notification permissions
   - Review Firebase project configuration

4. **Database connection issues**
   - Verify PostgreSQL connection string
   - Check database permissions
   - Review schema migration errors

### Getting Help

If you encounter issues:
1. Check the Firebase Console for error logs
2. Review the Cloud Functions logs
3. Verify all configuration steps
4. Test individual components separately

## 📈 Next Steps

After successful deployment:

1. **Configure user preferences** - Set up notification preferences for users
2. **Set up monitoring** - Configure alerts and monitoring
3. **Test end-to-end** - Test the complete notification flow
4. **Optimize performance** - Monitor and optimize function performance
5. **Scale as needed** - Adjust resources based on usage

## 🔄 Maintenance

### Regular Tasks
- Monitor function performance
- Clean up old notifications
- Update email templates
- Review security settings
- Backup database regularly

### Updates
- Keep Firebase CLI updated
- Update Cloud Functions dependencies
- Monitor for security updates
- Test after any updates

---

## 📞 Support

For additional support or questions:
- Check the Firebase documentation
- Review the Cloud Functions logs
- Test individual components
- Verify all configuration steps

Good luck with your deployment! 🚀
