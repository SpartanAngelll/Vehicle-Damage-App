import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

enum NotificationType {
  bookingReminder24h,
  bookingReminder1h,
  newChatMessage,
  newEstimate,
  newServiceRequest,
  bookingStatusUpdate,
  paymentUpdate,
  systemAlert,
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

enum NotificationStatus {
  pending,
  sent,
  delivered,
  failed,
  read,
}

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final NotificationPriority priority;
  final NotificationStatus status;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? actionButtons;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  AppNotification({
    String? id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.priority = NotificationPriority.normal,
    this.status = NotificationStatus.pending,
    this.data,
    this.actionButtons,
    DateTime? createdAt,
    this.scheduledFor,
    this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.errorMessage,
    this.metadata,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  factory AppNotification.fromMap(Map<String, dynamic> map, String documentId) {
    return AppNotification(
      id: documentId,
      userId: map['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.systemAlert,
      ),
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      status: NotificationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => NotificationStatus.pending,
      ),
      data: map['data'],
      actionButtons: map['actionButtons'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      scheduledFor: map['scheduledFor'] != null 
          ? (map['scheduledFor'] as Timestamp).toDate() 
          : null,
      sentAt: map['sentAt'] != null 
          ? (map['sentAt'] as Timestamp).toDate() 
          : null,
      deliveredAt: map['deliveredAt'] != null 
          ? (map['deliveredAt'] as Timestamp).toDate() 
          : null,
      readAt: map['readAt'] != null 
          ? (map['readAt'] as Timestamp).toDate() 
          : null,
      errorMessage: map['errorMessage'],
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'body': body,
      'priority': priority.name,
      'status': status.name,
      'data': data,
      'actionButtons': actionButtons,
      'createdAt': Timestamp.fromDate(createdAt),
      'scheduledFor': scheduledFor != null ? Timestamp.fromDate(scheduledFor!) : null,
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'errorMessage': errorMessage,
      'metadata': metadata,
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    NotificationPriority? priority,
    NotificationStatus? status,
    Map<String, dynamic>? data,
    Map<String, dynamic>? actionButtons,
    DateTime? createdAt,
    DateTime? scheduledFor,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? readAt,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      data: data ?? this.data,
      actionButtons: actionButtons ?? this.actionButtons,
      createdAt: createdAt ?? this.createdAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }
}

class NotificationTemplate {
  final String id;
  final NotificationType type;
  final String titleTemplate;
  final String bodyTemplate;
  final Map<String, dynamic>? defaultData;
  final Map<String, dynamic>? defaultActionButtons;
  final NotificationPriority defaultPriority;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationTemplate({
    String? id,
    required this.type,
    required this.titleTemplate,
    required this.bodyTemplate,
    this.defaultData,
    this.defaultActionButtons,
    this.defaultPriority = NotificationPriority.normal,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory NotificationTemplate.fromMap(Map<String, dynamic> map, String documentId) {
    return NotificationTemplate(
      id: documentId,
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.systemAlert,
      ),
      titleTemplate: map['titleTemplate'] ?? '',
      bodyTemplate: map['bodyTemplate'] ?? '',
      defaultData: map['defaultData'],
      defaultActionButtons: map['defaultActionButtons'],
      defaultPriority: NotificationPriority.values.firstWhere(
        (e) => e.name == map['defaultPriority'],
        orElse: () => NotificationPriority.normal,
      ),
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'titleTemplate': titleTemplate,
      'bodyTemplate': bodyTemplate,
      'defaultData': defaultData,
      'defaultActionButtons': defaultActionButtons,
      'defaultPriority': defaultPriority.name,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  String formatTitle(Map<String, dynamic> variables) {
    String formatted = titleTemplate;
    variables.forEach((key, value) {
      formatted = formatted.replaceAll('{{$key}}', value.toString());
    });
    return formatted;
  }

  String formatBody(Map<String, dynamic> variables) {
    String formatted = bodyTemplate;
    variables.forEach((key, value) {
      formatted = formatted.replaceAll('{{$key}}', value.toString());
    });
    return formatted;
  }
}

class NotificationChannel {
  final String id;
  final String name;
  final String description;
  final NotificationPriority importance;
  final bool enableSound;
  final bool enableVibration;
  final bool enableLights;
  final String? soundFile;
  final String? lightColor;
  final bool isActive;
  final DateTime createdAt;

  NotificationChannel({
    String? id,
    required this.name,
    required this.description,
    this.importance = NotificationPriority.normal,
    this.enableSound = true,
    this.enableVibration = true,
    this.enableLights = false,
    this.soundFile,
    this.lightColor,
    this.isActive = true,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  factory NotificationChannel.fromMap(Map<String, dynamic> map, String documentId) {
    return NotificationChannel(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      importance: NotificationPriority.values.firstWhere(
        (e) => e.name == map['importance'],
        orElse: () => NotificationPriority.normal,
      ),
      enableSound: map['enableSound'] ?? true,
      enableVibration: map['enableVibration'] ?? true,
      enableLights: map['enableLights'] ?? false,
      soundFile: map['soundFile'],
      lightColor: map['lightColor'],
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'importance': importance.name,
      'enableSound': enableSound,
      'enableVibration': enableVibration,
      'enableLights': enableLights,
      'soundFile': soundFile,
      'lightColor': lightColor,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class NotificationPreferences {
  final String userId;
  final bool enablePushNotifications;
  final bool enableEmailNotifications;
  final bool enableSmsNotifications;
  final Map<NotificationType, bool> typePreferences;
  final Map<NotificationType, NotificationPriority> priorityOverrides;
  final List<String> quietHoursStart; // Format: ["22:00", "23:00"]
  final List<String> quietHoursEnd;   // Format: ["08:00", "09:00"]
  final List<int> quietDays; // 0=Sunday, 1=Monday, etc.
  final DateTime updatedAt;

  NotificationPreferences({
    required this.userId,
    this.enablePushNotifications = true,
    this.enableEmailNotifications = true,
    this.enableSmsNotifications = false,
    Map<NotificationType, bool>? typePreferences,
    Map<NotificationType, NotificationPriority>? priorityOverrides,
    this.quietHoursStart = const ["22:00"],
    this.quietHoursEnd = const ["08:00"],
    this.quietDays = const [],
    DateTime? updatedAt,
  }) : typePreferences = typePreferences ?? {
          NotificationType.bookingReminder24h: true,
          NotificationType.bookingReminder1h: true,
          NotificationType.newChatMessage: true,
          NotificationType.newEstimate: true,
          NotificationType.newServiceRequest: true,
          NotificationType.bookingStatusUpdate: true,
          NotificationType.paymentUpdate: true,
          NotificationType.systemAlert: true,
        },
       priorityOverrides = priorityOverrides ?? {},
       updatedAt = updatedAt ?? DateTime.now();

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    final typePrefs = <NotificationType, bool>{};
    final priorityOverrides = <NotificationType, NotificationPriority>{};
    
    if (map['typePreferences'] != null) {
      (map['typePreferences'] as Map<String, dynamic>).forEach((key, value) {
        final type = NotificationType.values.firstWhere(
          (e) => e.name == key,
          orElse: () => NotificationType.systemAlert,
        );
        typePrefs[type] = value as bool? ?? true;
      });
    }

    if (map['priorityOverrides'] != null) {
      (map['priorityOverrides'] as Map<String, dynamic>).forEach((key, value) {
        final type = NotificationType.values.firstWhere(
          (e) => e.name == key,
          orElse: () => NotificationType.systemAlert,
        );
        final priority = NotificationPriority.values.firstWhere(
          (e) => e.name == value,
          orElse: () => NotificationPriority.normal,
        );
        priorityOverrides[type] = priority;
      });
    }

    return NotificationPreferences(
      userId: map['userId'] ?? '',
      enablePushNotifications: map['enablePushNotifications'] ?? true,
      enableEmailNotifications: map['enableEmailNotifications'] ?? true,
      enableSmsNotifications: map['enableSmsNotifications'] ?? false,
      typePreferences: typePrefs,
      priorityOverrides: priorityOverrides,
      quietHoursStart: List<String>.from(map['quietHoursStart'] ?? ["22:00"]),
      quietHoursEnd: List<String>.from(map['quietHoursEnd'] ?? ["08:00"]),
      quietDays: List<int>.from(map['quietDays'] ?? []),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    final typePrefsMap = <String, bool>{};
    typePreferences.forEach((key, value) {
      typePrefsMap[key.name] = value;
    });

    final priorityOverridesMap = <String, String>{};
    priorityOverrides.forEach((key, value) {
      priorityOverridesMap[key.name] = value.name;
    });

    return {
      'userId': userId,
      'enablePushNotifications': enablePushNotifications,
      'enableEmailNotifications': enableEmailNotifications,
      'enableSmsNotifications': enableSmsNotifications,
      'typePreferences': typePrefsMap,
      'priorityOverrides': priorityOverridesMap,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'quietDays': quietDays,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool shouldSendNotification(NotificationType type) {
    if (!enablePushNotifications) return false;
    return typePreferences[type] ?? true;
  }

  NotificationPriority getNotificationPriority(NotificationType type) {
    return priorityOverrides[type] ?? NotificationPriority.normal;
  }

  bool isInQuietHours() {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final currentDay = now.weekday % 7; // Convert to 0=Sunday format

    // Check if current day is in quiet days
    if (quietDays.contains(currentDay)) return true;

    // Check if current time is in quiet hours
    for (int i = 0; i < quietHoursStart.length; i++) {
      final start = quietHoursStart[i];
      final end = quietHoursEnd[i];
      
      if (start.compareTo(end) <= 0) {
        // Same day quiet hours
        if (currentTime.compareTo(start) >= 0 && currentTime.compareTo(end) <= 0) {
          return true;
        }
      } else {
        // Overnight quiet hours
        if (currentTime.compareTo(start) >= 0 || currentTime.compareTo(end) <= 0) {
          return true;
        }
      }
    }

    return false;
  }
}
