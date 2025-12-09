-- Test script for booking trigger (Test 5 equivalent)
-- Run this in Supabase SQL Editor to test the booking trigger
-- This will verify that chat_room_id is correctly set as UUID

-- Step 1: Create test users (if they don't exist)
-- Note: Replace with actual Firebase UIDs from your app if you want to test with real users
DO $$
DECLARE
  v_timestamp TEXT := extract(epoch from now())::text;
  v_customer_uid TEXT := 'test-customer-' || v_timestamp;
  v_professional_uid TEXT := 'test-professional-' || v_timestamp;
  v_customer_email TEXT := 'test-customer-' || v_timestamp || '@example.com';
  v_professional_email TEXT := 'test-professional-' || v_timestamp || '@example.com';
  v_test_booking_id TEXT := 'test-booking-' || v_timestamp;
  v_chat_room_id UUID;
  v_invoice_id UUID;
BEGIN
  -- Create test customer user (firebase_uid is now the primary key, no id column)
  -- Use unique email to avoid conflicts
  INSERT INTO users (firebase_uid, email, role, created_at, updated_at)
  VALUES (
    v_customer_uid,
    v_customer_email,
    'owner',  -- Using 'owner' as it's in the CHECK constraint
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
  )
  ON CONFLICT (firebase_uid) DO UPDATE SET email = EXCLUDED.email;
  
  -- Create test professional user
  -- Use unique email to avoid conflicts
  INSERT INTO users (firebase_uid, email, role, created_at, updated_at)
  VALUES (
    v_professional_uid,
    v_professional_email,
    'serviceProfessional',  -- Using 'serviceProfessional' as it's in the CHECK constraint
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
  )
  ON CONFLICT (firebase_uid) DO UPDATE SET email = EXCLUDED.email;
  
  RAISE NOTICE 'Created test users:';
  RAISE NOTICE '  Customer UID: %', v_customer_uid;
  RAISE NOTICE '  Professional UID: %', v_professional_uid;
  
  -- Step 2: Create a test booking (this will trigger the function)
  INSERT INTO bookings (
    id,
    customer_id,
    professional_id,
    customer_name,
    professional_name,
    service_title,
    service_description,
    agreed_price,
    currency,
    scheduled_start_time,
    scheduled_end_time,
    service_location,
    status
  ) VALUES (
    v_test_booking_id,
    v_customer_uid,
    v_professional_uid,
    'Test Customer',
    'Test Professional',
    'Test Service',
    'Test Description',
    100.00,
    'JMD',
    CURRENT_TIMESTAMP + INTERVAL '1 day',
    CURRENT_TIMESTAMP + INTERVAL '1 day 2 hours',
    'Test Location',
    'pending'
  );
  
  RAISE NOTICE 'Created test booking: %', v_test_booking_id;
  
  -- Step 3: Verify the trigger worked
  -- Check if chat_room_id was set (should be UUID, not NULL)
  SELECT chat_room_id INTO v_chat_room_id
  FROM bookings
  WHERE id = v_test_booking_id;
  
  IF v_chat_room_id IS NOT NULL THEN
    RAISE NOTICE '✅ SUCCESS: chat_room_id was set correctly: %', v_chat_room_id;
    RAISE NOTICE '   Type: UUID (correct!)';
  ELSE
    RAISE WARNING '❌ FAILED: chat_room_id is NULL';
  END IF;
  
  -- Check if chat room was created
  SELECT id INTO v_chat_room_id
  FROM chat_rooms
  WHERE booking_id = v_test_booking_id
  LIMIT 1;
  
  IF v_chat_room_id IS NOT NULL THEN
    RAISE NOTICE '✅ SUCCESS: Chat room was created: %', v_chat_room_id;
  ELSE
    RAISE WARNING '⚠️  Chat room was not created';
  END IF;
  
  -- Check if invoice was created
  SELECT id INTO v_invoice_id
  FROM invoices
  WHERE booking_id = v_test_booking_id
  LIMIT 1;
  
  IF v_invoice_id IS NOT NULL THEN
    RAISE NOTICE '✅ SUCCESS: Invoice was created: %', v_invoice_id;
  ELSE
    RAISE WARNING '⚠️  Invoice was not created';
  END IF;
  
  -- Check if notifications were created
  DECLARE
    v_notification_count INTEGER;
  BEGIN
    SELECT COUNT(*) INTO v_notification_count
    FROM notifications
    WHERE data->>'booking_id' = v_test_booking_id;
    
    IF v_notification_count > 0 THEN
      RAISE NOTICE '✅ SUCCESS: % notification(s) were created', v_notification_count;
    ELSE
      RAISE WARNING '⚠️  No notifications were created';
    END IF;
  END;
  
  -- Step 4: Display results
  RAISE NOTICE '';
  RAISE NOTICE '=== Test Results ===';
  RAISE NOTICE 'Booking ID: %', v_test_booking_id;
  RAISE NOTICE 'Chat Room ID: %', (SELECT chat_room_id FROM bookings WHERE id = v_test_booking_id);
  RAISE NOTICE 'Chat Room Created: %', (SELECT COUNT(*) > 0 FROM chat_rooms WHERE booking_id = v_test_booking_id);
  RAISE NOTICE 'Invoice Created: %', (SELECT COUNT(*) > 0 FROM invoices WHERE booking_id = v_test_booking_id);
  RAISE NOTICE 'Notifications Created: %', (SELECT COUNT(*) FROM notifications WHERE data->>'booking_id' = v_test_booking_id);
  
  -- Step 5: Clean up (optional - comment out if you want to inspect the data)
  -- DELETE FROM notifications WHERE data->>'booking_id' = v_test_booking_id;
  -- DELETE FROM invoices WHERE booking_id = v_test_booking_id;
  -- DELETE FROM chat_rooms WHERE booking_id = v_test_booking_id;
  -- DELETE FROM bookings WHERE id = v_test_booking_id;
  -- DELETE FROM users WHERE firebase_uid IN (v_customer_uid, v_professional_uid);
  
  RAISE NOTICE '';
  RAISE NOTICE '✅ Test 5 (Booking Trigger Test) Complete!';
  RAISE NOTICE '   Check the results above to verify the trigger is working correctly.';
  RAISE NOTICE '   To inspect the created records, comment out the cleanup section.';
  
END $$;

-- ==============================================
-- VERIFICATION QUERY
-- ==============================================
-- Run this query separately to see the actual test results
-- This will show what was created by the trigger

SELECT 
  b.id as booking_id,
  b.chat_room_id,
  CASE 
    WHEN b.chat_room_id IS NOT NULL THEN '✅ Set (UUID)'
    ELSE '❌ NULL'
  END as chat_room_id_status,
  b.customer_id,
  b.professional_id,
  CASE 
    WHEN cr.id IS NOT NULL THEN '✅ Created'
    ELSE '❌ Not Created'
  END as chat_room_status,
  cr.id as chat_room_uuid,
  CASE 
    WHEN i.id IS NOT NULL THEN '✅ Created'
    ELSE '❌ Not Created'
  END as invoice_status,
  i.id as invoice_uuid,
  (SELECT COUNT(*) FROM notifications WHERE data->>'booking_id' = b.id) as notification_count,
  b.created_at
FROM bookings b
LEFT JOIN chat_rooms cr ON cr.booking_id = b.id
LEFT JOIN invoices i ON i.booking_id = b.id
WHERE b.id LIKE 'test-booking-%'
ORDER BY b.created_at DESC
LIMIT 5;

