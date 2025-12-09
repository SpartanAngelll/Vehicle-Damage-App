const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');
const { createClient } = require('@supabase/supabase-js');

// Initialize Firebase Admin SDK
admin.initializeApp();

const db = admin.firestore();

// Supabase configuration
const SUPABASE_URL = functions.config().supabase?.url || process.env.SUPABASE_URL;
if (!SUPABASE_URL) {
  throw new Error('SUPABASE_URL must be configured in Firebase Functions config or environment variables');
}
const SUPABASE_SERVICE_ROLE_KEY = functions.config().supabase?.service_role_key || process.env.SUPABASE_SERVICE_ROLE_KEY;

// Initialize Supabase client with service role key for admin operations
let supabaseClient = null;
if (SUPABASE_SERVICE_ROLE_KEY) {
  supabaseClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  });
  console.log('✅ Supabase client initialized for Firebase Functions');
} else {
  console.warn('⚠️ Supabase service role key not configured. Supabase sync functions will be disabled.');
}

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

// Firestore trigger: Send notification when a new chat message is created
exports.onChatMessageCreated = functions.firestore
  .document('chat_messages/{messageId}')
  .onCreate(async (snap, context) => {
    try {
      const messageData = snap.data();
      const messageId = context.params.messageId;
      
      // Skip system messages
      if (messageData.senderId === 'system' || messageData.type === 'system') {
        console.log('Skipping notification for system message');
        return null;
      }

      const chatRoomId = messageData.chatRoomId;
      const senderId = messageData.senderId;
      const senderName = messageData.senderName || 'Someone';
      const messageContent = messageData.content || '';
      const messagePreview = messageContent.length > 100 
        ? `${messageContent.substring(0, 100)}...` 
        : messageContent;

      // Get chat room to find recipient
      const chatRoomDoc = await db.collection('chat_rooms').doc(chatRoomId).get();
      if (!chatRoomDoc.exists) {
        console.log('Chat room not found:', chatRoomId);
        return null;
      }

      const chatRoomData = chatRoomDoc.data();
      const customerId = chatRoomData.customerId;
      const professionalId = chatRoomData.professionalId;

      // Determine recipient: if sender is customer, recipient is professional, and vice versa
      const recipientId = senderId === customerId ? professionalId : customerId;

      // Don't send notification if recipient is the same as sender
      if (!recipientId || recipientId === senderId) {
        console.log('Skipping notification - recipient is same as sender or missing');
        return null;
      }

      // Get recipient's FCM token(s)
      const recipientDoc = await db.collection('users').doc(recipientId).get();
      if (!recipientDoc.exists) {
        console.log('[onChatMessageCreated] Recipient not found:', recipientId);
        return null;
      }

      const recipientData = recipientDoc.data();
      // Support both single token and array of tokens (for multiple devices)
      let fcmTokens = [];
      if (recipientData.fcmToken) {
        if (Array.isArray(recipientData.fcmToken)) {
          fcmTokens = recipientData.fcmToken;
        } else {
          fcmTokens = [recipientData.fcmToken];
        }
      }

      if (fcmTokens.length === 0) {
        console.log('[onChatMessageCreated] Recipient has no FCM token:', recipientId);
        return null;
      }

      console.log(`[onChatMessageCreated] Found ${fcmTokens.length} FCM token(s) for recipient: ${recipientId}`);

      // Prepare notification
      const title = `New Message from ${senderName}`;
      const body = messagePreview;

      // Prepare FCM message template
      const messageTemplate = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: 'chat_message',
          chatRoomId: chatRoomId,
          messageId: messageId,
          senderId: senderId,
          senderName: senderName,
          timestamp: Date.now().toString(),
        },
        webpush: {
          notification: {
            title: title,
            body: body,
            icon: '/icons/Icon-192.png',
            badge: '/icons/Icon-192.png',
            tag: `chat_${chatRoomId}`,
            requireInteraction: false,
          },
          fcmOptions: {
            link: `/chat?roomId=${chatRoomId}`,
          },
        },
        android: {
          priority: 'high',
          notification: {
            title: title,
            body: body,
            priority: 'high',
            sound: 'default',
            channelId: 'chat_notifications',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
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

      // Send FCM notifications to all devices
      const sendPromises = fcmTokens.map(async (token) => {
        try {
          const message = {
            ...messageTemplate,
            token: token,
          };
          const response = await admin.messaging().send(message);
          console.log(`[onChatMessageCreated] FCM notification sent to token ${token.substring(0, 20)}... Response:`, response);
          return { success: true, token: token.substring(0, 20), response };
        } catch (error) {
          console.error(`[onChatMessageCreated] Failed to send to token ${token.substring(0, 20)}...:`, error);
          // If token is invalid, we might want to remove it from the user's profile
          if (error.code === 'messaging/invalid-registration-token' || 
              error.code === 'messaging/registration-token-not-registered') {
            console.log(`[onChatMessageCreated] Removing invalid token: ${token.substring(0, 20)}...`);
            // Remove invalid token from user's profile
            try {
              const userData = recipientDoc.data();
              if (Array.isArray(userData.fcmToken)) {
                const updatedTokens = userData.fcmToken.filter(t => t !== token);
                await db.collection('users').doc(recipientId).update({
                  fcmToken: updatedTokens.length === 1 ? updatedTokens[0] : updatedTokens,
                });
              } else if (userData.fcmToken === token) {
                await db.collection('users').doc(recipientId).update({
                  fcmToken: admin.firestore.FieldValue.delete(),
                });
              }
            } catch (updateError) {
              console.error('[onChatMessageCreated] Failed to remove invalid token:', updateError);
            }
          }
          return { success: false, token: token.substring(0, 20), error: error.message };
        }
      });

      const results = await Promise.all(sendPromises);
      const successCount = results.filter(r => r.success).length;
      console.log(`[onChatMessageCreated] Sent ${successCount}/${fcmTokens.length} FCM notifications for message: ${messageId}`);

      // Log notification to Firestore
      await db.collection('notifications').add({
        userId: recipientId,
        title: title,
        body: body,
        data: {
          type: 'chat_message',
          chatRoomId: chatRoomId,
          messageId: messageId,
        },
        priority: 'high',
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        fcmMessageId: response,
        method: 'fcm',
      });

      return null;
    } catch (error) {
      console.error('Error sending notification for chat message:', error);
      // Don't throw - we don't want to fail message creation if notification fails
      return null;
    }
  });

// ==============================================
// SUPABASE SYNC FUNCTIONS
// ==============================================

// Helper function to get user ID from Supabase by Firebase UID
async function getSupabaseUserIdByFirebaseUid(firebaseUid) {
  if (!supabaseClient) {
    console.warn('[Supabase Sync] Supabase client not initialized');
    return null;
  }

  try {
    const { data, error } = await supabaseClient
      .from('users')
      .select('id')
      .eq('firebase_uid', firebaseUid)
      .single();

    if (error) {
      console.error('[Supabase Sync] Error getting user by Firebase UID:', error);
      return null;
    }

    return data?.id || null;
  } catch (error) {
    console.error('[Supabase Sync] Exception getting user by Firebase UID:', error);
    return null;
  }
}

// Sync new user to Supabase when created in Firebase Auth
exports.onUserCreate = functions.auth.user().onCreate(async (user) => {
  if (!supabaseClient) {
    console.warn('[onUserCreate] Supabase client not initialized, skipping sync');
    return null;
  }

  try {
    console.log(`[onUserCreate] Syncing user to Supabase: ${user.uid}`);

    // Check if user already exists in Supabase
    const { data: existingUser } = await supabaseClient
      .from('users')
      .select('id')
      .eq('firebase_uid', user.uid)
      .single();

    if (existingUser) {
      console.log(`[onUserCreate] User already exists in Supabase: ${user.uid}`);
      return null;
    }

    // Get user data from Firestore if available
    const userDoc = await db.collection('users').doc(user.uid).get();
    const userData = userDoc.exists ? userDoc.data() : {};

    // Insert user into Supabase
    const { data, error } = await supabaseClient
      .from('users')
      .insert({
        firebase_uid: user.uid,
        email: user.email || '',
        full_name: user.displayName || userData.fullName || userData.name || '',
        display_name: user.displayName || userData.displayName || '',
        profile_photo_url: user.photoURL || userData.profilePhotoUrl || null,
        role: userData.role || 'owner',
        phone_number: user.phoneNumber || userData.phone || null,
        is_verified: user.emailVerified || false,
        is_active: true,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        metadata: userData.metadata || null,
      })
      .select()
      .single();

    if (error) {
      console.error('[onUserCreate] Error syncing user to Supabase:', error);
      throw error;
    }

    console.log(`[onUserCreate] ✅ User synced to Supabase: ${user.uid} -> ${data.id}`);
    return null;
  } catch (error) {
    console.error('[onUserCreate] Failed to sync user to Supabase:', error);
    // Don't throw - we don't want to fail user creation if sync fails
    return null;
  }
});

// Sync chat room to Supabase when created in Firestore
exports.onChatRoomCreated = functions.firestore
  .document('chatRooms/{roomId}')
  .onCreate(async (snap, context) => {
    if (!supabaseClient) {
      console.warn('[onChatRoomCreated] Supabase client not initialized, skipping sync');
      return null;
    }

    try {
      const roomData = snap.data();
      const roomId = context.params.roomId;

      console.log(`[onChatRoomCreated] Syncing chat room to Supabase: ${roomId}`);

      // Get Supabase user IDs from Firebase UIDs
      const customerSupabaseId = await getSupabaseUserIdByFirebaseUid(roomData.customerId);
      const professionalSupabaseId = await getSupabaseUserIdByFirebaseUid(roomData.professionalId);

      if (!customerSupabaseId || !professionalSupabaseId) {
        console.warn(`[onChatRoomCreated] Could not find Supabase user IDs for room ${roomId}`);
        return null;
      }

      // Insert chat room into Supabase
      // Note: chat_rooms.id is UUID, but we store Firestore ID in metadata
      const { data, error } = await supabaseClient
        .from('chat_rooms')
        .insert({
          booking_id: roomData.bookingId || null,
          customer_id: customerSupabaseId,
          professional_id: professionalSupabaseId,
          last_message_at: roomData.lastMessageAt?.toDate?.()?.toISOString() || null,
          last_message_text: roomData.lastMessage || null,
          is_active: true,
          created_at: roomData.createdAt?.toDate?.()?.toISOString() || new Date().toISOString(),
          updated_at: roomData.updatedAt?.toDate?.()?.toISOString() || new Date().toISOString(),
          metadata: {
            firestore_room_id: roomId,
            customer_name: roomData.customerName,
            professional_name: roomData.professionalName,
          },
        })
        .select()
        .single();

      if (error) {
        console.error('[onChatRoomCreated] Error syncing chat room to Supabase:', error);
        throw error;
      }

      console.log(`[onChatRoomCreated] ✅ Chat room synced to Supabase: ${roomId}`);
      return null;
    } catch (error) {
      console.error('[onChatRoomCreated] Failed to sync chat room to Supabase:', error);
      return null;
    }
  });

// Sync chat message to Supabase (for chatRooms/{roomId}/messages/{messageId} subcollection)
exports.onChatMessageCreatedSubcollection = functions.firestore
  .document('chatRooms/{roomId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    if (!supabaseClient) {
      console.warn('[onChatMessageCreatedSubcollection] Supabase client not initialized, skipping sync');
      return null;
    }

    try {
      const messageData = snap.data();
      const messageId = context.params.messageId;
      const roomId = context.params.roomId;

      console.log(`[onChatMessageCreatedSubcollection] Syncing message to Supabase: ${messageId} in room ${roomId}`);

      // Get chat room from Supabase using Firestore room ID in metadata
      const { data: chatRooms } = await supabaseClient
        .from('chat_rooms')
        .select('id')
        .eq('metadata->>firestore_room_id', roomId)
        .limit(1);
      
      const chatRoom = chatRooms && chatRooms.length > 0 ? chatRooms[0] : null;

      if (!chatRoom) {
        console.warn(`[onChatMessageCreatedSubcollection] Chat room not found in Supabase: ${roomId}`);
        return null;
      }

      // Get sender's Supabase user ID
      const senderSupabaseId = await getSupabaseUserIdByFirebaseUid(messageData.senderId);
      if (!senderSupabaseId) {
        console.warn(`[onChatMessageCreatedSubcollection] Could not find Supabase user ID for sender: ${messageData.senderId}`);
        return null;
      }

      // Insert message into Supabase
      // Note: chat_messages.id is UUID, but we store Firestore ID in metadata
      const { data, error } = await supabaseClient
        .from('chat_messages')
        .insert({
          chat_room_id: chatRoom.id,
          sender_id: senderSupabaseId,
          message_text: messageData.text || messageData.content || '',
          message_type: messageData.type || 'text',
          media_url: messageData.imageUrl || null,
          is_read: messageData.read || false,
          created_at: messageData.createdAt?.toDate?.()?.toISOString() || new Date().toISOString(),
          metadata: {
            firestore_message_id: messageId,
            sender_name: messageData.senderName,
          },
        })
        .select()
        .single();

      if (error) {
        console.error('[onChatMessageCreatedSubcollection] Error syncing message to Supabase:', error);
        throw error;
      }

      console.log(`[onChatMessageCreatedSubcollection] ✅ Message synced to Supabase: ${messageId}`);
      return null;
    } catch (error) {
      console.error('[onChatMessageCreatedSubcollection] Failed to sync message to Supabase:', error);
      return null;
    }
  });

