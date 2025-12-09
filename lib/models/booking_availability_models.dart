import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Represents a time slot that can be booked
class TimeSlot {
  final String id;
  final String professionalId;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;
  final String? bookingId; // null if available, contains booking ID if booked
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  TimeSlot({
    required this.id,
    required this.professionalId,
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
    this.bookingId,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory TimeSlot.fromMap(Map<String, dynamic> map, String documentId) {
    return TimeSlot(
      id: documentId,
      professionalId: map['professionalId'] ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      isAvailable: map['isAvailable'] ?? true,
      bookingId: map['bookingId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'professionalId': professionalId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'isAvailable': isAvailable,
      'bookingId': bookingId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  TimeSlot copyWith({
    String? id,
    String? professionalId,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAvailable,
    String? bookingId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return TimeSlot(
      id: id ?? this.id,
      professionalId: professionalId ?? this.professionalId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAvailable: isAvailable ?? this.isAvailable,
      bookingId: bookingId ?? this.bookingId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if this time slot conflicts with another time slot
  bool conflictsWith(TimeSlot other) {
    return startTime.isBefore(other.endTime) && endTime.isAfter(other.startTime);
  }

  /// Check if this time slot contains a specific time
  bool contains(DateTime time) {
    return time.isAfter(startTime) && time.isBefore(endTime);
  }

  /// Get duration of the time slot
  Duration get duration => endTime.difference(startTime);

  @override
  String toString() {
    return 'TimeSlot(id: $id, start: $startTime, end: $endTime, available: $isAvailable)';
  }
}

/// Represents a professional's availability schedule
class ProfessionalAvailability {
  final String id;
  final String professionalId;
  final String dayOfWeek; // 'monday', 'tuesday', etc.
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isAvailable;
  final List<DateTime> blockedDates; // Specific dates when not available
  final int slotDurationMinutes; // Duration of each time slot in minutes
  final int breakBetweenSlotsMinutes; // Break between consecutive slots
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  ProfessionalAvailability({
    required this.id,
    required this.professionalId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
    List<DateTime>? blockedDates,
    this.slotDurationMinutes = 10,
    this.breakBetweenSlotsMinutes = 0,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  }) : blockedDates = blockedDates ?? [];

  factory ProfessionalAvailability.fromMap(Map<String, dynamic> map, String documentId) {
    return ProfessionalAvailability(
      id: documentId,
      professionalId: map['professionalId'] ?? '',
      dayOfWeek: map['dayOfWeek'] ?? '',
      startTime: TimeOfDay(
        hour: map['startTime']['hour'] ?? 9,
        minute: map['startTime']['minute'] ?? 0,
      ),
      endTime: TimeOfDay(
        hour: map['endTime']['hour'] ?? 17,
        minute: map['endTime']['minute'] ?? 0,
      ),
      isAvailable: map['isAvailable'] ?? true,
      blockedDates: (map['blockedDates'] as List<dynamic>?)
          ?.map((e) => (e as Timestamp).toDate())
          .toList() ?? [],
      slotDurationMinutes: map['slotDurationMinutes'] ?? 10,
      breakBetweenSlotsMinutes: map['breakBetweenSlotsMinutes'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'professionalId': professionalId,
      'dayOfWeek': dayOfWeek,
      'startTime': {
        'hour': startTime.hour,
        'minute': startTime.minute,
      },
      'endTime': {
        'hour': endTime.hour,
        'minute': endTime.minute,
      },
      'isAvailable': isAvailable,
      'blockedDates': blockedDates.map((date) => Timestamp.fromDate(date)).toList(),
      'slotDurationMinutes': slotDurationMinutes,
      'breakBetweenSlotsMinutes': breakBetweenSlotsMinutes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  /// Check if a specific date is blocked
  bool isDateBlocked(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return blockedDates.any((blockedDate) => 
      DateTime(blockedDate.year, blockedDate.month, blockedDate.day) == dateOnly);
  }

  /// Check if this availability applies to a specific day of week
  bool appliesToDayOfWeek(String dayOfWeek) {
    return this.dayOfWeek.toLowerCase() == dayOfWeek.toLowerCase();
  }

  /// Generate time slots for a specific date
  List<TimeSlot> generateTimeSlotsForDate(DateTime date) {
    if (!isAvailable || isDateBlocked(date)) {
      return [];
    }

    final slots = <TimeSlot>[];
    final now = DateTime.now();
    
    // Create start time for the date
    var currentTime = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );

    // Create end time for the date
    final endDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      endTime.hour,
      endTime.minute,
    );

    // Generate slots
    while (currentTime.add(Duration(minutes: slotDurationMinutes)).isBefore(endDateTime) ||
           currentTime.add(Duration(minutes: slotDurationMinutes)) == endDateTime) {
      
      final slotEndTime = currentTime.add(Duration(minutes: slotDurationMinutes));
      
      // Only create slots for future times
      if (currentTime.isAfter(now)) {
        slots.add(TimeSlot(
          id: '', // Will be set when saved
          professionalId: professionalId,
          startTime: currentTime,
          endTime: slotEndTime,
          isAvailable: true,
          createdAt: now,
          updatedAt: now,
        ));
      }

      // Move to next slot with break
      currentTime = slotEndTime.add(Duration(minutes: breakBetweenSlotsMinutes));
    }

    return slots;
  }
}

/// Represents a booking conflict
class BookingConflict {
  final String id;
  final String professionalId;
  final DateTime startTime;
  final DateTime endTime;
  final String conflictType; // 'double_booking', 'overlapping', 'insufficient_time'
  final String? existingBookingId;
  final String message;
  final DateTime detectedAt;

  BookingConflict({
    required this.id,
    required this.professionalId,
    required this.startTime,
    required this.endTime,
    required this.conflictType,
    this.existingBookingId,
    required this.message,
    required this.detectedAt,
  });

  factory BookingConflict.fromMap(Map<String, dynamic> map, String documentId) {
    return BookingConflict(
      id: documentId,
      professionalId: map['professionalId'] ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      conflictType: map['conflictType'] ?? '',
      existingBookingId: map['existingBookingId'],
      message: map['message'] ?? '',
      detectedAt: (map['detectedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'professionalId': professionalId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'conflictType': conflictType,
      'existingBookingId': existingBookingId,
      'message': message,
      'detectedAt': Timestamp.fromDate(detectedAt),
    };
  }
}

/// Represents a calendar day with availability information
class CalendarDay {
  final DateTime date;
  final List<TimeSlot> availableSlots;
  final List<TimeSlot> bookedSlots;
  final bool isBlocked;
  final bool isPast;
  final bool isToday;

  CalendarDay({
    required this.date,
    required this.availableSlots,
    required this.bookedSlots,
    this.isBlocked = false,
    this.isPast = false,
    this.isToday = false,
  });

  /// Get all slots (available + booked)
  List<TimeSlot> get allSlots => [...availableSlots, ...bookedSlots];

  /// Check if there are any available slots
  bool get hasAvailableSlots => availableSlots.isNotEmpty;

  /// Get the next available slot
  TimeSlot? get nextAvailableSlot {
    if (availableSlots.isEmpty) return null;
    return availableSlots.first;
  }

  /// Get slots for a specific time range
  List<TimeSlot> getSlotsInRange(DateTime start, DateTime end) {
    return allSlots.where((slot) => 
      slot.startTime.isAfter(start) && slot.endTime.isBefore(end)
    ).toList();
  }
}
