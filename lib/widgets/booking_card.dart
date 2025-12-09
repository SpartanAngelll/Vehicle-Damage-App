import 'package:flutter/material.dart';
import '../utils/time_utils.dart';

/// Simple booking model for the calendar grid.
/// This can be adapted to work with your existing Booking model.
class CalendarBooking {
  final String id;
  final DateTime start;
  final DateTime end;
  final String title;
  final String? customerName;
  final Color? color;

  CalendarBooking({
    required this.id,
    required this.start,
    required this.end,
    required this.title,
    this.customerName,
    this.color,
  });

  /// Creates a CalendarBooking from your existing Booking model.
  /// You can adapt this to match your Booking class structure.
  factory CalendarBooking.fromBooking({
    required String id,
    required DateTime start,
    required DateTime end,
    required String title,
    String? customerName,
    Color? color,
  }) {
    return CalendarBooking(
      id: id,
      start: start,
      end: end,
      title: title,
      customerName: customerName,
      color: color,
    );
  }
}

/// A draggable booking card widget that displays a booking in the calendar grid.
class BookingCard extends StatelessWidget {
  final CalendarBooking booking;
  final VoidCallback? onTap;
  final bool isDragging;
  final double? width;
  final double? height;

  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.isDragging = false,
    this.width,
    this.height,
  });

  /// Calculates the height of the card based on booking duration.
  static double calculateHeight(DateTime start, DateTime end, double rowHeight) {
    final slots = TimeUtils.calculateSlotSpan(start, end);
    return slots * rowHeight;
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = booking.color ?? _getColorForBooking(booking.id);
    final opacity = isDragging ? 0.5 : 1.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 1.0),
        decoration: BoxDecoration(
          color: cardColor.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: cardColor.withValues(alpha: 0.3),
            width: 1.0,
          ),
          boxShadow: isDragging
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4.0,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                booking.title,
                style: const TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (booking.customerName != null && booking.customerName!.isNotEmpty) ...[
                const SizedBox(height: 2.0),
                Text(
                  booking.customerName!,
                  style: const TextStyle(
                    fontSize: 10.0,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 2.0),
              Text(
                '${TimeUtils.formatTime(booking.start)} - ${TimeUtils.formatTime(booking.end)}',
                style: const TextStyle(
                  fontSize: 10.0,
                  color: Colors.white70,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Generates a consistent color for a booking based on its ID.
  static Color _getColorForBooking(String id) {
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFEF4444), // Red
      const Color(0xFF14B8A6), // Teal
    ];

    // Use hash code to consistently pick a color
    final index = id.hashCode.abs() % colors.length;
    return colors[index];
  }
}

/// Data class for drag operations.
class BookingDragData {
  final CalendarBooking booking;
  final int originalColumnIndex;
  final int originalRowIndex;

  BookingDragData({
    required this.booking,
    required this.originalColumnIndex,
    required this.originalRowIndex,
  });
}

