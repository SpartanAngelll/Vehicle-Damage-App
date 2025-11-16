import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_functions/cloud_functions.dart';
import '../models/notification_models.dart';
import '../models/booking_models.dart';

class EmailNotificationService {
  static final EmailNotificationService _instance = EmailNotificationService._internal();
  factory EmailNotificationService() => _instance;
  EmailNotificationService._internal();

  // Email service configuration - now using Cloud Functions
  static const String _fromEmail = 'noreply@vehicledamageapp.com';
  static const String _fromName = 'Vehicle Damage App';

  /// Send email notification using Cloud Functions
  Future<bool> sendEmailNotification({
    required String toEmail,
    required String toName,
    required AppNotification notification,
  }) async {
    try {
      final emailContent = _generateEmailContent(notification);
      
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendEmailNotification');
      
      final result = await callable.call({
        'toEmail': toEmail,
        'toName': toName,
        'subject': notification.title,
        'htmlContent': emailContent['html'],
        'textContent': emailContent['text'],
        'data': notification.data,
      });

      if (result.data['success'] == true) {
        print('✅ [EmailService] Email sent successfully to $toEmail');
        return true;
      } else {
        print('❌ [EmailService] Failed to send email: ${result.data}');
        return false;
      }
    } catch (e) {
      print('❌ [EmailService] Error sending email: $e');
      return false;
    }
  }

