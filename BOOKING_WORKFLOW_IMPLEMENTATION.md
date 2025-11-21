# PostgreSQL-Backed Booking Workflow Implementation

## Overview

This implementation adds an InDrive-style booking workflow that uses:
- **Firestore** for real-time UI updates (live booking status, chat, notifications)
- **PostgreSQL** for financial records and long-term data storage (bookings, payment confirmations, reviews)

## Architecture

### Dual Database Strategy

1. **Firestore (Real-time)**
   - Booking status updates
   - Chat messages
   - Real-time UI synchronization
   - Customer PIN (unhashed, shown once)

2. **PostgreSQL (Financial Records)**
   - Booking financial data (agreed price, currency)
   - Hashed PIN storage (SHA-256)
   - Payment confirmations
   - Reviews/ratings (long-term records)

## Workflow Steps

### 1. Customer Submits Service Request
- Stored in Firestore (real-time feed)
- No PostgreSQL entry yet (waiting for price agreement)

### 2. Price Negotiation
- Customer and professional negotiate price in chat
- Agreed price stored in:
  - Firestore (for real-time UI)
  - PostgreSQL (when booking is created)

### 3. Booking Creation
When booking is confirmed:
- **Firestore**: Full booking document with all details
- **PostgreSQL**: Financial record with:
  - `booking_id` (VARCHAR, matches Firestore ID)
  - `customer_id`, `professional_id`
  - `agreed_price`, `currency`
  - `service_location`
  - `start_pin_hash` (SHA-256 hash of 4-digit PIN)
  - `status`, timestamps
- **PIN Generation**: 4-digit PIN generated and hashed (SHA-256) in PostgreSQL
- **PIN Display**: Unhashed PIN shown to customer once in Firestore

### 4. "On My Way" Feature
- Either customer or professional can set status to "on_my_way"
- Determined by travel mode:
  - If professional travels to customer → Professional sets "On My Way"
  - If customer travels to shop → Customer sets "On My Way"
- Updates both Firestore and PostgreSQL

### 5. PIN Verification to Start Job
- Professional requests PIN from customer
- Customer provides 4-digit PIN
- PIN verified against hashed value in PostgreSQL
- When PIN matches:
  - Booking status → "in_progress" (both databases)
  - `job_started_at` timestamp set

### 6. Job Completion Flow
1. **Professional marks job as completed**
   - Updates Firestore → "completed"
   - Updates PostgreSQL → "completed"
   - Shows payment confirmation dialog

2. **Payment Confirmation (Offline)**
   - Professional confirms "Customer has paid the agreed amount"
   - Stored in PostgreSQL `payment_confirmations` table
   - Synced to Firestore for UI

3. **Customer confirms job completion**
   - Customer accepts job as completed
   - Status → "reviewed" (both databases)
   - `job_accepted_at` timestamp set

### 7. Rating/Review System
- **Professional rates customer** (after job completion)
- **Customer rates professional** (after accepting completion)
- Reviews stored in:
  - Firestore (real-time display)
  - PostgreSQL (long-term records)

## Database Schema

### PostgreSQL Tables

#### `bookings`
```sql
- id VARCHAR(255) PRIMARY KEY (matches Firestore ID)
- customer_id, professional_id VARCHAR(255)
- agreed_price DECIMAL(10,2)
- currency VARCHAR(3)
- service_location TEXT
- start_pin_hash VARCHAR(255) -- SHA-256 hash
- status VARCHAR(50)
- timestamps (on_my_way_at, job_started_at, job_completed_at, job_accepted_at)
```

#### `payment_confirmations`
```sql
- booking_id VARCHAR(255) PRIMARY KEY
- professional_id VARCHAR(255)
- amount DECIMAL(10,2)
- confirmed_at TIMESTAMP
- notes TEXT
```

#### `reviews`
```sql
- id UUID PRIMARY KEY
- booking_id VARCHAR(255)
- reviewer_id, reviewee_id VARCHAR(255)
- rating INTEGER (1-5)
- comment TEXT
- created_at, updated_at TIMESTAMP
```

