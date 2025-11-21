// Stub file for non-web platforms
// This file provides empty implementations for web notification interop on mobile platforms

/// Stub for NotificationOptions
class NotificationOptions {
  final String? body;
  final String? icon;
  final String? badge;
  final String? tag;
  final bool? requireInteraction;
  final bool? silent;
  final dynamic data;

  NotificationOptions({
    this.body,
    this.icon,
    this.badge,
    this.tag,
    this.requireInteraction,
    this.silent,
    this.data,
  });
}

/// Stub for BrowserNotification
class BrowserNotification {
  final String title;
  final String body;
  final String icon;
  final String badge;
  final String tag;
  final bool requireInteraction;
  final bool silent;
  final dynamic data;

  BrowserNotification(this.title, [NotificationOptions? options])
      : body = options?.body ?? '',
        icon = options?.icon ?? '',
        badge = options?.badge ?? '',
        tag = options?.tag ?? '',
        requireInteraction = options?.requireInteraction ?? false,
        silent = options?.silent ?? false,
        data = options?.data;

  void close() {
    // Stub - no-op on mobile
  }

  set onclick(dynamic callback) {
    // Stub - no-op on mobile
  }
  
  void setOnClick(void Function() callback) {
    // Stub - no-op on mobile
  }

  set onshow(dynamic callback) {
    // Stub - no-op on mobile
  }

  set onerror(dynamic callback) {
    // Stub - no-op on mobile
  }

  set onclose(dynamic callback) {
    // Stub - no-op on mobile
  }
}

/// Stub for notification permission
bool get isNotificationSupported => false;

/// Stub for requesting permission
Future<String> requestNotificationPermission() async {
  return 'denied';
}

/// Stub for notification permission status
dynamic get notificationPermission => null;

/// Stub for getting notification permission status
String? getNotificationPermissionStatus() => null;

/// Stub for creating notification
BrowserNotification createNotification(String title, [NotificationOptions? options]) {
  return BrowserNotification(title, options);
}

/// Stub extension for Map to JS
extension MapToJS on Map<String, dynamic> {
  dynamic jsify() {
    // Return the map as-is on mobile (won't be used anyway)
    return this;
  }
}

