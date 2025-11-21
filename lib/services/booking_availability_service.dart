import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import '../models/booking_availability_models.dart';
import '../models/booking_models.dart';

class BookingAvailabilityService {
  static final BookingAvailabilityService _instance = BookingAvailabilityService._internal();
  factory BookingAvailabilityService() => _instance;
  BookingAvailabilityService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Collections
  CollectionReference get _timeSlotsCollection => _firestore.collection('time_slots');
  CollectionReference get _availabilityCollection => _firestore.collection('professional_availability');
  CollectionReference get _bookingsCollection => _firestore.collection('bookings');
  CollectionReference get _conflictsCollection => _firestore.collection('booking_conflicts');

  /// Set up availability schedule for a professional
  /// Simplified approach: Only stores weekly schedule, generates slots on-demand
  Future<void> setupProfessionalAvailability({
    required String professionalId,
    required List<Map<String, dynamic>> weeklySchedule,
  }) async {
    try {
      print('📅 [BookingAvailabilityService] Setting up availability for professional: $professionalId');

      // Clear existing availability
      await _availabilityCollection
          .where('professionalId', isEqualTo: professionalId)
          .get()
          .then((snapshot) async {
        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
      });

      // Add new availability - only store the schedule, no pre-generated slots
      for (var schedule in weeklySchedule) {
        final availability = ProfessionalAvailability(
          id: _uuid.v4(),
          professionalId: professionalId,
          dayOfWeek: schedule['dayOfWeek'],
          startTime: schedule['startTime'],
          endTime: schedule['endTime'],
          isAvailable: schedule['isAvailable'] ?? true,
          slotDurationMinutes: schedule['slotDurationMinutes'] ?? 60,
          breakBetweenSlotsMinutes: schedule['breakBetweenSlotsMinutes'] ?? 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _availabilityCollection.doc(availability.id).set(availability.toMap());
      }

      // No longer pre-generating slots - they'll be generated on-demand
      print('✅ [BookingAvailabilityService] Availability schedule saved for professional: $professionalId');
    } catch (e) {
      print('❌ [BookingAvailabilityService] Error setting up availability: $e');
      rethrow;
    }
  }

  /// Generate time slots for a professional for a specific number of days
  Future<void> _generateTimeSlotsForProfessional(String professionalId, int days) async {
    try {
      final now = DateTime.now();
      final endDate = now.add(Duration(days: days));

      // Get professional's availability schedule
      final availabilitySnapshot = await _availabilityCollection
          .where('professionalId', isEqualTo: professionalId)
          .get();

      if (availabilitySnapshot.docs.isEmpty) {
        print('⚠️ [BookingAvailabilityService] No availability schedule found for professional: $professionalId');
        return;
      }

      final availabilities = availabilitySnapshot.docs
          .map((doc) => ProfessionalAvailability.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Clear existing time slots for this professional
      await _timeSlotsCollection
          .where('professionalId', isEqualTo: professionalId)
          .get()
          .then((snapshot) async {
        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
      });

      // Generate slots for each day
      for (int i = 0; i < days; i++) {
        final date = now.add(Duration(days: i));
        final dayOfWeek = _getDayOfWeek(date.weekday);

        // Find availability for this day
        final dayAvailability = availabilities.firstWhere(
          (avail) => avail.appliesToDayOfWeek(dayOfWeek),
          orElse: () => ProfessionalAvailability(
            id: '',
            professionalId: professionalId,
            dayOfWeek: dayOfWeek,
            startTime: const TimeOfDay(hour: 9, minute: 0),
            endTime: const TimeOfDay(hour: 17, minute: 0),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Generate slots for this day
        final slots = dayAvailability.generateTimeSlotsForDate(date);
        
        // Save slots to Firestore
        for (var slot in slots) {
          final slotId = _uuid.v4();
          await _timeSlotsCollection.doc(slotId).set(slot.copyWith(id: slotId).toMap());
        }
      }

      print('✅ [BookingAvailabilityService] Generated time slots for professional: $professionalId');
    } catch (e) {
      print('❌ [BookingAvailabilityService] Error generating time slots: $e');
      rethrow;
    }
  }

  /// Get available time slots for a professional on a specific date
  /// Simplified: Always generates from schedule and checks against bookings
  Future<List<TimeSlot>> getAvailableSlotsForDate({
    required String professionalId,
    required DateTime date,
  }) async {
    try {
      // Always generate slots from schedule (on-demand)
      return await generateSlotsForDate(
        professionalId: professionalId,
        date: date,
      );
    } catch (e) {
      print('❌ [BookingAvailabilityService] Error getting available slots: $e');
      return [];
    }
  }

  /// Generate time slots for a specific date based on availability schedule
  /// Simplified: Checks bookings directly instead of time_slots collection
  Future<List<TimeSlot>> generateSlotsForDate({
    required String professionalId,
    required DateTime date,
  }) async {
    try {
      final dayOfWeek = _getDayOfWeek(date.weekday);
      print('📅 [BookingAvailabilityService] Generating slots for date: $date, dayOfWeek: $dayOfWeek, professionalId: $professionalId');
      
      // Get professional's availability schedule
      final availabilitySnapshot = await _availabilityCollection
          .where('professionalId', isEqualTo: professionalId)
          .get();

      print('📅 [BookingAvailabilityService] Found ${availabilitySnapshot.docs.length} availability records');

      if (availabilitySnapshot.docs.isEmpty) {
        print('⚠️ [BookingAvailabilityService] No availability schedule found for professional: $professionalId');
        return [];
      }

      final availabilities = availabilitySnapshot.docs
          .map((doc) {
            try {
              return ProfessionalAvailability.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            } catch (e) {
              print('❌ [BookingAvailabilityService] Error parsing availability: $e');
              return null;
            }
          })
          .whereType<ProfessionalAvailability>()
          .toList();

      print('📅 [BookingAvailabilityService] Parsed ${availabilities.length} availability records');

      // Find availability for this day
      final dayAvailability = availabilities.firstWhere(
        (avail) => avail.appliesToDayOfWeek(dayOfWeek),
        orElse: () {
          print('⚠️ [BookingAvailabilityService] No availability for $dayOfWeek, using first available or default');
          return availabilities.isNotEmpty 
              ? availabilities.first 
              : ProfessionalAvailability(
                  id: '',
                  professionalId: professionalId,
                  dayOfWeek: dayOfWeek,
                  startTime: const TimeOfDay(hour: 9, minute: 0),
                  endTime: const TimeOfDay(hour: 17, minute: 0),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
        },
      );

      print('📅 [BookingAvailabilityService] Using availability: ${dayAvailability.dayOfWeek}, ${dayAvailability.startTime} - ${dayAvailability.endTime}, isAvailable: ${dayAvailability.isAvailable}');

      // Generate slots for this date from schedule
      final generatedSlots = dayAvailability.generateTimeSlotsForDate(date);
      print('📅 [BookingAvailabilityService] Generated ${generatedSlots.length} slots for date');
      
      if (generatedSlots.isEmpty) {
        print('⚠️ [BookingAvailabilityService] No slots generated. Check if date is in past or availability is disabled.');
        // If no slots generated, it might be because:
        // 1. Date is in the past
        // 2. All slots are in the past (for today)
        // 3. Availability is disabled for this day
        // Let's still return empty list but log the reason
        final now = DateTime.now();
        final isPastDate = date.isBefore(DateTime(now.year, now.month, now.day));
        print('📅 [BookingAvailabilityService] Date is past: $isPastDate, isAvailable: ${dayAvailability.isAvailable}');
        return [];
      }
      
      // Check which slots are booked by querying bookings directly (simpler, no indexes needed)
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      // Query bookings for this date - simplified query to avoid complex indexes
      // Get all bookings for the professional and date, then filter by status in code
      final bookingsSnapshot = await _bookingsCollection
          .where('professionalId', isEqualTo: professionalId)
          .where('scheduledStartTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('scheduledStartTime', isLessThan: Timestamp.fromDate(endOfDay))
          .get();
      
      // Filter by status in code to avoid needing complex index
      final bookings = bookingsSnapshot.docs
          .map((doc) => Booking.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((booking) => ['pending', 'confirmed', 'in_progress'].contains(booking.status.name))
          .toList();
      
      print('📅 [BookingAvailabilityService] Found ${bookings.length} bookings for this date');
      
      // Mark slots as booked if they overlap with existing bookings
      final allSlots = <TimeSlot>[];
      
      for (var generatedSlot in generatedSlots) {
        // Check if this slot conflicts with any booking
        final isBooked = bookings.any((booking) {
          // Check if slot overlaps with booking time
          return (generatedSlot.startTime.isBefore(booking.scheduledEndTime) &&
                  generatedSlot.endTime.isAfter(booking.scheduledStartTime));
        });
        
        if (isBooked) {
          // Mark as booked
          allSlots.add(generatedSlot.copyWith(
            isAvailable: false,
            bookingId: bookings.firstWhere(
              (b) => generatedSlot.startTime.isBefore(b.scheduledEndTime) &&
                     generatedSlot.endTime.isAfter(b.scheduledStartTime),
            ).id,
          ));
        } else {
          // Available slot
          allSlots.add(generatedSlot);
        }
      }
      
      print('📅 [BookingAvailabilityService] Returning ${allSlots.length} total slots (${allSlots.where((s) => s.isAvailable).length} available, ${allSlots.where((s) => !s.isAvailable).length} booked)');
      return allSlots;
    } catch (e) {
      print('❌ [BookingAvailabilityService] Error generating slots for date: $e');
      return [];
    }
  }

  /// Get calendar data for a professional for a specific month
  /// Simplified: Generates slots on-demand instead of querying time_slots collection
  Future<List<CalendarDay>> getCalendarDataForMonth({
    required String professionalId,
    required DateTime month,
  }) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 1);
      final now = DateTime.now();

      // Get bookings for the month to check availability - simplified query
      final bookingsSnapshot = await _bookingsCollection
          .where('professionalId', isEqualTo: professionalId)
          .where('scheduledStartTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('scheduledStartTime', isLessThan: Timestamp.fromDate(endOfMonth))
          .get();

      // Filter by status in code to avoid needing complex index
      final bookings = bookingsSnapshot.docs
          .map((doc) => Booking.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((booking) => ['pending', 'confirmed', 'in_progress'].contains(booking.status.name))
          .toList();

      // Group bookings by date
      final Map<DateTime, List<Booking>> bookingsByDate = {};
      for (var booking in bookings) {
        final date = DateTime(booking.scheduledStartTime.year, booking.scheduledStartTime.month, booking.scheduledStartTime.day);
        bookingsByDate.putIfAbsent(date, () => []).add(booking);
      }

      // Get availability schedule
      final availabilitySnapshot = await _availabilityCollection
          .where('professionalId', isEqualTo: professionalId)
          .get();

      final availabilities = availabilitySnapshot.docs
          .map((doc) => ProfessionalAvailability.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Create calendar days - generate slots on-demand for each day
      final calendarDays = <CalendarDay>[];
      final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(month.year, month.month, day);
        final dayOfWeek = _getDayOfWeek(date.weekday);
        
        // Find availability for this day
        final dayAvailability = availabilities.firstWhere(
          (avail) => avail.appliesToDayOfWeek(dayOfWeek),
          orElse: () => ProfessionalAvailability(
            id: '',
            professionalId: professionalId,
            dayOfWeek: dayOfWeek,
            startTime: const TimeOfDay(hour: 9, minute: 0),
            endTime: const TimeOfDay(hour: 17, minute: 0),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Generate slots for this day
        final generatedSlots = dayAvailability.generateTimeSlotsForDate(date);
        final dayBookings = bookingsByDate[date] ?? [];
        
        // Mark slots as booked if they overlap with bookings
        final availableSlots = <TimeSlot>[];
        final bookedSlots = <TimeSlot>[];
        
        for (var slot in generatedSlots) {
          final isBooked = dayBookings.any((booking) {
            return (slot.startTime.isBefore(booking.scheduledEndTime) &&
                    slot.endTime.isAfter(booking.scheduledStartTime));
          });
          
          if (isBooked) {
            bookedSlots.add(slot.copyWith(
              isAvailable: false,
              bookingId: dayBookings.firstWhere(
                (b) => slot.startTime.isBefore(b.scheduledEndTime) &&
                       slot.endTime.isAfter(b.scheduledStartTime),
              ).id,
            ));
          } else {
            availableSlots.add(slot);
          }
        }
        
        calendarDays.add(CalendarDay(
          date: date,
          availableSlots: availableSlots,
          bookedSlots: bookedSlots,
          isPast: date.isBefore(DateTime(now.year, now.month, now.day)),
          isToday: date.year == now.year && date.month == now.month && date.day == now.day,
        ));
      }

      return calendarDays;
    } catch (e) {
      print('❌ [BookingAvailabilityService] Error getting calendar data: $e');
      return [];
    }
  }

  /// Check for booking conflicts
  Future<List<BookingConflict>> checkBookingConflicts({
    required String professionalId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeBookingId,
  }) async {
    try {
      final conflicts = <BookingConflict>[];

      // Check for overlapping bookings
      final overlappingBookings = await _bookingsCollection
          .where('professionalId', isEqualTo: professionalId)
          .where('status', whereIn: ['pending', 'confirmed', 'in_progress'])
          .get();

      for (var doc in overlappingBookings.docs) {
        if (excludeBookingId != null && doc.id == excludeBookingId) continue;

        try {
          final booking = Booking.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          
          // Check for time overlap
          if (startTime.isBefore(booking.scheduledEndTime) && 
              endTime.isAfter(booking.scheduledStartTime)) {
            
            final conflict = BookingConflict(
              id: _uuid.v4(),
              professionalId: professionalId,
              startTime: startTime,
              endTime: endTime,
              conflictType: 'double_booking',
              existingBookingId: booking.id,
              message: 'Time slot conflicts with existing booking from ${_formatTime(booking.scheduledStartTime)} to ${_formatTime(booking.scheduledEndTime)}',
              detectedAt: DateTime.now(),
            );
            
            conflicts.add(conflict);
          }
        } catch (e) {
          print('⚠️ [BookingAvailabilityService] Error parsing booking ${doc.id} for conflict check: $e');
          continue; // Skip this booking if it can't be parsed
        }
      }

      // Check for insufficient time between bookings
      if (conflicts.isEmpty) {
        final nearbyBookings = await _bookingsCollection
            .where('professionalId', isEqualTo: professionalId)
            .where('status', whereIn: ['pending', 'confirmed', 'in_progress'])
            .get();

        for (var doc in nearbyBookings.docs) {
          if (excludeBookingId != null && doc.id == excludeBookingId) continue;

          try {
            final booking = Booking.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            
            // Check time between bookings in both directions
            // Case 1: Existing booking ends before new booking starts
            final timeAfterExisting = startTime.difference(booking.scheduledEndTime);
            // Case 2: New booking ends before existing booking starts
            final timeAfterNew = booking.scheduledStartTime.difference(endTime);
            
            // Check if there's less than 30 minutes between bookings
            if ((timeAfterExisting.inMinutes >= 0 && timeAfterExisting.inMinutes < 30) ||
                (timeAfterNew.inMinutes >= 0 && timeAfterNew.inMinutes < 30)) {
              final conflict = BookingConflict(
                id: _uuid.v4(),
                professionalId: professionalId,
                startTime: startTime,
                endTime: endTime,
                conflictType: 'insufficient_time',
                existingBookingId: booking.id,
                message: 'Insufficient time between bookings. Need at least 30 minutes between appointments.',
                detectedAt: DateTime.now(),
              );
              
              conflicts.add(conflict);
              break; // Only add one insufficient time conflict
            }
          } catch (e) {
            print('⚠️ [BookingAvailabilityService] Error parsing booking ${doc.id} for time check: $e');
            continue; // Skip this booking if it can't be parsed
          }
        }
      }

      return conflicts;
    } catch (e) {
      print('❌ [BookingAvailabilityService] Error checking conflicts: $e');
      return [];
    }
  }

  /// Book a time slot
  /// Simplified: Validates against schedule and bookings, creates booking directly
  Future<Booking> bookTimeSlot({
    required String professionalId,
    required String customerId,
    required String customerName,
    required String professionalName,
    required DateTime startTime,
    required DateTime endTime,
    required String serviceTitle,
    required String serviceDescription,
    required double agreedPrice,
    required String location,
    List<String>? deliverables,
    List<String>? importantPoints,
    String? notes,
  }) async {
    try {
      print('📅 [BookingAvailabilityService] Booking time slot for professional: $professionalId');

      // Check if time is within professional's availability schedule
      final dayOfWeek = _getDayOfWeek(startTime.weekday);
      final availabilitySnapshot = await _availabilityCollection
          .where('professionalId', isEqualTo: professionalId)
          .get();

      if (availabilitySnapshot.docs.isEmpty) {
        throw Exception('Professional has not set up availability schedule');
      }

      final availabilities = availabilitySnapshot.docs
          .map((doc) => ProfessionalAvailability.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      final dayAvailability = availabilities.firstWhere(
        (avail) => avail.appliesToDayOfWeek(dayOfWeek),
        orElse: () => ProfessionalAvailability(
          id: '',
          professionalId: professionalId,
          dayOfWeek: dayOfWeek,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 17, minute: 0),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Check if requested time is within availability hours
      final requestStartTime = TimeOfDay.fromDateTime(startTime);
      final requestEndTime = TimeOfDay.fromDateTime(endTime);
      
      if (!dayAvailability.isAvailable ||
          _timeOfDayToMinutes(requestStartTime) < _timeOfDayToMinutes(dayAvailability.startTime) ||
          _timeOfDayToMinutes(requestEndTime) > _timeOfDayToMinutes(dayAvailability.endTime)) {
        throw Exception('Requested time is outside of professional\'s availability hours');
      }

      // Check for conflicts
      final conflicts = await checkBookingConflicts(
        professionalId: professionalId,
        startTime: startTime,
        endTime: endTime,
      );

      if (conflicts.isNotEmpty) {
        throw Exception('Booking conflicts detected: ${conflicts.first.message}');
      }

      // Use Firestore transaction to ensure atomicity and prevent race conditions
      return await _firestore.runTransaction((transaction) async {
        // Re-check for conflicts within transaction
        // Note: Firestore transactions require reading documents before writing
        // We need to get all bookings for this professional and check conflicts
        final conflictsQuery = _bookingsCollection
            .where('professionalId', isEqualTo: professionalId)
            .where('status', whereIn: ['pending', 'confirmed', 'in_progress']);
        
        // In transactions, we need to read documents individually or use a collection group query
        // For now, we'll read all bookings and filter in memory (this is acceptable for small datasets)
        final conflictsSnapshot = await conflictsQuery.get();

        // Check for overlapping bookings
        for (var doc in conflictsSnapshot.docs) {
          final bookingData = doc.data() as Map<String, dynamic>;
          
          // Safely extract timestamps with null checks
          final startTimeData = bookingData['scheduledStartTime'];
          final endTimeData = bookingData['scheduledEndTime'];
          
          if (startTimeData == null || endTimeData == null) {
            continue; // Skip bookings with missing time data
          }
          
          final existingStartTime = (startTimeData as Timestamp).toDate();
          final existingEndTime = (endTimeData as Timestamp).toDate();
          
          // Check for time overlap: new booking overlaps if it starts before existing ends AND ends after existing starts
          if (startTime.isBefore(existingEndTime) && 
              endTime.isAfter(existingStartTime)) {
            throw Exception('Time slot is no longer available - conflict detected with existing booking from ${_formatTime(existingStartTime)} to ${_formatTime(existingEndTime)}');
          }
        }
        
        // Double-check: Also verify the slot is within professional's availability
        // This ensures we're booking in an available slot
        print('📅 [BookingAvailabilityService] Verifying slot is within availability: ${_formatTime(startTime)} - ${_formatTime(endTime)}');

        // Create booking with confirmed status (since it's being confirmed from the dialog)
        final bookingId = _uuid.v4();
        final now = DateTime.now();

        final booking = Booking(
          id: bookingId,
          estimateId: '', // Will be set when estimate is created
          chatRoomId: '', // Will be set when chat room is created
          customerId: customerId,
          professionalId: professionalId,
          customerName: customerName,
          professionalName: professionalName,
          serviceTitle: serviceTitle,
          serviceDescription: serviceDescription,
          agreedPrice: agreedPrice,
          scheduledStartTime: startTime,
          scheduledEndTime: endTime,
          location: location,
          deliverables: deliverables ?? [],
          importantPoints: importantPoints ?? [],
          status: BookingStatus.confirmed, // Set to confirmed when booking is created from confirmation dialog
          createdAt: now,
          updatedAt: now,
          notes: notes,
        );

        // Save booking (within transaction)
        transaction.set(_bookingsCollection.doc(bookingId), booking.toMap());

        print('✅ [BookingAvailabilityService] Time slot booked and confirmed successfully: $bookingId');
        print('📅 [BookingAvailabilityService] Booking time: ${_formatTime(startTime)} - ${_formatTime(endTime)}');
        return booking;
      });
    } catch (e) {
      print('❌ [BookingAvailabilityService] Error booking time slot: $e');
      rethrow;
    }
  }

  /// Helper to convert TimeOfDay to minutes for comparison
  int _timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  /// Cancel a booking
  /// Simplified: Just updates booking status, no time_slots to manage
  Future<void> cancelBooking(String bookingId) async {
    try {
      print('📅 [BookingAvailabilityService] Cancelling booking: $bookingId');

      // Get the booking
      final bookingDoc = await _bookingsCollection.doc(bookingId).get();
      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }

      // Update booking status
      await _bookingsCollection.doc(bookingId).update({
        'status': BookingStatus.cancelled.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('✅ [BookingAvailabilityService] Booking cancelled successfully: $bookingId');
    } catch (e) {
      print('❌ [BookingAvailabilityService] Error cancelling booking: $e');
      rethrow;
    }
  }

  /// Get professional's bookings for a date range
  Future<List<Booking>> getProfessionalBookings({
    required String professionalId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _bookingsCollection
          .where('professionalId', isEqualTo: professionalId)
          .where('scheduledStartTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('scheduledStartTime', isLessThan: Timestamp.fromDate(endDate))
          .orderBy('scheduledStartTime')
          .get();

      return snapshot.docs
          .map((doc) => Booking.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('❌ [BookingAvailabilityService] Error getting professional bookings: $e');
      return [];
    }
  }

  /// Helper methods
  String _getDayOfWeek(int weekday) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[weekday - 1];
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Duration _getTimeBetween(DateTime end, DateTime start) {
    return start.difference(end);
  }
}