## Key Services

### `PostgresBookingService`
- Handles all PostgreSQL booking operations
- PIN generation and hashing
- Status updates
- Payment confirmations
- Review creation

### `BookingWorkflowService`
- Coordinates between Firestore and PostgreSQL
- Ensures data consistency
- Handles workflow state transitions

### `ChatService` (Updated)
- Creates bookings in both Firestore and PostgreSQL
- Generates and stores PIN

### `ReviewService` (Updated)
- Saves reviews to both Firestore and PostgreSQL

## UI Components

### `BookingStatusActions`
- Displays action buttons based on booking status
- Handles "On My Way", PIN verification, job completion
- Integrated with workflow service

### `PaymentConfirmationDialog`
- Shows when professional marks job as completed
- Confirms offline payment receipt
- Stores confirmation in PostgreSQL

## Setup Instructions

### 1. Database Setup
Run the migration script:
```bash
psql -U postgres -d vehicle_damage_payments -f database/booking_workflow_schema.sql
```

Or manually run:
```sql
\c vehicle_damage_payments;
\i database/booking_workflow_schema.sql
```

### 2. Environment Variables
Ensure PostgreSQL connection is configured:
- `POSTGRES_HOST` (default: localhost)
- `POSTGRES_PORT` (default: 5432)
- `POSTGRES_DB` (default: vehicle_damage_payments)
- `POSTGRES_USER` (default: postgres)
- `POSTGRES_PASSWORD`

### 3. Initialize Services
The services auto-initialize on first use, but you can manually initialize:
```dart
await PostgresBookingService.instance.initialize();
await BookingWorkflowService.instance.initialize();
```

## Workflow States

```
pending → confirmed → on_my_way → in_progress → completed → reviewed
```

### State Transitions

1. **pending → confirmed**: Booking created
2. **confirmed → on_my_way**: Traveling party sets status
3. **on_my_way → in_progress**: PIN verified, job started
4. **in_progress → completed**: Professional marks job complete
5. **completed → reviewed**: Customer accepts completion

## Security Considerations

1. **PIN Storage**
   - PIN is hashed (SHA-256) in PostgreSQL
   - Unhashed PIN only stored in Firestore temporarily (shown once to customer)
   - PIN verification happens server-side (PostgreSQL)

2. **Payment Confirmation**
   - Only professional can confirm payment
   - Confirmation stored in PostgreSQL for audit trail
   - No actual payment processing (offline payment model)

3. **Data Consistency**
   - Firestore is source of truth for real-time UI
   - PostgreSQL is source of truth for financial records
   - Services coordinate updates to both

## Error Handling

- If PostgreSQL is unavailable, Firestore operations continue
- If Firestore is unavailable, PostgreSQL operations continue
- Services log warnings but don't fail the primary operation
- UI gracefully handles partial failures

## Testing

### Manual Testing Checklist

1. ✅ Create booking → Check both Firestore and PostgreSQL
2. ✅ Set "On My Way" → Verify status in both databases
3. ✅ Verify PIN → Test correct and incorrect PINs
4. ✅ Mark job complete → Check payment confirmation dialog
5. ✅ Confirm payment → Verify PostgreSQL record
6. ✅ Accept job completion → Check status update
7. ✅ Submit reviews → Verify both databases

## Files Modified/Created

### New Files
- `lib/services/postgres_booking_service.dart`
- `lib/services/booking_workflow_service.dart`
- `lib/widgets/payment_confirmation_dialog.dart`
- `database/booking_workflow_schema.sql`

### Modified Files
- `lib/services/chat_service.dart` - Integrated PostgreSQL booking creation
- `lib/services/review_service.dart` - Added PostgreSQL review storage
- `lib/widgets/booking_status_actions.dart` - Updated to use workflow service
- `lib/models/booking_models.dart` - Already had necessary fields

## Notes

- No payment gateway integration (offline payment model)
- PIN is 4 digits, generated randomly
- Reviews can be submitted by both parties after job completion
- All timestamps are stored in UTC
- Booking IDs match between Firestore and PostgreSQL for easy lookup

