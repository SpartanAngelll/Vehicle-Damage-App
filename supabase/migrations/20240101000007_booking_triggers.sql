-- Booking triggers to automatically populate related tables
-- Migration: 20240101000007_booking_triggers.sql

-- Function to populate booking-related tables when a booking is created
CREATE OR REPLACE FUNCTION populate_booking_related_tables()
RETURNS TRIGGER AS $$
DECLARE
  v_chat_room_id UUID;
  v_invoice_id UUID;
  v_customer_uuid UUID;
  v_professional_uuid UUID;
  v_deposit_percentage INTEGER := 0; -- Default deposit percentage, can be configured
  v_deposit_amount DECIMAL(10, 2);
  v_balance_amount DECIMAL(10, 2);
  v_due_date TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Get UUID user IDs from Firebase UIDs
  SELECT id INTO v_customer_uuid FROM users WHERE firebase_uid = NEW.customer_id;
  SELECT id INTO v_professional_uuid FROM users WHERE firebase_uid = NEW.professional_id;
  
  -- If users not found, log warning but continue (users might be created later)
  IF v_customer_uuid IS NULL THEN
    RAISE WARNING 'Customer with Firebase UID % not found in users table', NEW.customer_id;
  END IF;
  
  IF v_professional_uuid IS NULL THEN
    RAISE WARNING 'Professional with Firebase UID % not found in users table', NEW.professional_id;
  END IF;
  
  -- Create chat room if it doesn't exist and chat_room_id is not already set
  IF NEW.chat_room_id IS NULL AND v_customer_uuid IS NOT NULL AND v_professional_uuid IS NOT NULL THEN
    -- Check if chat room already exists for this booking
    SELECT id INTO v_chat_room_id 
    FROM chat_rooms 
    WHERE booking_id = NEW.id 
    LIMIT 1;
    
    IF v_chat_room_id IS NULL THEN
      v_chat_room_id := uuid_generate_v4();
      
      INSERT INTO chat_rooms (
        id,
        booking_id,
        customer_id,
        professional_id,
        is_active,
        created_at,
        updated_at
      ) VALUES (
        v_chat_room_id,
        NEW.id,
        v_customer_uuid,
        v_professional_uuid,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      );
      
      -- Update booking with chat_room_id (chat_room_id is UUID, so no casting needed)
      -- Wrap in exception handling in case of any issues
      BEGIN
        UPDATE bookings 
        SET chat_room_id = v_chat_room_id
        WHERE id = NEW.id;
      EXCEPTION WHEN OTHERS THEN
        -- Log warning but don't fail the insert
        RAISE WARNING 'Failed to update booking chat_room_id: %', SQLERRM;
      END;
    END IF;
  END IF;
  
  -- Create invoice for the booking (only if one doesn't already exist)
  IF v_customer_uuid IS NOT NULL AND v_professional_uuid IS NOT NULL THEN
    -- Check if invoice already exists for this booking
    SELECT id INTO v_invoice_id 
    FROM invoices 
    WHERE booking_id = NEW.id 
    LIMIT 1;
    
    IF v_invoice_id IS NULL THEN
      -- Calculate deposit and balance amounts
      v_deposit_amount := (NEW.agreed_price * v_deposit_percentage / 100.0);
      v_balance_amount := NEW.agreed_price - v_deposit_amount;
      
      -- Set due date to scheduled end time or 7 days from now, whichever is later
      v_due_date := GREATEST(NEW.scheduled_end_time, CURRENT_TIMESTAMP + INTERVAL '7 days');
      
      v_invoice_id := uuid_generate_v4();
      
      INSERT INTO invoices (
        id,
        booking_id,
        customer_id,
        professional_id,
        total_amount,
        currency,
        deposit_percentage,
        deposit_amount,
        balance_amount,
        status,
        due_date,
        created_at,
        updated_at
      ) VALUES (
        v_invoice_id,
        NEW.id,
        v_customer_uuid,
        v_professional_uuid,
        NEW.agreed_price,
        COALESCE(NEW.currency, 'JMD'),
        v_deposit_percentage,
        v_deposit_amount,
        v_balance_amount,
        'draft',
        v_due_date,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      );
    END IF;
  END IF;
  
  -- Initialize professional balance if it doesn't exist
  -- Note: professional_balances.professional_id should match bookings.professional_id type (VARCHAR)
  -- Skip if professional UUID not found (test users won't exist)
  IF NEW.professional_id IS NOT NULL THEN
    INSERT INTO professional_balances (
      professional_id,
      available_balance,
      total_earned,
      total_paid_out,
      created_at,
      updated_at
    ) VALUES (
      NEW.professional_id,
      0.00,
      0.00,
      0.00,
      CURRENT_TIMESTAMP,
      CURRENT_TIMESTAMP
    )
    ON CONFLICT (professional_id) DO NOTHING;
  END IF;
  
  -- Create notification entries for customer and professional
  -- Only create if notifications don't already exist for this booking
  IF v_customer_uuid IS NOT NULL THEN
    INSERT INTO notifications (
      user_id,
      notification_type,
      title,
      body,
      priority,
      status,
      data,
      created_at
    ) 
    SELECT 
      v_customer_uuid,
      'booking_confirmed',
      'Booking Confirmed',
      'Your booking for ' || NEW.service_title || ' has been confirmed.',
      'normal',
      'pending',
      jsonb_build_object(
        'booking_id', NEW.id,
        'service_title', NEW.service_title,
        'scheduled_start_time', NEW.scheduled_start_time,
        'professional_name', NEW.professional_name
      ),
      CURRENT_TIMESTAMP
    WHERE NOT EXISTS (
      SELECT 1 FROM notifications 
      WHERE user_id = v_customer_uuid 
      AND notification_type = 'booking_confirmed'
      AND data->>'booking_id' = NEW.id
    );
  END IF;
  
  IF v_professional_uuid IS NOT NULL THEN
    INSERT INTO notifications (
      user_id,
      notification_type,
      title,
      body,
      priority,
      status,
      data,
      created_at
    )
    SELECT 
      v_professional_uuid,
      'new_booking',
      'New Booking Received',
      'You have a new booking for ' || NEW.service_title || ' from ' || NEW.customer_name || '.',
      'high',
      'pending',
      jsonb_build_object(
        'booking_id', NEW.id,
        'service_title', NEW.service_title,
        'scheduled_start_time', NEW.scheduled_start_time,
        'customer_name', NEW.customer_name
      ),
      CURRENT_TIMESTAMP
    WHERE NOT EXISTS (
      SELECT 1 FROM notifications 
      WHERE user_id = v_professional_uuid 
      AND notification_type = 'new_booking'
      AND data->>'booking_id' = NEW.id
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to execute the function after booking insert
DROP TRIGGER IF EXISTS trigger_populate_booking_tables ON bookings;
CREATE TRIGGER trigger_populate_booking_tables
  AFTER INSERT ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION populate_booking_related_tables();

-- Add comment for documentation
COMMENT ON FUNCTION populate_booking_related_tables() IS 
'Automatically populates related tables when a booking is created: chat_rooms, invoices, professional_balances, and notifications';

