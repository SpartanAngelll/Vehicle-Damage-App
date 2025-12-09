# Booking Triggers Setup

## Overview

Database triggers have been set up to automatically populate all booking-related tables whenever a new booking is created. This ensures data consistency and eliminates the need for manual population of related records.

## What Was Set Up

### Migration File
- **Location**: `supabase/migrations/20240101000007_booking_triggers.sql`
- **Trigger Function**: `populate_booking_related_tables()`
- **Trigger**: `trigger_populate_booking_tables` (fires AFTER INSERT on bookings table)

## What Gets Populated Automatically

When a booking is inserted into the `bookings` table, the trigger automatically:

### 1. **Chat Room Creation**
- Creates a new chat room in the `chat_rooms` table
- Links the chat room to the booking via `booking_id`
- Maps Firebase UIDs to UUID user IDs for customer and professional
- Updates the booking record with the generated `chat_room_id`
- Only creates if `chat_room_id` is not already set and users exist

### 2. **Invoice Creation**
- Creates a draft invoice in the `invoices` table
- Sets total amount to the booking's `agreed_price`
- Calculates deposit and balance amounts (currently 0% deposit by default)
- Sets due date to the scheduled end time or 7 days from now (whichever is later)
- Only creates if an invoice doesn't already exist for the booking

### 3. **Professional Balance Initialization**
- Initializes a balance record in `professional_balances` if it doesn't exist
- Sets all balance fields to 0.00
- Uses the professional's Firebase UID as the key

### 4. **Notification Creation**
- Creates a "booking_confirmed" notification for the customer
- Creates a "new_booking" notification for the professional
- Includes booking details in the notification data (JSONB)
- Prevents duplicate notifications for the same booking

## Important Notes

### User ID Mapping
- The `bookings` table stores Firebase UIDs (VARCHAR) for `customer_id` and `professional_id`
- Related tables (`chat_rooms`, `invoices`) use UUID references to `users.id`
- The trigger automatically converts Firebase UIDs to UUIDs by looking up the `users` table
- If users are not found, warnings are logged but the trigger continues (users might be created later)

### Idempotency
- All operations check for existing records before creating new ones
- Prevents duplicate chat rooms, invoices, and notifications
- Safe to run multiple times without creating duplicates

### Error Handling
- If users are not found, warnings are raised but the trigger doesn't fail
- This allows bookings to be created even if user records are synced later
- Chat rooms and invoices are only created when both user UUIDs are available

## Configuration

### Deposit Percentage
Currently set to 0% by default. To change this:
1. Modify the `v_deposit_percentage` variable in the trigger function
2. Or create a system setting and read it from there

Example:
```sql
-- Read from system_settings table
SELECT setting_value::INTEGER INTO v_deposit_percentage 
FROM system_settings 
WHERE setting_key = 'default_deposit_percentage';
```

## Testing

To test the trigger:

```sql
-- Insert a test booking
INSERT INTO bookings (
  id, customer_id, professional_id, customer_name, professional_name,
  service_title, service_description, agreed_price, currency,
  scheduled_start_time, scheduled_end_time, service_location, status
) VALUES (
  'test-booking-123',
  'firebase-uid-customer',
  'firebase-uid-professional',
  'Test Customer',
  'Test Professional',
  'Test Service',
  'Test Description',
  1000.00,
  'JMD',
  CURRENT_TIMESTAMP + INTERVAL '1 day',
  CURRENT_TIMESTAMP + INTERVAL '1 day 2 hours',
  'Test Location',
  'confirmed'
);

-- Verify chat room was created
SELECT * FROM chat_rooms WHERE booking_id = 'test-booking-123';

-- Verify invoice was created
SELECT * FROM invoices WHERE booking_id = 'test-booking-123';

-- Verify notifications were created
SELECT * FROM notifications WHERE data->>'booking_id' = 'test-booking-123';

-- Verify professional balance was initialized
SELECT * FROM professional_balances WHERE professional_id = 'firebase-uid-professional';
```

## Migration

To apply this migration to your database:

1. **Supabase**: Run the migration file in the Supabase SQL Editor
2. **PostgreSQL**: Run the migration file using `psql` or your preferred database client

```bash
psql -d your_database -f supabase/migrations/20240101000007_booking_triggers.sql
```

## Related Tables Populated

| Table | What Gets Created | Notes |
|-------|------------------|-------|
| `chat_rooms` | New chat room linked to booking | Only if `chat_room_id` is NULL |
| `invoices` | Draft invoice with booking details | Prevents duplicates |
| `professional_balances` | Initial balance record (0.00) | Only if doesn't exist |
| `notifications` | Customer and professional notifications | Prevents duplicates |

## Troubleshooting

### Users Not Found
If you see warnings about users not being found:
- Ensure users exist in the `users` table with matching `firebase_uid` values
- The trigger will still create the booking, but chat rooms and invoices won't be created until users exist

### Duplicate Records
The trigger includes checks to prevent duplicates, but if you see any:
- Check if the trigger is being called multiple times
- Verify that the booking insert is not happening in a transaction that's being retried

### Performance
The trigger performs multiple SELECT and INSERT operations. For high-volume systems:
- Consider adding indexes on `users.firebase_uid` (should already exist)
- Monitor trigger execution time
- Consider batching operations if needed

