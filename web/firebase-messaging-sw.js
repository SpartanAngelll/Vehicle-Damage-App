// Service Worker for Firebase Cloud Messaging
// This file must be in the web root directory

importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// Initialize Firebase in the service worker
firebase.initializeApp({
  apiKey: 'AIzaSyDsLqQSQf7LKwU0X_2e6_xca9YR-7s5t_Y',
  appId: '1:875116012151:web:772ae082592331b9521c72',
  messagingSenderId: '875116012151',
  projectId: 'vehicle-damage-app',
  authDomain: 'vehicle-damage-app.firebaseapp.com',
  storageBucket: 'vehicle-damage-app.firebasestorage.app',
  measurementId: 'G-2SQ6PE3FYB',
});

// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification?.title || 'New Notification';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: payload.data?.notificationId || 'default',
    requireInteraction: false,
    data: payload.data || {},
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification click received.');
  
  event.notification.close();
  
  // Handle navigation based on notification data
  const data = event.notification.data;
  if (data && data.chatRoomId) {
    event.waitUntil(
      clients.openWindow(`/chat?roomId=${data.chatRoomId}`)
    );
  } else if (data && data.bookingId) {
    event.waitUntil(
      clients.openWindow(`/myBookings?bookingId=${data.bookingId}`)
    );
  } else {
    // Default: focus or open the app
    event.waitUntil(
      clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
        if (clientList.length > 0) {
          return clientList[0].focus();
        }
        return clients.openWindow('/');
      })
    );
  }
});

