const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

// Initialize Firebase Admin SDK
admin.initializeApp();

const db = admin.firestore();

// Email service configuration
const SENDGRID_API_KEY = functions.config().sendgrid?.api_key || process.env.SENDGRID_API_KEY;
const SENDGRID_URL = 'https://api.sendgrid.com/v3/mail/send';
const FROM_EMAIL = 'noreply@vehicledamageapp.com';
const FROM_NAME = 'Vehicle Damage App';

// Send FCM notification
exports.sendNotification = functions.https.onCall(async (data, context) => {
  try {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { userId, title, body, data: notificationData, priority = 'normal' } = data;

    if (!userId || !title || !body) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }

    // Get user's FCM token
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      throw new functions.https.HttpsError('not-found', 'User has no FCM token');
    }

    // Prepare notification payload
    const message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: {
        ...notificationData,
        timestamp: Date.now().toString(),
      },
      android: {
        priority: priority === 'urgent' ? 'high' : 'normal',
        notification: {
          priority: priority === 'urgent' ? 'high' : 'normal',
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    // Send notification
    const response = await admin.messaging().send(message);

    // Log notification to Firestore
    await db.collection('notifications').add({
      userId: userId,
      title: title,
      body: body,
      data: notificationData,
      priority: priority,
      status: 'sent',
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      fcmMessageId: response,
    });

    return { success: true, messageId: response };
  } catch (error) {
    console.error('Error sending notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send notification');
  }
});

