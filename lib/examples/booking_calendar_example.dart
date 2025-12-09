import 'package:flutter/material.dart';
import '../widgets/booking_calendar_grid.dart';
import '../widgets/booking_card.dart';

/// Example screen demonstrating the BookingCalendarGrid widget.
/// 
/// This shows how to:
/// - Create bookings
/// - Handle rescheduling via drag & drop
/// - Handle booking taps
/// - Update the UI when bookings change
class BookingCalendarExampleScreen extends StatefulWidget {
  const BookingCalendarExampleScreen({super.key});

  @override
  State<BookingCalendarExampleScreen> createState() =>
      _BookingCalendarExampleScreenState();
}

class _BookingCalendarExampleScreenState
    extends State<BookingCalendarExampleScreen> {
  // Sample bookings for demonstration
  List<CalendarBooking> _bookings = [];

  @override
  void initState() {
    super.initState();
    _initializeSampleBookings();
  }

  /// Initialize with some sample bookings
  void _initializeSampleBookings() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    setState(() {
      _bookings = [
        // Today's bookings
        CalendarBooking(
          id: 'booking-1',
          start: today.add(const Duration(hours: 9)),
          end: today.add(const Duration(hours: 10)),
          title: 'Haircut - John Doe',
        ),
        CalendarBooking(
          id: 'booking-2',
          start: today.add(const Duration(hours: 11, minutes: 30)),
          end: today.add(const Duration(hours: 12, minutes: 30)),
          title: 'Beard Trim - Mike Smith',
        ),
        CalendarBooking(
          id: 'booking-3',
          start: today.add(const Duration(hours: 14)),
          end: today.add(const Duration(hours: 15, minutes: 30)),
          title: 'Full Service - Sarah Johnson',
        ),
        // Tomorrow's bookings
        CalendarBooking(
          id: 'booking-4',
          start: today.add(const Duration(days: 1, hours: 10)),
          end: today.add(const Duration(days: 1, hours: 11)),
          title: 'Haircut - Emily Brown',
        ),
        CalendarBooking(
          id: 'booking-5',
          start: today.add(const Duration(days: 1, hours: 13)),
          end: today.add(const Duration(days: 1, hours: 14, minutes: 30)),
          title: 'Beard & Hair - David Wilson',
        ),
        // Day after tomorrow
        CalendarBooking(
          id: 'booking-6',
          start: today.add(const Duration(days: 2, hours: 9, minutes: 30)),
          end: today.add(const Duration(days: 2, hours: 10, minutes: 30)),
          title: 'Quick Trim - Lisa Anderson',
        ),
      ];
    });
  }

  /// Handle booking rescheduling via drag & drop
  void _handleBookingRescheduled({
    required String bookingId,
    required DateTime newStartTime,
    required DateTime newEndTime,
  }) {
    setState(() {
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        final booking = _bookings[index];
        _bookings[index] = CalendarBooking(
          id: booking.id,
          start: newStartTime,
          end: newEndTime,
          title: booking.title,
          color: booking.color,
        );
      }
    });

    // Show a snackbar to confirm the change
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Booking rescheduled to ${_formatDateTime(newStartTime)}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    // In a real app, you would update the backend here:
    // await bookingService.updateBooking(bookingId, newStartTime, newEndTime);
  }

  /// Handle booking tap
  void _handleBookingTap(CalendarBooking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(booking.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${booking.id}'),
            const SizedBox(height: 8),
            Text('Start: ${_formatDateTime(booking.start)}'),
            Text('End: ${_formatDateTime(booking.end)}'),
            const SizedBox(height: 8),
            Text(
              'Duration: ${booking.end.difference(booking.start).inMinutes} minutes',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteBooking(booking.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Delete a booking
  void _deleteBooking(String bookingId) {
    setState(() {
      _bookings.removeWhere((b) => b.id == bookingId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking deleted'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Format DateTime for display
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Add a new sample booking
  void _addSampleBooking() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextHour = today.add(
      Duration(
        hours: now.hour + 1,
        minutes: (now.minute ~/ 30) * 30,
      ),
    );

    setState(() {
      _bookings.add(
        CalendarBooking(
          id: 'booking-${DateTime.now().millisecondsSinceEpoch}',
          start: nextHour,
          end: nextHour.add(const Duration(hours: 1)),
          title: 'New Booking',
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final startDate = DateTime.now();
    final startOfWeek = startDate.subtract(Duration(days: startDate.weekday - 1));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Calendar Grid'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addSampleBooking,
            tooltip: 'Add sample booking',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeSampleBookings,
            tooltip: 'Reset to sample bookings',
          ),
        ],
      ),
      body: Column(
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue.shade50,
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Long-press a booking card to drag it to a new time slot. '
                    'Tap a booking to view details.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          // Calendar grid
          Expanded(
            child: BookingCalendarGrid(
              bookings: _bookings,
              startDate: startOfWeek,
              numberOfDays: 7,
              onBookingRescheduled: _handleBookingRescheduled,
              onBookingTap: _handleBookingTap,
              rowHeight: 60.0,
              columnWidth: 200.0,
              showGridLines: true,
            ),
          ),
        ],
      ),
    );
  }
}

