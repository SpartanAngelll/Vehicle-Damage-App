# Booking System Implementation

This document describes the comprehensive booking system implemented for the vehicle damage app, which includes availability tracking, calendar functionality, and double-booking prevention.

## Features Implemented

### 1. Time Slot Management
- **TimeSlot Model**: Represents individual bookable time slots with start/end times
- **Availability Tracking**: Tracks which slots are available vs. booked
- **Conflict Detection**: Prevents double booking and overlapping appointments
- **Automatic Generation**: Time slots are automatically generated based on professional availability

### 2. Professional Availability System
- **Weekly Schedule**: Professionals can set their availability for each day of the week
- **Flexible Timing**: Configurable start/end times, slot duration, and breaks between slots
- **Blocked Dates**: Ability to block specific dates when not available
- **Real-time Updates**: Availability changes are immediately reflected in the system

### 3. Calendar Widget
- **Monthly View**: Displays a full month calendar with availability indicators
- **Slot Selection**: Customers can select available time slots
- **Visual Indicators**: Green dots show available slots, different colors for different states
- **Date Navigation**: Easy navigation between months

### 4. Booking Management
- **Professional Interface**: Complete booking management for service professionals
- **Customer Interface**: Easy booking process for customers
- **Status Tracking**: Track booking status from pending to completed
- **Conflict Prevention**: Automatic conflict detection and prevention

## File Structure

### Models
- `lib/models/booking_availability_models.dart` - Core models for availability and time slots
- `lib/models/booking_models.dart` - Existing booking models (updated)

### Services
- `lib/services/booking_availability_service.dart` - Core booking and availability logic
- `lib/services/chat_service.dart` - Updated with booking integration

### UI Components
- `lib/widgets/booking_calendar_widget.dart` - Calendar widget for displaying slots
- `lib/screens/professional_booking_management_screen.dart` - Professional booking management
- `lib/screens/customer_booking_screen.dart` - Customer booking interface
- `lib/screens/booking_integration_example.dart` - Integration example

### Database
- `database/booking_availability_schema.sql` - Database schema for availability tracking

## Database Schema

### New Tables

#### professional_availability
Stores weekly availability schedules for professionals:
```sql
- id (UUID, Primary Key)
- professional_id (UUID, Foreign Key to users)
- day_of_week (VARCHAR, 'monday' to 'sunday')
- start_time (TIME)
- end_time (TIME)
- is_available (BOOLEAN)
- blocked_dates (DATE[])
- slot_duration_minutes (INTEGER)
- break_between_slots_minutes (INTEGER)
```

#### time_slots
Stores individual bookable time slots:
```sql
- id (UUID, Primary Key)
- professional_id (UUID, Foreign Key to users)
- start_time (TIMESTAMP WITH TIME ZONE)
- end_time (TIMESTAMP WITH TIME ZONE)
- is_available (BOOLEAN)
- booking_id (UUID, Foreign Key to bookings, nullable)
```

#### booking_conflicts
Tracks booking conflicts for analysis:
```sql
- id (UUID, Primary Key)
- professional_id (UUID, Foreign Key to users)
- start_time (TIMESTAMP WITH TIME ZONE)
- end_time (TIMESTAMP WITH TIME ZONE)
- conflict_type (VARCHAR)
- existing_booking_id (UUID, Foreign Key to bookings)
- message (TEXT)
```

## Usage Examples

### 1. Setting Up Professional Availability

```dart
final chatService = ChatService();

// Define weekly schedule
final weeklySchedule = [
  {
    'dayOfWeek': 'monday',
    'isAvailable': true,
    'startTime': TimeOfDay(hour: 9, minute: 0),
    'endTime': TimeOfDay(hour: 17, minute: 0),
    'slotDurationMinutes': 10,
    'breakBetweenSlotsMinutes': 0,
  },
  // ... other days
];

// Setup availability
await chatService.setupProfessionalAvailability(
  professionalId: 'professional_id',
  weeklySchedule: weeklySchedule,
);
```

### 2. Getting Available Slots

```dart
final availableSlots = await chatService.getAvailableSlots(
  professionalId: 'professional_id',
  date: DateTime.now().add(Duration(days: 1)),
);
```

### 3. Creating a Booking

```dart
final booking = await chatService.createBookingWithAvailability(
  professionalId: 'professional_id',
  customerId: 'customer_id',
  customerName: 'John Doe',
  professionalName: 'Jane Smith',
  startTime: DateTime(2024, 1, 15, 10, 0),
  endTime: DateTime(2024, 1, 15, 11, 0),
  serviceTitle: 'Engine Diagnostic',
  serviceDescription: 'Complete engine diagnostic',
  agreedPrice: 150.0,
  location: '123 Main St',
);
```

### 4. Using the Calendar Widget

```dart
BookingCalendarWidget(
  professionalId: 'professional_id',
  onDateSelected: (date, slots) {
    // Handle date selection
  },
  onSlotSelected: (slot) {
    // Handle slot selection
  },
  showAvailableSlotsOnly: true,
)
```

## Key Features

### Conflict Detection
The system automatically detects and prevents:
- **Double Booking**: Overlapping time slots
- **Insufficient Time**: Less than 30 minutes between appointments
- **Invalid Slots**: Attempts to book unavailable time slots

### Automatic Time Slot Generation
- Time slots are automatically generated based on professional availability
- Generated for the next 30 days by default
- Automatically updated when availability changes
- Only future time slots are created

### Real-time Updates
- Calendar updates in real-time as bookings are made
- Professional availability changes are immediately reflected
- Booking status updates are synchronized across the system

## Integration Points

### With Existing Chat Service
- New methods added to `ChatService` for booking management
- Seamless integration with existing booking workflow
- Maintains compatibility with existing booking models

### With Professional Profiles
- Availability setup integrated into professional registration
- Booking management accessible from professional dashboard
- Calendar view available in professional interface

### With Customer Interface
- Booking calendar accessible from service selection
- Easy slot selection and booking confirmation
- Integration with existing payment workflow

## Security Considerations

- All booking operations require proper authentication
- Professional availability can only be modified by the professional
- Booking conflicts are checked server-side
- Time slot availability is validated before booking

## Performance Optimizations

- Database indexes on frequently queried fields
- Efficient time slot generation algorithms
- Cached availability data where appropriate
- Optimized calendar rendering

## Future Enhancements

1. **Recurring Availability**: Support for recurring availability patterns
2. **Time Zone Support**: Full time zone handling for global professionals
3. **Advanced Scheduling**: Support for different slot types and durations
4. **Integration APIs**: REST APIs for external system integration
5. **Analytics**: Booking analytics and reporting
6. **Mobile Notifications**: Push notifications for booking updates

## Testing

The system includes comprehensive error handling and validation:
- Conflict detection testing
- Time slot generation testing
- Calendar widget testing
- Integration testing with existing services

## Deployment

1. Run the database migration script: `database/booking_availability_schema.sql`
2. Update Firestore security rules if needed
3. Deploy the updated services
4. Test the integration with existing functionality

This booking system provides a robust foundation for managing service professional availability and customer bookings while preventing conflicts and ensuring a smooth user experience.

