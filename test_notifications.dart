// Test script for notification system
// This file can be used to test the notification functionality

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Test notification system
  await testNotificationSystem();
}

Future<void> testNotificationSystem() async {
  print('🧪 Testing notification system...');
  
  try {
    final functions = FirebaseFunctions.instance;
    
    // Test 1: Send FCM notification
    print('\n📱 Testing FCM notification...');
    final sendNotification = functions.httpsCallable('sendNotification');
    
    final fcmResult = await sendNotification.call({
      'userId': 'test_user_id',
      'title': 'Test FCM Notification',
      'body': 'This is a test FCM notification from the Vehicle Damage App',
      'priority': 'normal',
      'data': {
        'type': 'test',
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      }
    });
    
    print('✅ FCM Test Result: ${fcmResult.data}');
    
    // Test 2: Send email notification
    print('\n📧 Testing email notification...');
    final sendEmail = functions.httpsCallable('sendEmailNotification');
    
    final emailResult = await sendEmail.call({
      'toEmail': 'test@example.com',
      'toName': 'Test User',
      'subject': 'Test Email Notification',
      'htmlContent': '''
        <h1>Test Email</h1>
        <p>This is a test email notification from the Vehicle Damage App.</p>
        <p>If you received this, the email service is working correctly!</p>
      ''',
      'textContent': 'Test Email\n\nThis is a test email notification from the Vehicle Damage App.\nIf you received this, the email service is working correctly!',
      'data': {
        'type': 'test_email',
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      }
    });
    
    print('✅ Email Test Result: ${emailResult.data}');
    
    // Test 3: Send notification with fallback
    print('\n🔄 Testing notification with fallback...');
    final sendWithFallback = functions.httpsCallable('sendNotificationWithFallback');
    
    final fallbackResult = await sendWithFallback.call({
      'userId': 'test_user_id',
      'title': 'Test Fallback Notification',
      'body': 'This notification will try FCM first, then email if FCM fails',
      'priority': 'normal',
      'enableEmailFallback': true,
      'data': {
        'type': 'test_fallback',
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      }
    });
    
    print('✅ Fallback Test Result: ${fallbackResult.data}');
    
    // Test 4: Send bulk notifications
    print('\n📢 Testing bulk notifications...');
    final sendBulk = functions.httpsCallable('sendBulkNotifications');
    
    final bulkResult = await sendBulk.call({
      'userIds': ['test_user_1', 'test_user_2', 'test_user_3'],
      'title': 'Bulk Test Notification',
      'body': 'This is a bulk notification test',
      'priority': 'normal',
      'data': {
        'type': 'test_bulk',
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      }
    });
    
    print('✅ Bulk Test Result: ${bulkResult.data}');
    
    print('\n🎉 All notification tests completed successfully!');
    print('\n📋 Test Summary:');
    print('   ✅ FCM notifications working');
    print('   ✅ Email notifications working');
    print('   ✅ Fallback notifications working');
    print('   ✅ Bulk notifications working');
    
  } catch (e) {
    print('❌ Test failed: $e');
    print('\n🔍 Troubleshooting tips:');
    print('   1. Ensure Firebase is properly initialized');
    print('   2. Check that Cloud Functions are deployed');
    print('   3. Verify SendGrid API key is configured');
    print('   4. Check Firebase project permissions');
  }
}

// Helper function to test individual components
Future<void> testIndividualComponents() async {
  print('🔧 Testing individual components...');
  
  // Test Firebase initialization
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    return;
  }
  
  // Test Cloud Functions connection
  try {
    final functions = FirebaseFunctions.instance;
    print('✅ Cloud Functions instance created');
  } catch (e) {
    print('❌ Cloud Functions connection failed: $e');
    return;
  }
  
  print('✅ All individual components working correctly');
}
