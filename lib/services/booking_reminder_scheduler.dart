import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_models.dart';
import 'comprehensive_notification_service.dart';

class BookingReminderScheduler {
  static final BookingReminderScheduler _instance = BookingReminderScheduler._internal();
  factory BookingReminderScheduler() => _instance;
  BookingReminderScheduler._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ComprehensiveNotificationService _notificationService = ComprehensiveNotificationService();
  
  Timer? _schedulerTimer;
  final Map<String, Timer> _bookingTimers = {};

  /// Initialize the booking reminder scheduler
  Future<void> initialize() async {
    try {
      print('⏰ [BookingReminderScheduler] Initializing booking reminder scheduler...');
      
      // Start the main scheduler that runs every hour
      _startMainScheduler();
      
      // Load existing bookings and schedule their reminders
      await _loadAndScheduleExistingBookings();
      
      print('✅ [BookingReminderScheduler] Booking reminder scheduler initialized');
    } catch (e) {
      print('❌ [BookingReminderScheduler] Failed to initialize: $e');
      rethrow;
    }
  }

  void _startMainScheduler() {
    // Run every hour to check for new bookings and reschedule if needed
    _schedulerTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _processBookings(),
    );
  }

  Future<void> _loadAndScheduleExistingBookings() async {
    try {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 30)); // Look ahead 30 days
      
      final snapshot = await _firestore
          .collection('bookings')
          .where('status', whereIn: [
            BookingStatus.pending.name,
            BookingStatus.confirmed.name,
          ])
          .where('scheduledStartTime', isGreaterThan: Timestamp.fromDate(now))
          .where('scheduledStartTime', isLessThan: Timestamp.fromDate(futureDate))
          .get();

      for (final doc in snapshot.docs) {
        final booking = Booking.fromMap(doc.data(), doc.id);
        await _scheduleBookingReminders(booking);
      }

      print('✅ [BookingReminderScheduler] Scheduled reminders for ${snapshot.docs.length} existing bookings');
    } catch (e) {
      print('❌ [BookingReminderScheduler] Failed to load existing bookings: $e');
    }
  }

  Future<void> _processBookings() async {
    try {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 7)); // Look ahead 7 days
      
      final snapshot = await _firestore
          .collection('bookings')
          .where('status', whereIn: [
            BookingStatus.pending.name,
            BookingStatus.confirmed.name,
          ])
          .where('scheduledStartTime', isGreaterThan: Timestamp.fromDate(now))
          .where('scheduledStartTime', isLessThan: Timestamp.fromDate(futureDate))
          .get();

      for (final doc in snapshot.docs) {
        final booking = Booking.fromMap(doc.data(), doc.id);
        
        // Check if reminders are already scheduled
        if (!_bookingTimers.containsKey(booking.id)) {
          await _scheduleBookingReminders(booking);
        }
      }

      print('✅ [BookingReminderScheduler] Processed ${snapshot.docs.length} bookings');
    } catch (e) {
      print('❌ [BookingReminderScheduler] Failed to process bookings: $e');
    }
  }

  /// Schedule reminders for a specific booking
  Future<void> scheduleBookingReminders(Booking booking) async {
    try {
      // Cancel existing timers for this booking
      _cancelBookingTimers(booking.id);
      
      await _scheduleBookingReminders(booking);
      
      print('✅ [BookingReminderScheduler] Scheduled reminders for booking ${booking.id}');
    } catch (e) {
      print('❌ [BookingReminderScheduler] Failed to schedule reminders for booking ${booking.id}: $e');
    }
  }

  Future<void> _scheduleBookingReminders(Booking booking) async {
    final now = DateTime.now();
    final scheduledTime = booking.scheduledStartTime;
    
    // Calculate reminder times
    final reminder24h = scheduledTime.subtract(const Duration(hours: 24));
    final reminder1h = scheduledTime.subtract(const Duration(hours: 1));
    
    // Only schedule if the reminder time is in the future
    if (reminder24h.isAfter(now)) {
      final delay24h = reminder24h.difference(now);
      _bookingTimers['${booking.id}_24h'] = Timer(
        delay24h,
        () => _sendBookingReminder(booking, 24),
      );
      print('⏰ [BookingReminderScheduler] 24h reminder scheduled for booking ${booking.id} in ${delay24h.inHours}h');
    }
    
    if (reminder1h.isAfter(now)) {
      final delay1h = reminder1h.difference(now);
      _bookingTimers['${booking.id}_1h'] = Timer(
        delay1h,
        () => _sendBookingReminder(booking, 1),
      );
      print('⏰ [BookingReminderScheduler] 1h reminder scheduled for booking ${booking.id} in ${delay1h.inHours}h');
    }
  }

  Future<void> _sendBookingReminder(Booking booking, int hoursBefore) async {
    try {
      await _notificationService.sendBookingReminder(
        booking: booking,
        hoursBefore: hoursBefore,
      );
      
      // Remove the timer from our tracking
      _bookingTimers.remove('${booking.id}_${hoursBefore}h');
      
      print('✅ [BookingReminderScheduler] Sent ${hoursBefore}h reminder for booking ${booking.id}');
    } catch (e) {
      print('❌ [BookingReminderScheduler] Failed to send ${hoursBefore}h reminder for booking ${booking.id}: $e');
    }
  }

  /// Cancel reminders for a specific booking
  void cancelBookingReminders(String bookingId) {
    _cancelBookingTimers(bookingId);
    print('✅ [BookingReminderScheduler] Cancelled reminders for booking $bookingId');
  }

  void _cancelBookingTimers(String bookingId) {
    _bookingTimers.remove('${bookingId}_24h')?.cancel();
    _bookingTimers.remove('${bookingId}_1h')?.cancel();
  }

  /// Cancel all reminders
  void cancelAllReminders() {
    for (final timer in _bookingTimers.values) {
      timer.cancel();
    }
    _bookingTimers.clear();
    print('✅ [BookingReminderScheduler] Cancelled all booking reminders');
  }

  /// Get status of scheduled reminders
  Map<String, dynamic> getSchedulerStatus() {
    return {
      'activeTimers': _bookingTimers.length,
      'bookingIds': _bookingTimers.keys
          .map((key) => key.split('_')[0])
          .toSet()
          .toList(),
      'isRunning': _schedulerTimer?.isActive ?? false,
    };
  }

  /// Reschedule all reminders (useful for timezone changes or system restarts)
  Future<void> rescheduleAllReminders() async {
    try {
      print('🔄 [BookingReminderScheduler] Rescheduling all reminders...');
      
      // Cancel all existing timers
      cancelAllReminders();
      
      // Reload and schedule all bookings
      await _loadAndScheduleExistingBookings();
      
      print('✅ [BookingReminderScheduler] All reminders rescheduled');
    } catch (e) {
      print('❌ [BookingReminderScheduler] Failed to reschedule reminders: $e');
    }
  }

  /// Clean up completed bookings
  Future<void> cleanupCompletedBookings() async {
    try {
      final now = DateTime.now();
      final pastDate = now.subtract(const Duration(days: 1));
      
      // Find bookings that are completed or cancelled and are more than 1 day old
      final snapshot = await _firestore
          .collection('bookings')
          .where('status', whereIn: [
            BookingStatus.completed.name,
            BookingStatus.cancelled.name,
          ])
          .where('scheduledStartTime', isLessThan: Timestamp.fromDate(pastDate))
          .get();

      for (final doc in snapshot.docs) {
        final booking = Booking.fromMap(doc.data(), doc.id);
        _cancelBookingTimers(booking.id);
      }

      print('✅ [BookingReminderScheduler] Cleaned up ${snapshot.docs.length} completed bookings');
    } catch (e) {
      print('❌ [BookingReminderScheduler] Failed to cleanup completed bookings: $e');
    }
  }

  void dispose() {
    _schedulerTimer?.cancel();
    cancelAllReminders();
  }
}