// Sync chat message to Supabase (for chat_messages/{messageId} top-level collection)
exports.onChatMessageCreatedTopLevel = functions.firestore
  .document('chat_messages/{messageId}')
  .onCreate(async (snap, context) => {
    if (!supabaseClient) {
      console.warn('[onChatMessageCreatedTopLevel] Supabase client not initialized, skipping sync');
      return null;
    }

    try {
      const messageData = snap.data();
      const messageId = context.params.messageId;

      console.log(`[onChatMessageCreatedTopLevel] Syncing message to Supabase: ${messageId}`);

      // Get chat room from Supabase using Firestore chatRoomId in metadata
      const { data: chatRooms } = await supabaseClient
        .from('chat_rooms')
        .select('id')
        .eq('metadata->>firestore_room_id', messageData.chatRoomId)
        .limit(1);
      
      const chatRoom = chatRooms && chatRooms.length > 0 ? chatRooms[0] : null;

      if (!chatRoom) {
        console.warn(`[onChatMessageCreatedTopLevel] Chat room not found in Supabase: ${messageData.chatRoomId}`);
        return null;
      }

      // Get sender's Supabase user ID
      const senderSupabaseId = await getSupabaseUserIdByFirebaseUid(messageData.senderId);
      if (!senderSupabaseId) {
        console.warn(`[onChatMessageCreatedTopLevel] Could not find Supabase user ID for sender: ${messageData.senderId}`);
        return null;
      }

      // Insert message into Supabase
      // Note: chat_messages.id is UUID, but we store Firestore ID in metadata
      const { data, error } = await supabaseClient
        .from('chat_messages')
        .insert({
          chat_room_id: chatRoom.id,
          sender_id: senderSupabaseId,
          message_text: messageData.content || messageData.text || '',
          message_type: messageData.type || 'text',
          media_url: messageData.imageUrl || null,
          is_read: false,
          created_at: messageData.timestamp?.toDate?.()?.toISOString() || new Date().toISOString(),
          metadata: {
            firestore_message_id: messageId,
            sender_name: messageData.senderName,
          },
        })
        .select()
        .single();

      if (error) {
        console.error('[onChatMessageCreatedTopLevel] Error syncing message to Supabase:', error);
        throw error;
      }

      console.log(`[onChatMessageCreatedTopLevel] ✅ Message synced to Supabase: ${messageId}`);
      return null;
    } catch (error) {
      console.error('[onChatMessageCreatedTopLevel] Failed to sync message to Supabase:', error);
      return null;
    }
  });