// Send bulk notifications
exports.sendBulkNotifications = functions.https.onCall(async (data, context) => {
  try {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { userIds, title, body, data: notificationData, priority = 'normal' } = data;

    if (!userIds || !Array.isArray(userIds) || userIds.length === 0 || !title || !body) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }

    // Get FCM tokens for all users
    const userDocs = await db.collection('users')
      .where(admin.firestore.FieldPath.documentId(), 'in', userIds)
      .get();

    const tokens = [];
    const validUserIds = [];

    userDocs.forEach(doc => {
      const userData = doc.data();
      if (userData.fcmToken) {
        tokens.push(userData.fcmToken);
        validUserIds.push(doc.id);
      }
    });

    if (tokens.length === 0) {
      throw new functions.https.HttpsError('not-found', 'No valid FCM tokens found');
    }

    // Prepare multicast message
    const message = {
      tokens: tokens,
      notification: {
        title: title,
        body: body,
      },
      data: {
        ...notificationData,
        timestamp: Date.now().toString(),
      },
      android: {
        priority: priority === 'urgent' ? 'high' : 'normal',
        notification: {
          priority: priority === 'urgent' ? 'high' : 'normal',
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    // Send multicast notification
    const response = await admin.messaging().sendMulticast(message);

    // Log notifications to Firestore
    const batch = db.batch();
    validUserIds.forEach(userId => {
      const notificationRef = db.collection('notifications').doc();
      batch.set(notificationRef, {
        userId: userId,
        title: title,
        body: body,
        data: notificationData,
        priority: priority,
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        fcmMessageId: response.messageId,
      });
    });
    await batch.commit();

    return { 
      success: true, 
      successCount: response.successCount,
      failureCount: response.failureCount,
      messageId: response.messageId 
    };
  } catch (error) {
    console.error('Error sending bulk notifications:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send bulk notifications');
  }
});

// Scheduled function to send booking reminders
exports.sendBookingReminders = functions.pubsub.schedule('every 1 hours').onRun(async (context) => {
  try {
    console.log('Running booking reminders check...');
    
    const now = new Date();
    const oneHourFromNow = new Date(now.getTime() + 60 * 60 * 1000);
    const oneDayFromNow = new Date(now.getTime() + 24 * 60 * 60 * 1000);

    // Find bookings that need 24-hour reminders
    const bookings24h = await db.collection('bookings')
      .where('scheduledStartTime', '>=', admin.firestore.Timestamp.fromDate(oneDayFromNow))
      .where('scheduledStartTime', '<=', admin.firestore.Timestamp.fromDate(new Date(oneDayFromNow.getTime() + 60 * 60 * 1000)))
      .where('status', 'in', ['pending', 'confirmed'])
      .get();

    // Find bookings that need 1-hour reminders
    const bookings1h = await db.collection('bookings')
      .where('scheduledStartTime', '>=', admin.firestore.Timestamp.fromDate(oneHourFromNow))
      .where('scheduledStartTime', '<=', admin.firestore.Timestamp.fromDate(new Date(oneHourFromNow.getTime() + 60 * 60 * 1000)))
      .where('status', 'in', ['pending', 'confirmed'])
      .get();

    // Send 24-hour reminders
    for (const bookingDoc of bookings24h.docs) {
      const booking = bookingDoc.data();
      await sendBookingReminderNotification(booking, '24h');
    }

    // Send 1-hour reminders
    for (const bookingDoc of bookings1h.docs) {
      const booking = bookingDoc.data();
      await sendBookingReminderNotification(booking, '1h');
    }

    console.log(`Sent ${bookings24h.docs.length} 24h reminders and ${bookings1h.docs.length} 1h reminders`);
    
    return null;
  } catch (error) {
    console.error('Error in booking reminders function:', error);
    return null;
  }
});

// Helper function to send booking reminder notification
async function sendBookingReminderNotification(booking, reminderType) {
  try {
    const hours = reminderType === '24h' ? 24 : 1;
    const title = hours === 24 
      ? `Booking Reminder - ${booking.serviceTitle}`
      : `Booking Starting Soon - ${booking.serviceTitle}`;
    
    const body = hours === 24
      ? `Your ${booking.serviceTitle} appointment is scheduled for tomorrow at ${formatTime(booking.scheduledStartTime.toDate())}. Location: ${booking.location}`
      : `Your ${booking.serviceTitle} appointment starts in 1 hour at ${booking.location}`;

    // Send to customer
    await sendNotificationToUser(booking.customerId, title, body, {
      bookingId: booking.id,
      type: 'booking_reminder',
      hoursBefore: hours,
    });

    // Send to professional
    await sendNotificationToUser(booking.professionalId, title, body, {
      bookingId: booking.id,
      type: 'booking_reminder',
      hoursBefore: hours,
    });
  } catch (error) {
    console.error(`Error sending ${reminderType} reminder:`, error);
  }
}

// Helper function to send notification to a single user
async function sendNotificationToUser(userId, title, body, data) {
  try {
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;
    if (!fcmToken) return;

    const message = {
      token: fcmToken,
      notification: { title, body },
      data: { ...data, timestamp: Date.now().toString() },
      android: {
        priority: 'high',
        notification: { priority: 'high', sound: 'default' },
      },
      apns: {
        payload: {
          aps: {
            alert: { title, body },
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    await admin.messaging().send(message);
  } catch (error) {
    console.error('Error sending notification to user:', error);
  }
}

// Helper function to format time
function formatTime(date) {
  const hour = date.getHours();
  const minute = date.getMinutes().toString().padStart(2, '0');
  const period = hour >= 12 ? 'PM' : 'AM';
  const displayHour = hour > 12 ? hour - 12 : (hour === 0 ? 12 : hour);
  return `${displayHour}:${minute} ${period}`;
}

// Send email notification with fallback
exports.sendEmailNotification = functions.https.onCall(async (data, context) => {
  try {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { toEmail, toName, subject, htmlContent, textContent, data: emailData } = data;

    if (!toEmail || !subject || !htmlContent) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }

    if (!SENDGRID_API_KEY) {
      throw new functions.https.HttpsError('failed-precondition', 'Email service not configured');
    }

    const emailPayload = {
      personalizations: [{
        to: [{ email: toEmail, name: toName || toEmail }],
        subject: subject,
      }],
      from: { email: FROM_EMAIL, name: FROM_NAME },
      content: [
        { type: 'text/html', value: htmlContent },
        { type: 'text/plain', value: textContent || htmlContent.replace(/<[^>]*>/g, '') }
      ],
      custom_args: emailData || {}
    };

    const response = await axios.post(SENDGRID_URL, emailPayload, {
      headers: {
        'Authorization': `Bearer ${SENDGRID_API_KEY}`,
        'Content-Type': 'application/json'
      }
    });

    // Log email to Firestore
    await db.collection('email_notifications').add({
      toEmail: toEmail,
      toName: toName,
      subject: subject,
      status: 'sent',
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      sendgridMessageId: response.headers['x-message-id'],
      data: emailData
    });

    return { success: true, messageId: response.headers['x-message-id'] };
  } catch (error) {
    console.error('Error sending email notification:', error);
    
    // Log failed email
    await db.collection('email_notifications').add({
      toEmail: data.toEmail,
      toName: data.toName,
      subject: data.subject,
      status: 'failed',
      errorMessage: error.message,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      data: data.data
    });

    throw new functions.https.HttpsError('internal', 'Failed to send email notification');
  }
});

// Send notification with FCM and email fallback
exports.sendNotificationWithFallback = functions.https.onCall(async (data, context) => {
  try {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { userId, title, body, data: notificationData, priority = 'normal', enableEmailFallback = true } = data;

    if (!userId || !title || !body) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }

    // Get user data
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;
    const userEmail = userData.email;
    const userName = userData.fullName || userData.displayName || 'User';

    let fcmSuccess = false;
    let emailSuccess = false;

    // Try FCM first
    if (fcmToken) {
      try {
        const message = {
          token: fcmToken,
          notification: { title, body },
          data: { ...notificationData, timestamp: Date.now().toString() },
          android: {
            priority: priority === 'urgent' ? 'high' : 'normal',
            notification: {
              priority: priority === 'urgent' ? 'high' : 'normal',
              sound: 'default',
            },
          },
          apns: {
            payload: {
              aps: {
                alert: { title, body },
                sound: 'default',
                badge: 1,
              },
            },
          },
        };

        const response = await admin.messaging().send(message);
        fcmSuccess = true;

        // Log FCM notification
        await db.collection('notifications').add({
          userId: userId,
          title: title,
          body: body,
          data: notificationData,
          priority: priority,
          status: 'sent',
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          fcmMessageId: response,
          method: 'fcm'
        });
      } catch (fcmError) {
        console.error('FCM notification failed:', fcmError);
      }
    }

    // Try email fallback if FCM failed or not available
    if ((!fcmSuccess || !fcmToken) && enableEmailFallback && userEmail) {
      try {
        const htmlContent = generateEmailHTML(title, body, notificationData);
        const textContent = generateEmailText(title, body, notificationData);

        const emailPayload = {
          personalizations: [{
            to: [{ email: userEmail, name: userName }],
            subject: title,
          }],
          from: { email: FROM_EMAIL, name: FROM_NAME },
          content: [
            { type: 'text/html', value: htmlContent },
            { type: 'text/plain', value: textContent }
          ],
          custom_args: { ...notificationData, type: 'notification_fallback' }
        };

        const response = await axios.post(SENDGRID_URL, emailPayload, {
          headers: {
            'Authorization': `Bearer ${SENDGRID_API_KEY}`,
            'Content-Type': 'application/json'
          }
        });

        emailSuccess = true;

        // Log email notification
        await db.collection('notifications').add({
          userId: userId,
          title: title,
          body: body,
          data: notificationData,
          priority: priority,
          status: 'sent',
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          sendgridMessageId: response.headers['x-message-id'],
          method: 'email'
        });
      } catch (emailError) {
        console.error('Email notification failed:', emailError);
      }
    }

    if (!fcmSuccess && !emailSuccess) {
      throw new functions.https.HttpsError('internal', 'Both FCM and email notifications failed');
    }

    return { 
      success: true, 
      fcmSuccess, 
      emailSuccess,
      message: fcmSuccess ? 'FCM notification sent' : 'Email notification sent as fallback'
    };
  } catch (error) {
    console.error('Error sending notification with fallback:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send notification');
  }
});

// Clean up old notifications
exports.cleanupOldNotifications = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
  try {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const oldNotifications = await db.collection('notifications')
      .where('createdAt', '<', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
      .where('status', 'in', ['delivered', 'read', 'failed'])
      .limit(500)
      .get();

    const batch = db.batch();
    oldNotifications.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`Cleaned up ${oldNotifications.docs.length} old notifications`);
    
    return null;
  } catch (error) {
    console.error('Error cleaning up old notifications:', error);
    return null;
  }
});

// Helper function to generate email HTML
function generateEmailHTML(title, body, data) {
  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>${title}</title>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #007bff; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background: #f9f9f9; }
        .footer { padding: 20px; text-align: center; color: #666; font-size: 12px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Vehicle Damage App</h1>
        </div>
        <div class="content">
          <h2>${title}</h2>
          <p>${body}</p>
          ${data ? `<p><strong>Additional Details:</strong></p><ul>${Object.entries(data).map(([key, value]) => `<li><strong>${key}:</strong> ${value}</li>`).join('')}</ul>` : ''}
        </div>
        <div class="footer">
          <p>This is an automated notification from Vehicle Damage App.</p>
        </div>
      </div>
    </body>
    </html>
  `;
}

// Helper function to generate email text
function generateEmailText(title, body, data) {
  let text = `${title}\n\n${body}\n\n`;
  if (data) {
    text += 'Additional Details:\n';
    Object.entries(data).forEach(([key, value]) => {
      text += `${key}: ${value}\n`;
    });
  }
  text += '\nThis is an automated notification from Vehicle Damage App.';
  return text;
}