  /// Send booking reminder email
  Future<bool> sendBookingReminderEmail({
    required String toEmail,
    required String toName,
    required Booking booking,
    required int hoursBefore,
  }) async {
    try {
      final isCustomer = booking.customerId == toEmail; // Simplified check
      final emailContent = _generateBookingReminderEmail(booking, hoursBefore, isCustomer);
      
      final response = await _sendEmail(
        toEmail: toEmail,
        toName: toName,
        subject: emailContent['subject'],
        htmlContent: emailContent['html'],
        textContent: emailContent['text'],
        data: {
          'bookingId': booking.id,
          'type': 'booking_reminder',
          'hoursBefore': hoursBefore,
        },
      );

      if (response.statusCode == 202) {
        print('✅ [EmailService] Booking reminder email sent to $toEmail');
        return true;
      } else {
        print('❌ [EmailService] Failed to send booking reminder email: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ [EmailService] Error sending booking reminder email: $e');
      return false;
    }
  }

  /// Send chat message email notification
  Future<bool> sendChatMessageEmail({
    required String toEmail,
    required String toName,
    required String senderName,
    required String messagePreview,
    required String chatRoomId,
  }) async {
    try {
      final emailContent = _generateChatMessageEmail(senderName, messagePreview);
      
      final response = await _sendEmail(
        toEmail: toEmail,
        toName: toName,
        subject: 'New Message from $senderName',
        htmlContent: emailContent['html'],
        textContent: emailContent['text'],
        data: {
          'chatRoomId': chatRoomId,
          'type': 'chat_message',
        },
      );

      if (response.statusCode == 202) {
        print('✅ [EmailService] Chat message email sent to $toEmail');
        return true;
      } else {
        print('❌ [EmailService] Failed to send chat message email: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ [EmailService] Error sending chat message email: $e');
      return false;
    }
  }

  /// Send estimate notification email
  Future<bool> sendEstimateEmail({
    required String toEmail,
    required String toName,
    required String professionalName,
    required String serviceTitle,
    required double price,
    required String estimateId,
  }) async {
    try {
      final emailContent = _generateEstimateEmail(professionalName, serviceTitle, price);
      
      final response = await _sendEmail(
        toEmail: toEmail,
        toName: toName,
        subject: 'New Estimate Received - $serviceTitle',
        htmlContent: emailContent['html'],
        textContent: emailContent['text'],
        data: {
          'estimateId': estimateId,
          'type': 'new_estimate',
        },
      );

      if (response.statusCode == 202) {
        print('✅ [EmailService] Estimate email sent to $toEmail');
        return true;
      } else {
        print('❌ [EmailService] Failed to send estimate email: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ [EmailService] Error sending estimate email: $e');
      return false;
    }
  }

  Future<http.Response> _sendEmail({
    required String toEmail,
    required String toName,
    required String subject,
    required String htmlContent,
    required String textContent,
    Map<String, dynamic>? data,
  }) async {
    final headers = {
      'Authorization': 'Bearer $_sendGridApiKey',
      'Content-Type': 'application/json',
    };

    final body = {
      'personalizations': [
        {
          'to': [
            {
              'email': toEmail,
              'name': toName,
            }
          ],
          'subject': subject,
        }
      ],
      'from': {
        'email': _fromEmail,
        'name': _fromName,
      },
      'content': [
        {
          'type': 'text/plain',
          'value': textContent,
        },
        {
          'type': 'text/html',
          'value': htmlContent,
        }
      ],
      'custom_args': data ?? {},
    };

    return await http.post(
      Uri.parse(_sendGridUrl),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Map<String, String> _generateEmailContent(AppNotification notification) {
    final html = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${notification.title}</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #2c3e50; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background-color: #f9f9f9; }
        .footer { padding: 20px; text-align: center; font-size: 12px; color: #666; }
        .button { display: inline-block; padding: 10px 20px; background-color: #3498db; color: white; text-decoration: none; border-radius: 5px; margin: 10px 5px; }
        .button:hover { background-color: #2980b9; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Vehicle Damage App</h1>
        </div>
        <div class="content">
            <h2>${notification.title}</h2>
            <p>${notification.body}</p>
            ${_generateActionButtons(notification.actionButtons)}
        </div>
        <div class="footer">
            <p>This is an automated message from Vehicle Damage App.</p>
            <p>If you no longer wish to receive these emails, please update your notification preferences in the app.</p>
        </div>
    </div>
</body>
</html>
    ''';

    final text = '''
${notification.title}

${notification.body}

${_generateActionButtonsText(notification.actionButtons)}

---
This is an automated message from Vehicle Damage App.
If you no longer wish to receive these emails, please update your notification preferences in the app.
    ''';

    return {'html': html, 'text': text};
  }

  Map<String, String> _generateBookingReminderEmail(Booking booking, int hoursBefore, bool isCustomer) {
    final timeStr = _formatTime(booking.scheduledStartTime);
    final dateStr = _formatDate(booking.scheduledStartTime);
    
    final subject = hoursBefore == 24 
        ? 'Booking Reminder - ${booking.serviceTitle}'
        : 'Booking Starting Soon - ${booking.serviceTitle}';
    
    final greeting = isCustomer ? 'Hello ${booking.customerName}' : 'Hello ${booking.professionalName}';
    final reminderText = hoursBefore == 24
        ? 'This is a friendly reminder that you have a ${booking.serviceTitle} appointment scheduled for tomorrow at $timeStr.'
        : 'Your ${booking.serviceTitle} appointment is starting in 1 hour at $timeStr.';
    
    final locationText = isCustomer 
        ? 'Location: ${booking.location}'
        : 'Customer: ${booking.customerName} at ${booking.location}';

    final html = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$subject</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #2c3e50; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background-color: #f9f9f9; }
        .booking-details { background-color: white; padding: 15px; border-radius: 5px; margin: 15px 0; }
        .footer { padding: 20px; text-align: center; font-size: 12px; color: #666; }
        .button { display: inline-block; padding: 10px 20px; background-color: #3498db; color: white; text-decoration: none; border-radius: 5px; margin: 10px 5px; }
        .button:hover { background-color: #2980b9; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Vehicle Damage App</h1>
        </div>
        <div class="content">
            <h2>$subject</h2>
            <p>$greeting,</p>
            <p>$reminderText</p>
            
            <div class="booking-details">
                <h3>Booking Details</h3>
                <p><strong>Service:</strong> ${booking.serviceTitle}</p>
                <p><strong>Date & Time:</strong> $dateStr at $timeStr</p>
                <p><strong>$locationText</strong></p>
                <p><strong>Price:</strong> \$${booking.agreedPrice.toStringAsFixed(2)}</p>
            </div>
            
            <p>
                <a href="#" class="button">View Booking</a>
                <a href="#" class="button">Reschedule</a>
            </p>
        </div>
        <div class="footer">
            <p>This is an automated reminder from Vehicle Damage App.</p>
        </div>
    </div>
</body>
</html>
    ''';

    final text = '''
$subject

$greeting,

$reminderText

Booking Details:
- Service: ${booking.serviceTitle}
- Date & Time: $dateStr at $timeStr
- $locationText
- Price: \$${booking.agreedPrice.toStringAsFixed(2)}

View your booking in the app for more details.

---
This is an automated reminder from Vehicle Damage App.
    ''';

    return {'subject': subject, 'html': html, 'text': text};
  }

  Map<String, String> _generateChatMessageEmail(String senderName, String messagePreview) {
    final html = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>New Message from $senderName</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #2c3e50; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background-color: #f9f9f9; }
        .message { background-color: white; padding: 15px; border-radius: 5px; margin: 15px 0; border-left: 4px solid #3498db; }
        .footer { padding: 20px; text-align: center; font-size: 12px; color: #666; }
        .button { display: inline-block; padding: 10px 20px; background-color: #3498db; color: white; text-decoration: none; border-radius: 5px; margin: 10px 5px; }
        .button:hover { background-color: #2980b9; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Vehicle Damage App</h1>
        </div>
        <div class="content">
            <h2>New Message from $senderName</h2>
            <p>You have received a new message in your chat.</p>
            
            <div class="message">
                <p><strong>$senderName:</strong> $messagePreview</p>
            </div>
            
            <p>
                <a href="#" class="button">Reply</a>
                <a href="#" class="button">View Chat</a>
            </p>
        </div>
        <div class="footer">
            <p>This is an automated message from Vehicle Damage App.</p>
        </div>
    </div>
</body>
</html>
    ''';

    final text = '''
New Message from $senderName

You have received a new message in your chat.

$senderName: $messagePreview

Reply in the app to continue the conversation.

---
This is an automated message from Vehicle Damage App.
    ''';

    return {'html': html, 'text': text};
  }

  Map<String, String> _generateEstimateEmail(String professionalName, String serviceTitle, double price) {
    final html = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>New Estimate Received - $serviceTitle</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #2c3e50; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background-color: #f9f9f9; }
        .estimate-details { background-color: white; padding: 15px; border-radius: 5px; margin: 15px 0; }
        .price { font-size: 24px; font-weight: bold; color: #27ae60; }
        .footer { padding: 20px; text-align: center; font-size: 12px; color: #666; }
        .button { display: inline-block; padding: 10px 20px; background-color: #27ae60; color: white; text-decoration: none; border-radius: 5px; margin: 10px 5px; }
        .button:hover { background-color: #229954; }
        .button.secondary { background-color: #3498db; }
        .button.secondary:hover { background-color: #2980b9; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Vehicle Damage App</h1>
        </div>
        <div class="content">
            <h2>New Estimate Received</h2>
            <p>$professionalName has submitted an estimate for your service request.</p>
            
            <div class="estimate-details">
                <h3>Estimate Details</h3>
                <p><strong>Service:</strong> $serviceTitle</p>
                <p><strong>Professional:</strong> $professionalName</p>
                <p><strong>Estimated Price:</strong> <span class="price">\$${price.toStringAsFixed(2)}</span></p>
            </div>
            
            <p>
                <a href="#" class="button">Accept Estimate</a>
                <a href="#" class="button secondary">View Details</a>
            </p>
        </div>
        <div class="footer">
            <p>This is an automated message from Vehicle Damage App.</p>
        </div>
    </div>
</body>
</html>
    ''';

    final text = '''
New Estimate Received

$professionalName has submitted an estimate for your service request.

Estimate Details:
- Service: $serviceTitle
- Professional: $professionalName
- Estimated Price: \$${price.toStringAsFixed(2)}

Accept the estimate in the app to proceed with the booking.

---
This is an automated message from Vehicle Damage App.
    ''';

    return {'html': html, 'text': text};
  }

  String _generateActionButtons(Map<String, dynamic>? actionButtons) {
    if (actionButtons == null || actionButtons.isEmpty) return '';
    
    final buttons = actionButtons.entries
        .map((entry) => '<a href="#" class="button">${entry.value}</a>')
        .join(' ');
    
    return '<p>$buttons</p>';
  }

  String _generateActionButtonsText(Map<String, dynamic>? actionButtons) {
    if (actionButtons == null || actionButtons.isEmpty) return '';
    
    return actionButtons.values.join(' | ');
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;
    return '$month $day, $year';
  }
}
