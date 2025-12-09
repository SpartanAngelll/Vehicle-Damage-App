# Booking Calendar Grid Widget

A Fresha/Calendly-style drag-and-drop scheduling calendar widget for Flutter.

## Features

- **Timeline Grid View**: X-axis shows sequential dates, Y-axis shows 24 hours in 30-minute increments
- **Draggable Booking Cards**: Long-press to drag bookings to new time slots
- **Visual Feedback**: Cards become semi-transparent while dragging, drop zones highlight on hover
- **Scrollable**: Both horizontal (dates) and vertical (time) scrolling
- **Clean Architecture**: Separated into reusable widgets and utilities
- **Performance Optimized**: Uses Stack for absolute positioning, minimal re-renders

## Files

- `booking_calendar_grid.dart` - Main grid widget
- `booking_card.dart` - Draggable booking card widget and CalendarBooking model
- `time_utils.dart` - Utility functions for date/time conversions
- `examples/booking_calendar_example.dart` - Example usage screen

## Usage

### Basic Example

```dart
import 'package:flutter/material.dart';
import 'package:your_app/widgets/booking_calendar_grid.dart';
import 'package:your_app/widgets/booking_card.dart';

class MyBookingScreen extends StatefulWidget {
  @override
  State<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends State<MyBookingScreen> {
  List<CalendarBooking> bookings = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BookingCalendarGrid(
        bookings: bookings,
        startDate: DateTime.now(),
        numberOfDays: 7,
        onBookingRescheduled: ({required bookingId, required newStartTime, required newEndTime}) {
          // Update your backend here
          print('Booking $bookingId rescheduled to $newStartTime - $newEndTime');
        },
        onBookingTap: (booking) {
          // Show booking details
          print('Tapped booking: ${booking.title}');
        },
      ),
    );
  }
}
```

### Creating Bookings

```dart
final booking = CalendarBooking(
  id: 'unique-id',
  start: DateTime(2024, 1, 15, 9, 0), // Jan 15, 2024 at 9:00 AM
  end: DateTime(2024, 1, 15, 10, 0),   // Jan 15, 2024 at 10:00 AM
  title: 'Haircut - John Doe',
);
```

### Converting from Your Booking Model

If you have an existing `Booking` model, you can convert it:

```dart
CalendarBooking.fromBooking(
  id: booking.id,
  start: booking.scheduledStartTime,
  end: booking.scheduledEndTime,
  title: booking.serviceTitle,
)
```

## Customization

### Row and Column Sizes

```dart
BookingCalendarGrid(
  rowHeight: 60.0,      // Height of each 30-minute slot
  columnWidth: 200.0,   // Width of each date column
  // ...
)
```

### Grid Appearance

```dart
BookingCalendarGrid(
  showGridLines: true,
  gridLineColor: Colors.grey.shade300,
  // ...
)
```

### Number of Days

```dart
BookingCalendarGrid(
  startDate: DateTime.now(),
  numberOfDays: 14, // Show 2 weeks
  // ...
)
```

## Drag & Drop

1. **Long-press** a booking card to start dragging
2. The card becomes semi-transparent and follows your finger/cursor
3. **Drag** over a valid time slot (highlighted in blue)
4. **Release** to drop the booking
5. The `onBookingRescheduled` callback fires with the new time

The booking automatically snaps to the nearest 30-minute slot.

## Time Utilities

The `TimeUtils` class provides helpful functions:

```dart
// Convert time to row index (0-47)
int row = TimeUtils.timeToRowIndex(dateTime);

// Convert row index to DateTime
DateTime time = TimeUtils.rowIndexToTime(rowIndex, referenceDate);

// Convert date to column index
int col = TimeUtils.dateToColumnIndex(date, startDate);

// Calculate how many slots a booking spans
int slots = TimeUtils.calculateSlotSpan(start, end);

// Format time for display
String formatted = TimeUtils.formatTime(dateTime); // "9:00 AM"
```

## Performance Considerations

- The grid uses a `Stack` with `Positioned` widgets for booking cards
- Drag targets are created for each cell (48 rows × number of days)
- For large date ranges (30+ days), consider pagination or lazy loading
- The grid is optimized to avoid re-rendering the entire widget during drag operations

## Example Screen

See `lib/examples/booking_calendar_example.dart` for a complete working example with:
- Sample bookings
- Rescheduling handler
- Booking tap handler
- Add/delete functionality

## Requirements

- Flutter 3.22+
- Null-safety enabled
- `intl` package (for date formatting)

## Notes

- Bookings automatically span the correct number of cells based on their duration
- Each booking gets a consistent color based on its ID
- The grid supports 24-hour scheduling (00:00 to 23:30)
- Time slots are fixed at 30-minute increments

