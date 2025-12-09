import 'package:intl/intl.dart';

/// Utility functions for time and date calculations in the booking calendar grid.
class TimeUtils {
  /// Number of 30-minute slots in a day (24 hours * 2)
  static const int slotsPerDay = 48;
  
  /// Duration of each time slot in minutes
  static const int slotDurationMinutes = 30;

  /// Converts a DateTime to a row index (0-47) based on time of day.
  /// Returns the row index for the 30-minute slot containing this time.
  static int timeToRowIndex(DateTime dateTime) {
    final hours = dateTime.hour;
    final minutes = dateTime.minute;
    final totalMinutes = (hours * 60) + minutes;
    return (totalMinutes / slotDurationMinutes).floor().clamp(0, slotsPerDay - 1);
  }

  /// Converts a row index (0-47) to a DateTime time (same day, time only).
  /// The date part is taken from the reference date.
  static DateTime rowIndexToTime(int rowIndex, DateTime referenceDate) {
    final clampedIndex = rowIndex.clamp(0, slotsPerDay - 1);
    final totalMinutes = clampedIndex * slotDurationMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    
    return DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
      hours,
      minutes,
    );
  }

  /// Converts a date to a column index.
  /// Column 0 is the start date, column 1 is start date + 1 day, etc.
  static int dateToColumnIndex(DateTime date, DateTime startDate) {
    final difference = date.difference(startDate).inDays;
    return difference.clamp(0, 365); // Max 1 year ahead
  }

  /// Converts a column index to a date.
  static DateTime columnIndexToDate(int columnIndex, DateTime startDate) {
    return startDate.add(Duration(days: columnIndex));
  }

  /// Calculates the number of 30-minute slots a booking spans.
  static int calculateSlotSpan(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final totalMinutes = duration.inMinutes;
    final slots = (totalMinutes / slotDurationMinutes).ceil();
    return slots.clamp(1, slotsPerDay);
  }

  /// Formats time for display (e.g., "9:00 AM", "2:30 PM").
  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Formats date for display in column header (e.g., "Mon 27 Aug").
  static String formatDateHeader(DateTime date) {
    return DateFormat('EEE d MMM').format(date);
  }

  /// Formats full date for display (e.g., "Monday, August 27, 2022").
  static String formatFullDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, yyyy').format(date);
  }

  /// Gets the start of the day (00:00:00) for a given date.
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Gets the end of the day (23:59:59) for a given date.
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// Snaps a DateTime to the nearest 30-minute slot (rounds down).
  static DateTime snapToSlot(DateTime dateTime) {
    final minutes = dateTime.minute;
    final snappedMinutes = (minutes / slotDurationMinutes).floor() * slotDurationMinutes;
    return DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      snappedMinutes,
    );
  }

  /// Snaps a DateTime to the nearest 30-minute slot (rounds up).
  static DateTime snapToSlotUp(DateTime dateTime) {
    final minutes = dateTime.minute;
    final remainder = minutes % slotDurationMinutes;
    if (remainder == 0) return dateTime;
    
    final snappedMinutes = ((minutes / slotDurationMinutes).floor() + 1) * slotDurationMinutes;
    final hours = dateTime.hour;
    final newHours = snappedMinutes >= 60 ? hours + 1 : hours;
    final newMinutes = snappedMinutes >= 60 ? snappedMinutes - 60 : snappedMinutes;
    
    return DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      newHours.clamp(0, 23),
      newMinutes,
    );
  }

  /// Generates a list of time labels for the Y-axis (00:00 to 23:30).
  static List<String> generateTimeLabels() {
    final labels = <String>[];
    for (int i = 0; i < slotsPerDay; i++) {
      final dateTime = DateTime(2022, 1, 1, i ~/ 2, (i % 2) * 30);
      labels.add(formatTime(dateTime));
    }
    return labels;
  }

  /// Generates a list of dates for the X-axis starting from a given date.
  static List<DateTime> generateDateRange(DateTime startDate, int numberOfDays) {
    return List.generate(
      numberOfDays,
      (index) => startDate.add(Duration(days: index)),
    );
  }

  /// Checks if two bookings overlap in time.
  static bool bookingsOverlap(DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    return start1.isBefore(end2) && start2.isBefore(end1);
  }
}

