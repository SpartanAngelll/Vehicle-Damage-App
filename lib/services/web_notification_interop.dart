// Web notification interop using dart:js_interop
// This file provides type-safe access to the browser Notification API

import 'dart:js_interop';
import 'dart:convert';

/// JS interop type for NotificationOptions
@JS()
@anonymous
extension type NotificationOptions._(JSObject _) implements JSObject {
  external factory NotificationOptions({
    String? body,
    String? icon,
    String? badge,
    String? tag,
    bool? requireInteraction,
    bool? silent,
    JSAny? data,
  });

  external String? get body;
  external String? get icon;
  external String? get badge;
  external String? get tag;
  external bool? get requireInteraction;
  external bool? get silent;
  external JSAny? get data;
}

/// JS interop type for Notification
@JS('Notification')
extension type BrowserNotification._(JSObject _) implements JSObject {
  external factory BrowserNotification(String title, [NotificationOptions? options]);

  external String get title;
  external String get body;
  external String get icon;
  external String get badge;
  external String get tag;
  external bool get requireInteraction;
  external bool get silent;
  external JSAny? get data;

  external void close();
  
  // Event handlers
  external set onclick(JSFunction? callback);
  external set onshow(JSFunction? callback);
  external set onerror(JSFunction? callback);
  external set onclose(JSFunction? callback);
  
  // Helper to set onclick with Dart function
  void setOnClick(void Function() callback) {
    onclick = callback.toJS;
  }
}

/// JS interop for Notification static properties and methods
/// Access static properties directly without constructing an instance
@JS('Notification.permission')
external JSString? get _notificationPermission;

@JS('Notification.requestPermission')
external JSPromise<JSString> _notificationRequestPermission();

/// Check if notifications are supported
@JS('typeof')
external JSString _jsTypeof(JSAny? value);

@JS('window.Notification')
external JSAny? get _windowNotification;

bool get isNotificationSupported {
  try {
    // Check if Notification exists by checking its type
    final notificationType = _jsTypeof(_windowNotification);
    // Convert JSString to String for comparison
    final typeString = notificationType is JSString ? notificationType.toDart : notificationType.toString();
    return typeString == 'function';
  } catch (e) {
    // Fallback: try to access Notification.permission directly
    try {
      final _ = _notificationPermission;
      return true;
    } catch (e2) {
      return false;
    }
  }
}

/// Request notification permission
Future<String> requestNotificationPermission() async {
  try {
    // Call Notification.requestPermission() directly
    final promise = _notificationRequestPermission();
    final result = await promise.toDart;
    // Convert JSString to String
    if (result is JSString) {
      return result.toDart;
    }
    return result.toString();
  } catch (e) {
    print('Error requesting permission: $e');
    // Fallback: check permission directly
    try {
      final permission = _notificationPermission;
      if (permission != null) {
        // Convert JSString to String
        if (permission is JSString) {
          return permission.toDart;
        }
        return permission.toString();
      }
    } catch (e2) {
      print('Error getting permission: $e2');
    }
    return 'denied';
  }
}

/// Get current notification permission status
String? getNotificationPermissionStatus() {
  try {
    // Access Notification.permission directly
    final permission = _notificationPermission;
    if (permission != null) {
      // Convert JSString to String
      if (permission is JSString) {
        return permission.toDart;
      }
      return permission.toString();
    }
    return null;
  } catch (e) {
    return null;
  }
}

/// Create a browser notification
BrowserNotification createNotification(String title, [NotificationOptions? options]) {
  if (options != null) {
    return BrowserNotification(title, options);
  } else {
    return BrowserNotification(title);
  }
}

/// Helper to convert Dart Map to JSObject using JSON.parse
@JS('JSON.parse')
external JSObject _jsonParse(JSString json);

/// Helper extension to convert Dart Map to JSObject
extension MapToJS on Map<String, dynamic> {
  JSObject jsify() {
    // Convert Map to JSObject using JSON.parse
    final jsonString = jsonEncode(this);
    return _jsonParse(jsonString.toJS);
  }
}
